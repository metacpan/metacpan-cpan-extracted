#FEATURE: Caching of the files somewhere inside the docroot and redirect to
#         the static file? Will this gain performance?

=head1 NAME

Konstrukt::Plugin::wiki::backend::file - Base class for file backends

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::backend::file';
	#overwrite the methods
	
	#note that you can use $self->backend_method() in the action methods as
	#only an instance of the backend class will be created and it will inherit your methods.
	
=head1 DESCRIPTION

Base class for a backend class that implements the backend
functionality (store, retrieve, ...) for files (*.zip, *.pdf, *.*).

Includes the control/display code for managing files as it won't change with
different backend types (DBI, file, ...). So the implementing backend class will
inherit this code but must overwrite the data retrieval and update code.

Although currently only DBI-backends exist, it should be easy to develop
other backends (e.g. file based).

Note that the name of the files will be normalized.
All characters but letters, numbers, hyphens, parenthesis, brackets and dots
will be replaced by underscores.
Internally files are case insensitive. So C<SomeFile.zip> will point to the same
page as C<somefile.zip>.

=cut

package Konstrukt::Plugin::wiki::backend::file;

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

Responsible for the actions to show manage files.

=cut
sub actions {
	return ('file_show', 'file_edit_show', 'file_edit', 'file_revision_list', 'file_restore');
}
#= /actions

=head2 prepare

The served file content will of course be dynamic. Don't do anything here.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

