#TODO: customizable diff-table headers

=head1 NAME

Konstrukt::Plugin::wiki::backend::article - Base class for article backends

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::backend::article';
	#overwrite the methods
	
	#note that you can use $self->backend_method() in the action methods as
	#only an instance of the backend class will be created and it will inherit your methods.

=head1 DESCRIPTION

Base class for a backend class that implements the backend
functionality (store, retrieve, ...) for wiki articles.

Includes the control/display code for wiki articles as it won't change with
different backend types (DBI, file, ...). So the implementing backend class will
inherit this code but must overwrite the date retrieval and update code.

Although currently only DBI-backends exist, it should be easy to develop
other backends (e.g. file based).

Note that the name of wiki articles will be normalized.
All characters but letters, numbers and parenthesis will be replaced by underscores.
Internally links are case insensitive. So C<SomeLink> will point to the same
page as C<[[somelink]]>.

=cut

package Konstrukt::Plugin::wiki::backend::article;

use strict;
use warnings;

#this class is a backend implementation and should also inherit the add_node method from Konstrukt::Plugin
use base qw/Konstrukt::Plugin::wiki::backend Konstrukt::Plugin/;
use Konstrukt::Plugin; #import use_plugin

=head1 METHODS

=head2 init

Initialization for this plugin.

If you overwrite this one in your implementation, make sure to call
C<$self->SUPER::init(@_);> to let the base class (this class) also do its init work.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic}    = use_plugin 'usermanagement::basic'    or return undef;
	$self->{user_level}    = use_plugin 'usermanagement::level'    or return undef;
	$self->{user_personal} = use_plugin 'usermanagement::personal' or return undef;

	#load wiki plugin to let it define its default settings
	use_plugin 'wiki';

	#paths
	$self->{template_path} = $Konstrukt::Settings->get("wiki/template_path");
	
	return 1;
}
#= /init

=head2 install

Installs the templates.

B<Parameters:>

none

=cut
sub install {
	my ($self) = @_;
	return $Konstrukt::Lib->plugin_file_install_helper($self->{template_path});
}
# /install

=head2 actions

See L<Konstrukt::Plugin::wiki::backend/actions> for a description of this one.

Responsible for the actions to show and edit wiki articles.

=cut
sub actions {
	return ('article_show', 'article_edit_show', 'article_edit', 'article_revision_list', 'article_restore_diff');
}
#= /actions

=head2 get_title

Will return the wiki page which has been requested.

These sources are checked in this order:

=over

=item * page passed through ?wiki_page= cgi parameter

=item * page specified in the tag attribute: <& wiki page="somepage" / &>

=item * default page set in wiki/default_page

=back

=cut
sub get_title {
	my ($self, $tag) = @_;
	
	my $title = $Konstrukt::CGI->param('wiki_page') || undef;
	$title = $tag->{tag}->{attributes}->{page} || undef unless defined $title;
	$title = $Konstrukt::Settings->get('wiki/default_page') unless defined $title;
	
	return $title;
}
#= /get_title

=head2 article_show

Will handle the action to show a wiki article.

Will load a wiki article, convert it and return it.

B<Parameters>:

=over

=item * $tag - The wiki tag node which executed the plugin

=back

=cut
sub article_show {
	my ($self, $tag) = @_;
	
	my $title = $self->get_title($tag);
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	
	my $template = use_plugin 'template';
	my $wiki = use_plugin 'wiki';
	
	#get the revision that should be displayed
	my $latest_revision = $self->revision($title);
	my $revision = $Konstrukt::CGI->param('revision');
	$revision = $latest_revision if not $revision or $revision > $latest_revision or $revision < 1;
	#is there any revision for this article? does it exist?
	if (defined $latest_revision) {
		#do we have a cached version of this article?
		my $cached_filename = $Konstrukt::Settings->get("wiki/cache_prefix") . $self->normalize_link($title) . "_$revision";
		$cached_filename = $Konstrukt::File->absolute_path($cached_filename);
		my $article = $Konstrukt::Cache->get_cache($cached_filename);
		unless (defined $article) {
			#render article and cache it.
			#push an arbitrary file on the stack to save the opened files as file conditions in the cache for this wiki markup
			$Konstrukt::File->push($cached_filename);
			#retrieve markup
			$article = $self->get($title, $revision);
			$article->{content}           = $wiki->convert_markup_string($article->{content});
			$article->{title}             = $title_html_escaped;
			$article->{title_uri_encoded} = $title_uri_encoded;
			map { $article->{$_} = sprintf("%02d", $article->{$_}) } qw/month day hour minute/;
			$Konstrukt::Cache->write_cache($cached_filename, $article);
		}
		#we're already done with this file
		$Konstrukt::File->pop();
		#get author name, tell the template if the use is privileged to write to the wiki and put out template
		$article->{author_name} = $self->{user_personal}->data($article->{author})->{nick};
		$article->{may_write} = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
		$self->add_node($template->node("$self->{template_path}layout/article.template", { fields => $article }));
	} else {
		$self->article_edit_show($tag);
	}
}
#= /article_show

=head2 article_edit_show

Will handle the action to show the form to edit a wiki article.

Will load the source of a wiki article (if exists) and display a form to
edit the source.

B<Parameters>:

=over

=item * $tag - The wiki tag node which executed the plugin

=back

=cut
sub article_edit_show {
	my ($self, $tag) = @_;
	
	my $title = $self->get_title($tag);
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
		
	#user logged in?
	my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
	
	my $template = use_plugin 'template';
	if ($may_edit) {
		#get the revision that should be displayed
		my $latest_revision = $self->revision($title);
		my $revision = $Konstrukt::CGI->param('revision');
		$revision = $latest_revision if not $revision or $revision > $latest_revision or $revision < 1;
		
		my $markup;
		if (defined $latest_revision) {
			#load source
			$markup = $self->get($title, $revision)->{content};
		}
		
		$self->add_node($template->node("$self->{template_path}layout/article_edit_form.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded, markup => $Konstrukt::Lib->html_escape($markup) }));
	} else {
		$self->add_node($template->node("$self->{template_path}messages/article_edit_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /article_edit_show 

=head2 article_edit

Will handle the action to update a wiki article.

Will save the markup for the given page.

B<Parameters>:

=over

=item * $tag - The wiki tag node which executed the plugin

=back

=cut
sub article_edit {
	my ($self, $tag) = @_;

	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/article_edit_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $title = $form->get_value('wiki_page') || undef;
		my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
		my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
		
		#user logged in?
		my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
		
		my $template = use_plugin 'template';
		
		if ($may_edit) {
			if (defined $title) {
				my $markup = $form->get_value('markup') || '';
				
				if ($form->get_value('preview')) {
					#show preview only
					my $wiki = use_plugin 'wiki';
					my $article = { markup => $Konstrukt::Lib->html_escape($markup), content => $wiki->convert_markup_string($markup), title => $title_html_escaped, title_uri_encoded => $title_uri_encoded };
					$self->add_node($template->node("$self->{template_path}layout/article_preview.template", { fields => $article }));
					$self->add_node($template->node("$self->{template_path}layout/article_edit_form.template", { fields => $article }));
				} else {
					#save article
					my $result = $self->store($title, $markup, $self->{user_basic}->id(), $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
					if (defined $result and $result == -1) {
						#no change
						$self->add_node($template->node("$self->{template_path}messages/article_edit_no_change.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
						$self->article_edit_show();
					} elsif (defined $result) {
						#show the new article
						$self->article_show($tag);
					} else {
						#error!
						$self->add_node($template->node("$self->{template_path}messages/article_edit_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
					}
				}
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/article_edit_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /article_edit

=head2 article_revision_list

Will handle the action to show the revision history of an article.

B<Parameters>:

=over

=item * $tag - The wiki tag node which executed the plugin

=back

=cut
sub article_revision_list {
	my ($self, $tag) = @_;

	my $title = $self->get_title($tag);
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	
	my $template = use_plugin 'template';
	
	if (defined $title and my $revisions = $self->revisions($title)) {
		#set count
		my $revision_count = @{$revisions};
		#prepare data
		foreach my $revision (@{$revisions}) {
			map { $revision->{$_} = sprintf("%02d", $revision->{$_}) } qw/month day hour minute/;
			$revision->{author_name} = $self->{user_personal}->data($revision->{author})->{nick};
			#add title field
			$revision->{title}             = $title_html_escaped;
			$revision->{title_uri_encoded} = $title_uri_encoded;
			#add revision count and current revision indicator
			$revision->{revision_count} = $revision_count;
			$revision->{current} = 0;
		}
		$revisions->[0]->{current} = 1 if @{$revisions};
		#reverse order
		$revisions = [ reverse @{$revisions} ];
		#display list
		$self->add_node($template->node("$self->{template_path}layout/article_revision_list.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded, revision_count => $revision_count, revisions => $revisions }));
	} else {
		#error
		$self->add_node($template->node("$self->{template_path}messages/article_revision_list_failed.template"));
	}
}
#= /article_revision_list

=head2 article_restore_diff

Will handle this action and run the method, which the user selected (restore or diff)

=cut
sub article_restore_diff {
	my ($self, $tag) = @_;
	
	if ($Konstrukt::CGI->param('restore')) {
		$self->article_restore($tag);
	} elsif ($Konstrukt::CGI->param('diff')) {
		$self->article_diff($tag);
	}
}
#= /article_restore_diff

=head2 article_restore

Will handle the action to restore an article's content.

=cut
sub article_restore {
	my ($self, $tag) = @_;
	
	my $template = use_plugin 'template';

	#user logged in?
	my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	if ($may_edit) {
		my $revision = $Konstrukt::CGI->param('revision') || undef;
		if (defined $title and $revision) {
			#get content of the revision to restore
			my $restore = $self->get($title, $revision);
			if (defined $restore) {
				#restore
				my $result = $self->store($title, $restore->{content}, $self->{user_basic}->id(), $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
				if (not defined $result) {
					#error
					$self->add_node($template->node("$self->{template_path}messages/article_restore_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
				} elsif ($result == -1) {
					#no change
					$self->add_node($template->node("$self->{template_path}messages/article_restore_failed_no_change.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
				}
			} else {
				$self->add_node($template->node("$self->{template_path}messages/article_restore_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			}
			$self->article_revision_list();
		} else {
			$self->add_node($template->node("$self->{template_path}messages/article_restore_failed_incomplete.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/article_restore_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /article_restore

=head2 article_diff

Will handle the action to show the diff between two revisions of an article

=cut
sub article_diff {
	my ($self, $tag) = @_;
	
	my $template = use_plugin 'template';
	my $diff     = use_plugin 'diff';

	my $title = $Konstrukt::CGI->param('title') || undef;
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	my ($diff1, $diff2) = ($Konstrukt::CGI->param('diff1') || undef, $Konstrukt::CGI->param('diff2') || undef);
	if (defined $title and defined $diff1 and defined $diff2) {
		if ($diff1 != $diff2) {
			#get markup of both revisions
			my $article1 = $self->get($title, $diff1);
			my $article2 = $self->get($title, $diff2);
			if (defined $article1 and defined $article2) {
				#show diff
				$self->add_node($template->node("$self->{template_path}layout/article_diff.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded, diff => $diff->diff($article1->{content}, $article2->{content}, "Revision $diff1", "Revision $diff2"), diff1 => $diff1, diff2 => $diff2 }));
			} else {
				$self->add_node($template->node("$self->{template_path}messages/article_diff_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/article_diff_failed_no_diff.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/article_diff_failed_incomplete.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /article_diff

=head2 exists

This method will return true, if a specified article exists. It will return
undef otherwise.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $revision - Optional: A specific revision of an article

=back

=cut
sub exists {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /exists

=head2 revision

This method will return the latest revision number/number of revisions of a
specified article. It will return undef if the specified article does not
exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the article

=back

=cut
sub revision {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 revisions

This method will return all revisions of the specified article as an array of
hash references:

	[
		{ revision => 1, author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },
		{ revision => 2, ...},
		...
	]

Will return undef, if the file doesn't exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the article

=back

=cut
sub revisions {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 get

This method will return the article as a hashref:

		{ revision => 1, content => '= wiki stuff', author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },

Will return undef, if the requested article doesn't exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $revision - Optional: A specific revision of an article. When not
specified, the latest revision will be returned.

=back

=cut
sub get {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /get

=head2 store

This method will add a new article (or new revision if the article already
exists) to the store.

Will return -1 if no change has been made (which is the case, when no new
content has been passed and the article already exists in the database).

Will return true on success and undef otherwise.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the article

=item * $content - The content that should be stored

=item * $author - User id of the creator

=item * $host - Internet address of the creator

=back

=cut
sub store {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /store

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/article.template -- >8 --

<div class="wiki article">
	<div class="content">
	<+$ content $+>(no content)<+$ / $+>
	</div>
	
	<& if condition="<+$ may_write $+>0<+$ / $+>" &>
	<hr />
	<p>Revision <+$ revision $+>(no revision)<+$ / $+>. Created on <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> by <+$ author_name $+>(no author)<+$ / $+> (author ID: <+$ author $+>0<+$ / $+>).</p>
	<p><a href="?action=article_edit_show;wiki_page=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>">Edit</a>, <a href="?action=article_revision_list;wiki_page=<+$ title_uri_encoded / $+>">Revisions</a></p>
	<& / &>
</div>

-- 8< -- textfile: layout/article_diff.template -- >8 --

<div class="wiki article diff">
	<h1>Diff for <+$ title $+>(no title)<+$ / $+> (Revision <+$ diff1 $+>?<+$ / $+> &hArr; <+$ diff2 $+>?<+$ / $+>)</h1>
	<hr />
	<+$ diff $+>(no content)<+$ / $+>
</div>

-- 8< -- textfile: layout/article_edit_form.form -- >8 --

$form_name = 'edit';
$form_specification =
{
	wiki_page => { name => 'Title (not empty)', minlength => 1, maxlength => 256,   match => '' },
	markup    => { name => 'Text (not empty)' , minlength => 1, maxlength => 65536, match => '' },
	preview   => { name => 'Preview'          , minlength => 0, maxlength => 1,     match => '' },
};

-- 8< -- textfile: layout/article_edit_form.template -- >8 --

<& formvalidator form="article_edit_form.form" / &>
<div class="wiki form">
	<h1>Edit page: <+$ title $+>(no title)<+$ / $+></h1>
	
	<form name="edit" action="" method="post" onsubmit="return validateForm(document.edit)">
		<input type="hidden" name="action"    value="article_edit" />
		<input type="hidden" name="wiki_page" value="<+$ title / $+>" />
		
		<textarea name="markup"><+$ markup $+>This page doesn't exist, yet. Write some text and create it!<+$ / $+></textarea>
		<br />
		
		<input id="preview" name="preview" type="checkbox" class="checkbox" checked="checked" />
		<label for="preview" class="checkbox">Preview</label>
		<br />
		
		<input value="Save!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/article_preview.template -- >8 --

<div class="wiki article preview">
	<h1>Preview: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	<div class="content">
	<+$ content $+>(no content)<+$ / $+>
	</div>
	<hr />
</div>
	
-- 8< -- textfile: layout/article_revision_list.template -- >8 --

<div class="wiki revisionlist">
	<h1>Revisionlist for: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	<form name="restore" action="" method="post">
		<input type="hidden" name="action" value="article_restore_diff" />
		<input type="hidden" name="title" value="<+$ title / $+>" />
		
		<table>
			<tr><th>Revision</th><th>Date</th><th>Author</th><th>Restore</th><th colspan="2">Difference</th></tr>
			<+@ revisions @+><tr>
				<td><a href="?action=article_show;wiki_page=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>"><+$ revision / $+></a></td>
				<td><+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+></td>
				<td><+$ author_name $+>(no author)<+$ / $+></td>
				<& perl &>
					#print radio buttons for restore and diff selection
					my $rev = '<+$ revision / $+>';
					my $rev_count = '<+$ revision_count / $+>';
					#restore
					print "<td>";
					if ($rev < $rev_count) {
						my $checked = $rev == $rev_count - 1 ? 'checked="checked" ' : '';
						print "<input type=\"radio\" class=\"radio\" name=\"revision\" value=\"$rev\" $checked/>";
					} else {
						print '&nbsp;';
					}
					print "</td>";
					#diff
					my $checked1 = $rev == ($rev_count - 1 or $rev_count == 1) ? 'checked="checked" ' : '';
					my $checked2 = $rev == $rev_count ? 'checked="checked" ' : '';
					print "<td><input name=\"diff1\" value=\"$rev\" type=\"radio\" class=\"radio\" $checked1/></td>";
					print "<td><input name=\"diff2\" value=\"$rev\" type=\"radio\" class=\"radio\" $checked2/></td>";
				<& / &>
			</tr>
			<+@ / @+>
		</table>
		
		<& if condition="<+$ revision_count / $+> > 1" &>
			<hr />
			<input name="restore" type="submit" class="submit" value="Restore"         />
			<input name="diff"    type="submit" class="submit" value="Show difference" />
		<& / &>
	</form>
</div>

-- 8< -- textfile: messages/article_diff_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Difference for '<+$ title $+>(no title)<+$ / $+>' cannot be displayed</h1>
	<p>An internal error occurred!</p>
</div>

-- 8< -- textfile: messages/article_diff_failed_incomplete.template -- >8 --

<div class="wiki message failure">
	<h1>Difference for '<+$ title $+>(no title)<+$ / $+>' cannot be displayed</h1>
	<p>The needed information (title, revisions) are incomplete.</p>
</div>

-- 8< -- textfile: messages/article_diff_failed_no_diff.template -- >8 --

<div class="wiki message failure">
	<h1>No difference for '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>The revisions are identical. There is no difference.</p>
</div>

-- 8< -- textfile: messages/article_edit_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' not saved</h1>
	<p>An internal error occurred while saving this article!</p>
</div>

-- 8< -- textfile: messages/article_edit_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' cannot be edited</h1>
	<p>You don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/article_edit_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>No change for page '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>No new/different content has been entered.</p>
</div>

-- 8< -- textfile: messages/article_restore_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>An internal error occurred while restoring this article.</p>
</div>

-- 8< -- textfile: messages/article_restore_failed_incomplete.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The needed information (title, revisions) are incomplete.</p>
</div>

-- 8< -- textfile: messages/article_restore_failed_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The requested restore has not been performed as it would leed to no change. The revision to restore is identical to the current one.</p>
</div>

-- 8< -- textfile: messages/article_restore_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>Article '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The article has not been restored, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/article_revision_list_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Cannot display revision list for article '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>Either this article does not exist or an internal error occurred.</p>
</div>