This one will be called, when a file's content will be downloaded. It will
retrieve the content from the backend and return it to the browser.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;
	
	#reset the collected nodes
	$self->reset_nodes();
	
	#load defaut settings and backend
	use_plugin 'wiki';
	my $backend = use_plugin 'wiki::backend::file::' . $Konstrukt::Settings->get("wiki/backend_type");
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	if (defined $title) {
		#get the revision that should be displayed
		my $revision = $Konstrukt::CGI->param('revision');
		my $file = $backend->get_content($title, $revision);
		if	(defined $file) {
			$self->add_node($file->{content});
			$Konstrukt::Response->header('Content-Type' => $file->{mimetype} || 'application/octet-stream');
			$Konstrukt::Response->header('Content-Disposition' => "attachment; filename=\"$file->{filename}\"");
		} else {
			$self->add_node("File '$title rev $revision' not found!");
			$Konstrukt::Response->status(404);
		}
	} else {
		$self->add_node("No file specified!");
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 file_show

Will handle the action to show an information page for a file.

=cut
sub file_show {
	my ($self, $tag) = @_;
	
	my $template = use_plugin 'template';
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	if (defined $title) {
		#get the revision that should be displayed
		my $latest_revision = $self->revision($title);
		my $revision = $Konstrukt::CGI->param('revision');
		$revision = $latest_revision if not $revision or $revision > $latest_revision or $revision < 1;
		#is there any revision for this article? does it exist?
		if (defined $latest_revision) {
			my $file = $self->get_info($title, $revision);
			
			map { $file->{$_} = sprintf("%02d", $file->{$_}) } qw/month day hour minute/;
			$file->{title}             = $Konstrukt::Lib->html_escape($title);
			$file->{title_uri_encoded} = $Konstrukt::Lib->uri_encode($title);
			$file->{description}       = $Konstrukt::Lib->html_escape($file->{description});
			$file->{author_name}       = $self->{user_personal}->data($file->{author})->{nick};
			$file->{may_write}         = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
			
			$self->add_node($template->node("$self->{template_path}layout/file_info.template", { fields => $file }));
		} else {
			#file doesn't exist yet
			$self->file_edit_show($title);
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/file_info_no_file_specified.template"));
	}
}
#= /file_show

=head2 file_edit_show

Will handle the action to show the form to edit/upload a file.

=cut
sub file_edit_show {
	my ($self, $tag) = @_;
	
	#user logged in?
	my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
	
	my $template = use_plugin 'template';
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	if ($may_edit) {
		#get the revision that should be displayed
		my $latest_revision = $self->revision($title);
		
		my $file;
		if (defined $latest_revision) {
			$file = $self->get_info($title);
			$file->{description} = $Konstrukt::Lib->html_escape($file->{description});
		}
		$file->{title}             = $Konstrukt::Lib->html_escape($title);
		$file->{title_uri_encoded} = $Konstrukt::Lib->uri_encode($title);
		
		$self->add_node($template->node("$self->{template_path}layout/file_edit_form.template", { fields => $file }));
	} else {
		$self->add_node($template->node("$self->{template_path}messages/file_edit_failed_permission_denied.template", { title => $title }));
	}
}
#= /file_edit_show 

=head2 file_edit

Will handle the action to update a file.

=cut
sub file_edit {
	my ($self, $tag) = @_;

	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/file_edit_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $title = $form->get_value('title');
		my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
		my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
		#user logged in?
		my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
		
		if ($may_edit) {
			my ($filename, $mimetype, $content, $description);
			my $store_description = $Konstrukt::CGI->param('store_description');
			my $store_content     = $Konstrukt::CGI->param('store_content');
			
			#new description?
			if ($store_description) {
				$description = $form->get_value('description');
				$description = undef unless length $description;
			}

			#new content?
			if ($store_content) {
				if (defined (my $fh = $Konstrukt::CGI->upload('content'))) {
					$content = '';
					binmode $fh;
					$content .= $_ while <$fh>;
					$filename = $Konstrukt::CGI->param('content');
    				$mimetype = $Konstrukt::CGI->uploadInfo($filename)->{'Content-Type'};
					#could the file be retrieved?
					$content = undef unless length $content;
				}
			}
			
			#store file
			my $result = $self->store($title, $store_description, $description, $store_content, $content, $mimetype, $filename, $self->{user_basic}->id(), $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
			if (defined $result) {
				#no change?
				$self->add_node($template->node("$self->{template_path}messages/file_edit_no_change.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded })) if $result == -1;
				#success
				$self->file_show();
			} else {
				#error
				$self->add_node($template->node("$self->{template_path}messages/file_edit_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/file_edit_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /file_edit

=head2 file_revision_list

Will handle the action to show the revision history of a file.

=cut
sub file_revision_list {
	my ($self, $tag) = @_;
	
	my $title = $Konstrukt::CGI->param('title') || undef;
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
		$self->add_node($template->node("$self->{template_path}layout/file_revision_list.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded, revision_count => $revision_count, revisions => $revisions }));
	} else {
		#error
		$self->add_node($template->node("$self->{template_path}messages/file_revision_list_failed.template"));
	}
}
#= /file_revision_list

=head2 file_restore

Will handle the action to restore a file's content and/or description.

=cut
sub file_restore {
	my ($self, $tag) = @_;
	
	my $template = use_plugin 'template';

	#user logged in?
	my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	if ($may_edit) {
		my $revision = $Konstrukt::CGI->param('revision') || undef;
		my $restore  = { map { $_ => 1 } ($Konstrukt::CGI->param('restore')) };
		if (defined $title and $revision and (exists $restore->{description} or exists $restore->{content})) {
			#restore
			my $result = $self->restore($title, $revision, exists $restore->{description}, exists $restore->{content}, $self->{user_basic}->id(), $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
			if (not defined $result) {
				#error
				$self->add_node($template->node("$self->{template_path}messages/file_restore_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			} elsif ($result == -1) {
				#no change
				$self->add_node($template->node("$self->{template_path}messages/file_restore_failed_no_change.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			}
			$self->file_revision_list();
		} else {
			$self->add_node($template->node("$self->{template_path}messages/file_restore_failed_incomplete.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/file_restore_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /file_restore

=head2 exists

This method will return true, if a specified file exists. It will return
undef otherwise.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the file

=item * $revision - Optional: A specific revision of a file

=back

=cut
sub exists {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /exists

=head2 revision

This method will return the latest revision number/number of revisions of a
specified file. It will return undef if the specified file does not
exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the file

=back

=cut
sub revision {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 revisions

This method will return all revisions of the specified file as an array of
hash references ordered by ascending revision numbers:

	[
		{ revision => 1, description => 'foo', description_revision => 3, content_revision => 4, content => 1, author => 'bar', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },
		{ revision => 2, ...},
		...
	]
	
Will return undef, if the file doesn't exist.

Note that the description_revision and content_revision may also be 0 if no content has been saved yet.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the file

=back

=cut
sub revisions {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 get_info

This method will return the file info as a hashref:

		{ title => 'foo', revision => 7, description => 'some text', description_revision => 3, content_revision => 4, author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },

Will return undef, if the requested file doesn't exist.

Note that the description_revision and content_revision may also be 0 if no content has been saved yet.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the file

=item * $revision - Optional: A specific revision of a file. When not
specified, the latest revision will be returned.

=back

=cut
sub get_info {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /get_info

=head2 get_content

This method will return the file content as a hashref:

		{ content => 'binarydata', mimetype => 'application/foobar', filename => 'somefile.ext' }

Will return undef, if the requested file doesn't exist or there is no content yet.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the file

=item * $revision - Optional: A specific revision of a file. When not
specified, the latest revision will be returned.

=back

=cut
sub get_content {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /get_content

=head2 store

This method will add a new file (or new revision if the file already
exists) to the store.

If the file already exists, you may also just add a new description or a new
content for the file. Pass undef for the value, you don't want to change.

Will return -1 if no change has been made (which is the case, when no new
content and no new description has been passed and the file already exists in
the database). Will return true on successful update and undef on error.

B<Parameters>:

=over

=item * $title - The title of the file

=item * $store_description - True, if a new description should be stored. False,
if the old one should be left.

=item * $description - A description of this file. May be undef to reset (delete)
the description for the new revision.

=item * $store_content - True, if a new content should be stored. False,
if the old one should be left.

=item * $content - The (binary) content that should be stored. May be undef
to reset (delete) the content for the new revision.

=item * $mimetype - The MIME type of the file

=item * $filename - The filename of the uploaded file. Will be used as the filename for the download

=item * $author - User id of the creator

=item * $host - Internet address of the creator

=back

=cut
sub store {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /store

=head2 restore

This method will restore a description and/or a content from a given file revision.

Will return -1 if no change has been made (which is the case, when the current
data and the data, which should be restored, are the same).
Will return true on successful update and undef on error.

B<Parameters>:

=over

=item * $title - The title of the file

=item * $revision - The revision from which the description will be restored.

=item * $restore_description - True, when the description should be restored

=item * $restore_content - True, when the content should be restored

=item * $author - User id of the modifier

=item * $host - Internet address of the modifier

=back

=cut
sub restore {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /restore

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/file_edit_form.form -- >8 --

$form_name = 'edit';
$form_specification =
{
	title             => { name => 'Title (not empty)', minlength => 1, maxlength =>        256, match => '' },
	description       => { name => 'Description'      , minlength => 0, maxlength =>      65536, match => '' },
	content           => { name => 'Content'          , minlength => 0, maxlength => 4294967296, match => '' },
};

-- 8< -- textfile: layout/file_edit_form.template -- >8 --

<& formvalidator form="file_edit_form.form" / &>
<div class="wiki form">
	<h1>Edit/upload file:</h1>
	
	<form name="edit" action="" method="post" enctype="multipart/form-data" onsubmit="return validateForm(document.edit)">
		<input type="hidden" name="action" value="file_edit" />
		
		<label>Title:</label>
		<input name="title" maxlength="255" value="<+$ title $+>(Kein Titel)<+$ / $+>" />
		<br />
		
		<label>Description:</label>
		<div style="width: 600px">
			<p>Current description:</p>
			<p><+$ description $+>(no description yet)<+$ / $+></p>
			<input id="store_description" name="store_description" type="checkbox" class="checkbox" value="1" />
			<label for="store_description" class="checkbox">New description: (keep empty to remove the description)</label>
			<br />
			<textarea name="description"></textarea>
		</div>
		<br />
		
		<label>File:</label>
		<div style="width: 600px">
			<p>Current file:</p>
			<p>
			<& perl &>
				my $content = '<+$ content_revision $+>0<+$ / $+>';
				if ($content) {
					print "<a href=\"/wiki/file/?action=file_content;title=<+$ title_uri_encoded / $+>;revision=$content\">Download</a>";
				} else {
					print '(no file yet)';
				}
			<& / &>
			</p>
			<input id="store_content" name="store_content" type="checkbox" class="checkbox" value="1" />
			<label for="store_content" class="checkbox">New file: (keep empty to remove the file)</label>
			<br />
			<input type="file" name="content" />
		</div>
		<br />

		<label>&nbsp;</label>
		<input value="Save!" type="submit" class="submit" />
		<br />
	</form>
	<h2>Note:</h2>
	<p>If no description and/or no file is specified, the old values for those fields will be kept in the database.</p>
	<p>It's possible to create a new file without a description and without a content. Those can be added later.</p>
</div>

-- 8< -- textfile: layout/file_info.template -- >8 --

<div class="wiki file info">
	<h1>File: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	
	<p>Description:</p>
	<p><+$ description $+>(no description)<+$ / $+></p>
	<hr />
	
	<p>
	<& if condition="<+$ content_revision $+>0<+$ / $+>" &>
		<$ then $><a href="/wiki/file/?action=file_content;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>">Download</a><$ / $>
		<$ else $>(no file yet)<$ / $>
	<& / &>
	</p>
	
	<& if condition="<+$ may_write $+>0<+$ / $+>" &>
	<hr />
	<p>Revision <+$ revision $+>(no revision)<+$ / $+>. Created on <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> by <+$ author_name $+>(no author)<+$ / $+> (author ID: <+$ author $+>0<+$ / $+>).</p>
	<p><a href="?action=file_edit_show;title=<+$ title_uri_encoded / $+>">Edit</a>, <a href="?action=file_revision_list;title=<+$ title_uri_encoded / $+>">Revisions</a></p>
	<& / &>
</div>

-- 8< -- textfile: layout/file_revision_list.template -- >8 --

<div class="wiki file revisionlist">
	<h1>Revisionlist for file: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	<form name="restore" action="" method="post">
		<input type="hidden" name="action" value="file_restore" />
		<input type="hidden" name="title" value="<+$ title / $+>" />
		
		<table>
			<tr><th>Revision</th><th>Description</th><th>Date</th><th>Author</th><th>Restore</th></tr>
			<+@ revisions @+><tr>
				<td><a href="?action=file_show;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>"><+$ revision / $+></a></td>
				<td><+$ description $+>(no description)<+$ / $+></td>
				<td><+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+></td>
				<td><+$ author_name $+>(no author)<+$ / $+></td>
				<td><& perl &>
					my $rev = '<+$ revision / $+>';
					my $rev_count = '<+$ revision_count / $+>';
					if ($rev < $rev_count) {
						my $checked = $rev == $rev_count - 1 ? 'checked="checked" ' : '';
						print "<input name=\"revision\" value=\"$rev\" type=\"radio\" class=\"radio\" $checked/>";
					} else {
						print '&nbsp;';
					}
				<& / &></td>
			</tr>
			<+@ / @+>
		</table>
		
		<& if condition="<+$ revision_count / $+> > 1" &>
			<hr />
			
			<input id="restore_desc" name="restore" type="checkbox" class="checkbox" value="description" />
			<label for="restore_desc" class="checkbox">Restore description</label>
			<br />
			
			<input id="restore_cont" name="restore" type="checkbox" class="checkbox" value="content" />
			<label for="restore_cont" class="checkbox">Restore content</label>
			<br />
			
			<input value="Restore!" type="submit" class="submit" />
			<br />
		<& / &>
	</form>
</div>

-- 8< -- textfile: messages/file_edit_failed.template -- >8 --

<div class="wiki message failure">
	<h1>File '<+$ title $+>(no title)<+$ / $+>' cannot be edited</h1>
	<p>An internal error occurred.</p>
</div>

-- 8< -- textfile: messages/file_edit_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>File '<+$ title $+>(no title)<+$ / $+>' cannot be edited!</h1>
	<p>You don't have the appropriate permissions.</p>
</div>

-- 8< -- textfile: messages/file_edit_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>No change for file '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>Neither a new description nor a new file have been specified (or the specified contents are identical to the current ones) and there already exists an entry for this file title.</p>
</div>

-- 8< -- textfile: messages/file_info_no_file_specified.template -- >8 --

<div class="wiki message failure">
	<h1>File cannot be displayed</h1>
	<p>No file specified.</p>
</div>

-- 8< -- textfile: messages/file_restore_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Contents of the file '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>An internal error occurred.</p>
</div>

-- 8< -- textfile: messages/file_restore_failed_incomplete.template -- >8 --

<div class="wiki message failure">
	<h1>File '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The needed information (title, revision, data to restore) are incomplete.</p>
</div>

-- 8< -- textfile: messages/file_restore_failed_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>File '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The requested restore has not been performed as it would leed to no change. The revision to restore is identical to the current one.</p>
</div>

-- 8< -- textfile: messages/file_restore_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>File '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The file has not been restored, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/file_revision_list_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Cannot display revision list for file '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>Either this file does not exist or an internal error occurred.</p>
</div>

-- 8< -- textfile: /wiki/file/index.html -- >8 --

<& wiki::backend::file / &>

