#TODO: can the <& tags / &> plugin set the tags itself so that the blog plugin
#      doesn't have to call $tags->set()?!
#FEATURE: ping blog search engines and aggregators (pingomatic.com, technorati, google, blah...)
#FEATURE: rss/rdf-"export": tags => needs nested lists template feature
#FEATURE: headline for each new day
#FEATURE: small list of topics (for a sidebar or so)
#FEATURE: calendar
#FEATURE: wiki markup also in comments?

=head1 NAME

Konstrukt::Plugin::blog - Konstrukt blogging engine

=head1 SYNOPSIS
	
	<& blog / &>
	
=head1 DESCRIPTION

This Konstrukt Plug-In provides blogging-facilities for your website.

You may simply integrate it by putting
	
	<& blog / &>
	
somewhere in your website.

To show a form to filter the entries put

	<& blog show="filter" / &>
	
in your page source.

If you want to get your content as an RSS 2.0 compliant XML file you may want
to put

	<& blog show="rss2" / &>

alone in a separate file.

If you want to allow trackbacks to your blog entries, you have to to put

	<& blog show="trackback" / &>

alone in a separate file, which you should advertise as the trackback ping URL.

The HTTP parameters "email" and "pass" will be used to log on the user before
retrieving the entries. This will also return private entries.

	http://domain.tld/blog_rss2.ihtml?email=foo@bar.baz;pass=23

=head1 CONFIGURATION

You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Default:

	#backend
	blog/backend                  DBI
	
	#layout
	blog/entries_per_page         5
	blog/template_path            /templates/blog/
	
	#user levels
	blog/userlevel_write          2
	blog/userlevel_admin          3
	
	#rss export
	blog/rss2_template            /templates/blog/export/rss2.template
	blog/rss2_entries             20 #number of exported entries
	
	#prefix for cached rendered article markup
	blog/cache_prefix             blog_article_cache/
	
	#use a captcha to prevent spam
	blog/use_captcha              1 #you have to put <& captcha / &> inside your add-template
	
	#the content type of the entries.
	#will be sent to trackback services.
	blog/trackback/content_type   utf-8
	#permalink URI to your blog entries.
	#will be sent to the pinged sites. the parameter ?action=show;id=42 with the correct id of the entry will be appended.
	#by default, this setting is undefined and the plugin tries to guess the right permalink, what may fail
	blog/trackback/permalink      http://your.site/blog/
	
See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::blog::DBI/CONFIGURATION>) for their configuration.

=cut

package Konstrukt::Plugin::blog;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

use POSIX; #needed for ceil

use Konstrukt::Cache;
use Konstrukt::Debug;

=head1 METHODS


=head2 execute_again

Yes, this plugin may return dynamic nodes (i.e. template nodes).

=cut
sub execute_again {
	return 1;
}
#= /execute_again


=head2 init

Initializes this object. Sets $self->{backend} and $self->{template_path}.
init will be called by the constructor.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic}    = use_plugin 'usermanagement::basic'    or return undef;
	$self->{user_level}    = use_plugin 'usermanagement::level'    or return undef;
	$self->{user_personal} = use_plugin 'usermanagement::personal' or return undef;
	
	#set default settings
	$Konstrukt::Settings->default("blog/backend"                => 'DBI');
	$Konstrukt::Settings->default("blog/entries_per_page"       => 5);
	$Konstrukt::Settings->default("blog/template_path"          => '/templates/blog/');
	$Konstrukt::Settings->default("blog/userlevel_write"        => 2);
	$Konstrukt::Settings->default("blog/userlevel_admin"        => 3);
	$Konstrukt::Settings->default("blog/rss2_entries"           => 20);
	$Konstrukt::Settings->default("blog/rss2_template"          => $Konstrukt::Settings->get("blog/template_path") . "export/rss2.template");
	$Konstrukt::Settings->default("blog/cache_prefix"           => '/blog_article_cache/');
	$Konstrukt::Settings->default("blog/use_captcha"            => 1);
	$Konstrukt::Settings->default("blog/trackback/content_type" => 'utf-8');
	
	$self->{backend}       = use_plugin "blog::" . $Konstrukt::Settings->get('blog/backend') or return undef;
	$self->{template_path} = $Konstrukt::Settings->get("blog/template_path");
	
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

=head2 prepare

Prepare method

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub prepare { 
	my ($self, $tag) = @_;

	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare


=head2 execute

All the work is done in the execute step.

B<Parameters>:

=over

=item * $tag - Reference to the tag (and its children) that shall be handled.

=back

=cut
sub execute {
	my ($self, $tag) = @_;

	#reset the collected nodes
	$self->reset_nodes();

	my $show = $tag->{tag}->{attributes}->{show} || '';
	
	if ($show eq 'rss2') {
		$self->export_rss();
	} elsif ($show eq 'trackback') {
		$self->trackback_process();
	} elsif ($show eq 'filter') {
		$self->filter_show();
	} else {
		my $action = $Konstrukt::CGI->param('action') || '';
		
		#user logged in?
		if ($self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_write')) {
			#operations that are accessible to "bloggers"
			if ($action eq 'showadd') {
				$self->add_entry_show();
			} elsif ($action eq 'add') {
				$self->add_entry();
			} elsif ($action eq 'showedit') {
				$self->edit_entry_show();
			} elsif ($action eq 'edit') {
				$self->edit_entry();
			} elsif ($action eq 'showdelete') {
				$self->delete_entry_show();
			} elsif ($action eq 'delete') {
				$self->delete_entry();
			} elsif ($action eq 'show') {
				$self->show_entry();
			} elsif ($action eq 'addcomment') {
				$self->add_comment();
			} elsif ($action eq 'deletecomment') {
				$self->delete_comment();
			} elsif ($action eq 'deletetrackback') {
				$self->delete_trackback();
			} elsif ($action eq 'filter') {
				$self->show_entries();
			} else {
				$Konstrukt::Debug->error_message("Invalid action '$action'!") if Konstrukt::Debug::ERROR and $action;
				$self->show_entries();
			}
		} else {
			#operations that are accessible to all visitors
			if ($action eq 'show') {
				$self->show_entry();
			} elsif ($action eq 'addcomment') {
				$self->add_comment();
			} else {
				$self->show_entries();
			}
		}
	}
	
	return $self->get_nodes();
}
#= /handler


=head2 add_entry_show

Displays the form to add an article.

=cut
sub add_entry_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	$self->add_node($template->node("$self->{template_path}layout/entry_add_form.template"));
}
#= /add_entry_show


=head2 add_entry

Takes the HTTP form input and adds a new blog entry.

Desplays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_add_form.form");
	$form->retrieve_values('cgi');
	my $log = use_plugin 'log';
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $tags     = use_plugin 'tags';
		my $wiki     = use_plugin 'wiki';
		
		#get data
		my ($title, $description, $content, $private, $tagstring, $trackback_discovery, $trackback_links) = map { $form->get_value($_); } qw/title description content private tags trackback_discovery trackback_links/;
		my $author = $self->{user_basic}->id();
		
		if ($form->get_value('preview')) {
			#show preview only

			#render content
			my $rendered = (use_plugin 'wiki')->convert_markup_string($content);
			
			#escape output
			map { $_ = $Konstrukt::Lib->html_escape($_) } ($title, $description, $content, $private, $tagstring, $trackback_discovery, $trackback_links);
			
			#put entry and form templates
			$self->add_node($template->node("$self->{template_path}layout/entry_preview.template", { title => $title, description => $description, content => $rendered }));
			$self->add_node($template->node("$self->{template_path}layout/entry_add_form.template", { title => $title, description => $description, content => $content, private => $private, tags => $tagstring, trackback_discovery => $trackback_discovery, trackback_links => $trackback_links }));
		} else {
			#add entry
			my $id = $self->{backend}->add_entry($title, $description, $content, $author, $private);
			if (defined $id and $tags->set('blog', $id, $tagstring)) {
				#success
				my $author_name = $self->{user_basic}->email();
				$log->put(__PACKAGE__ . '->add_entry', "$author_name added a new blog entry with the title '$title'.", $author_name, $id, $title);
				$self->add_node($template->node("$self->{template_path}messages/entry_add_successful.template"));
				
				#ping trackbacks
				$self->extract_and_ping_trackbacks($id, $title, $description, $content, $trackback_discovery, $trackback_links);
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_add_failed.template"));
			}
			$self->show_entries();
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_entry


=head2 extract_and_ping_trackbacks

Accepts the blog entry's content and trackback links, tries to discover
trackbacklinks from the pages linked in the content and sends pings to all
websites, that have been referenced.  

B<Parameters>:

=over

=item * $id - The id of the blog entry.

=item * $title - The title of the blog entry.

=item * $excerpt - The description/excerpt of the blog entry.

=item * $content - The content of the blog entry, that may contain links to
websites, for which a trackback autodiscovery may be performed.

=item * $trackback_discovery - True, if autodiscovery should be performed.

=item * $trackback_links - The newline-separated trackback-links that have
been explicitly specified by the user

=back

=cut
sub extract_and_ping_trackbacks {
	my ($self, $id, $title, $excerpt, $content, $trackback_discovery, $trackback_links) = @_;
	
	#add trackbacks:
	my $trackbacks;
	#autodiscover trackbacks for links in the content
	if ($trackback_discovery) {
		my @urls = ($content =~ /(http:\/\/[^\s"'\]\|]+)/gi);
		foreach my $url (@urls) {
			my $trackback = $self->trackback_discover($url);
			$trackbacks->{$trackback} = 1 if $trackback;
		}
	}
	#add the manually entered trackbacks
	my @urls = split /\s*\r?\n\s*/, ($trackback_links || '');
	$trackbacks->{$_} = 1 for @urls;
	#ping the collected trackbacks
	my $permalink = $self->generate_permalink($id);
	$self->trackback_ping($_, { url => $permalink, title => $title, excerpt => $excerpt }) for keys %{$trackbacks};
}
# /extract_and_ping_trackbacks


=head2 generate_permalink

Generates a permalink to a blog entry using the settings or guessing it.  

B<Parameters>:

=over

=item * $id - The id of the blog entry.

=back

=cut
sub generate_permalink {
	my ($self, $id) = @_;
	
	my $permalink = $Konstrukt::Settings->get("blog/trackback/permalink");
	unless ($permalink) {
		#build URL
		$permalink = "http://" . $Konstrukt::Handler->{ENV}->{HTTP_HOST} . $Konstrukt::Handler->{ENV}->{REQUEST_URI};
		#remove CGI parameters
		$permalink =~ s/\?.*//;
	}
	#add action and id parameters
	$permalink .= "?action=show;id=$id";
	
	return $permalink;
}
# /generate_permalink


=head2 edit_entry_show

Grabs the article from the backend and puts it into a form from which the
user may edit the article.

Displays the form to edit an article.

=cut
sub edit_entry_show {
	my ($self) = @_;

	my $id  = $Konstrukt::CGI->param('id');
	if ($id) {
		my $template = use_plugin 'template';
		my $tags     = use_plugin 'tags';

		#get entry
		my $entry = $self->{backend}->get_entry($id);
		#prepare data
		map { $entry->{$_} = $Konstrukt::Lib->html_escape($entry->{$_}) } qw/title description content/;
		my $data = {
			fields => $entry,
			tags => (join " ", map { $Konstrukt::Lib->html_escape($_); /\s/ ? "\"$_\"" : $_ } @{$tags->get('blog', $id)}) . " "
		};
		#put out the template node
		$self->add_node($template->node("$self->{template_path}layout/entry_edit_form.template", $data));
	} else {
		$Konstrukt::Debug->error_message('No id specified!') if Konstrukt::Debug::ERROR;
	}
}
#= /edit_entry_show


=head2 edit_entry

Takes the HTTP form input and updates the requested blog entry.

Displays a confirmation of the successful update or error messages otherwise.

=cut
sub edit_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_edit_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $tags     = use_plugin 'tags';
		
		#get data
		my ($id, $title, $description, $content, $private, $update, $tagstring, $trackback_discovery, $trackback_links) = map { $form->get_value($_) } qw/id title description content private update_date tags trackback_discovery trackback_links/;
		
		if ($form->get_value('preview')) {
			#show preview only

			#render content
			my $rendered = (use_plugin 'wiki')->convert_markup_string($content);
			
			#escape output
			map { $_ = $Konstrukt::Lib->html_escape($_) } ($id, $title, $description, $content, $private, $tagstring, $trackback_discovery, $trackback_links);
			
			#put entry and form templates
			$self->add_node($template->node("$self->{template_path}layout/entry_preview.template", { title => $title, description => $description, content => $rendered }));
			$self->add_node($template->node("$self->{template_path}layout/entry_edit_form.template", { id => $id, title => $title, description => $description, content => $content, private => $private, tags => $tagstring, trackback_discovery => $trackback_discovery, trackback_links => $trackback_links }));
		} else {
			#delete cache file for this article as the content has changed
			$self->delete_cache_content($id);
			
			my $entry = $self->{backend}->get_entry($id);
			if ($entry->{author} == $self->{user_basic}->id()) {
				if ($self->{backend}->update_entry($id, $title, $description, $content, $private, $update) and $tags->set('blog', $id, $tagstring)) {
					#success
					$self->add_node($template->node("$self->{template_path}messages/entry_edit_successful.template"));
					
					#ping trackbacks
					$self->extract_and_ping_trackbacks($id, $title, $description, $content, $trackback_discovery, $trackback_links);
				} else {
					#failed
					$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed.template"));
				}
			} else {
				#permission denied
				$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed_permission_denied.template"));
			}
			$self->show_entries();
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_entry


=head2 delete_entry_show

Displays the confirmation form to delete an article.

=cut
sub delete_entry_show {
	my ($self) = @_;
	
	my $id    = $Konstrukt::CGI->param('id');
	if ($id) {
		my $template = use_plugin 'template';
		my $article  = $self->{backend}->get_entry($id);
		if (keys %{$article}) {
			$self->add_node($template->node("$self->{template_path}layout/entry_delete_form.template", { title => $article->{title}, id => $id }));
		} else {
			$Konstrukt::Debug->error_message("Entry $id does not exist!") if Konstrukt::Debug::ERROR;
		}
	} else {
		$Konstrukt::Debug->error_message('No id specified!') if Konstrukt::Debug::ERROR;
		$self->show_entries();
	}
}
#= / delete_entry_show


=head2 delete_entry

Deletes the specified entry.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_delete_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $tags     = use_plugin 'tags';
		
		my $id       = $form->get_value('id');
		my $entry    = $self->{backend}->get_entry($id);
		if ($entry->{author} == $self->{user_basic}->id() or $self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_admin')) {
			#delete cache
			$self->delete_cache_content($id);
			#delete entry
			if ($id and $self->{backend}->delete_entry($id) and $tags->delete('blog', $id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/entry_delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_delete_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/entry_delete_failed_permission_denied.template"));
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_entry


=head2 show_entry

Shows the requested blog entry including its comments

Displays the entry or error messages otherwise.

B<Parameters>:

=over

=item * $id - ID of the entry to show (optional)

=back

=cut
sub show_entry {
	my ($self, $id) = @_;
	
	if (!$id) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/entry_show.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			$id = $form->get_value('id');
		}
	}
	
	if ($id) {
		my $template   = use_plugin 'template';
		my $tags       = use_plugin 'tags';
		my $entry      = $self->{backend}->get_entry($id);
		if (defined $entry) {
			my $may_edit   = ($entry->{author} == $self->{user_basic}->id() or $entry->{author} == 0);
			my $may_delete = ($may_edit or $self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_admin'));
			if (not $entry->{private} or $may_edit) {
				#prepare data
				$entry->{author_id}  = $entry->{author};
				$entry->{author}     = $self->{user_personal}->data($entry->{author_id})->{nick} || undef;
				$entry->{content}    = $self->format_and_cache_content($id, $entry->{content});
				$entry->{may_edit}   = $may_edit;
				$entry->{may_delete} = $may_delete;
				map { $entry->{$_} = $Konstrukt::Lib->html_escape($entry->{$_}) } qw/title description/;
				map { $entry->{$_} = sprintf("%02d", $entry->{$_}) } qw/month day hour minute/;
				my @tags = map { $Konstrukt::Lib->html_escape($_) } @{$tags->get('blog', $id)};
				my $data = { fields => $entry, tags => [ map { { title => $_ } } @tags ] };
				
				#add entry
				$self->add_node($template->node("$self->{template_path}layout/entry_full.template", $data));
				
				#add trackbacks
				my $trackbacks = $self->{backend}->get_trackbacks($id);
				if (@{$trackbacks}) {
					foreach my $trackback (@{$trackbacks}) {
						map { $trackback->{$_} = $Konstrukt::Lib->html_escape($trackback->{$_}) } qw/title excerpt blog_name/;
						map { $trackback->{$_} = sprintf("%02d", $trackback->{$_}) } qw/month day hour minute/;
						$trackback->{may_delete}  = $may_delete;
						$trackback->{lasttrackback} = ($trackback eq $trackbacks->[-1]);
					}
					$self->add_node($template->node("$self->{template_path}layout/trackbacks.template", { trackbacks => [ map { { fields => $_ } } @{$trackbacks} ] }));
				} else {
					$self->add_node($template->node("$self->{template_path}layout/trackbacks_empty.template"));
				}
				
				#add comment form
				$self->add_comment_show($id);
				
				#add comments
				my $comments = $self->{backend}->get_comments($id);
				if (@{$comments}) {
					foreach my $comment (@{$comments}) {
						#get username from db, if comment was written by a registered user
						$comment->{author} ||= $self->{user_personal}->data($comment->{user})->{nick} if $comment->{user};
						map { $comment->{$_} = $Konstrukt::Lib->html_escape($comment->{$_}) } qw/email author text/;
						map { $comment->{$_} = sprintf("%02d", $comment->{$_}) } qw/month day hour minute/;
						$comment->{email}       = undef unless $comment->{email_public}; 
						$comment->{text}        = $Konstrukt::Lib->html_paragraphify($comment->{text});
						$comment->{author_id}   = $comment->{user};
						$comment->{may_delete}  = $may_delete;
						$comment->{lastcomment} = ($comment eq $comments->[-1]);
					}
					$self->add_node($template->node("$self->{template_path}layout/comments.template", { comments => [ map { { fields => $_ } } @{$comments} ] }));
				} else {
					$self->add_node($template->node("$self->{template_path}layout/comments_empty.template"));
				}
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/entry_show_failed_not_exists.template"));
		}
	}
}
#= /show_entry


=head2 show_entries

Shows the blog entries

Displays the entries or error messages otherwise.

=cut
sub show_entries {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $tags     = use_plugin 'tags';
	
	#filters?
	my $select;
	if (($Konstrukt::CGI->param('action') || '') eq 'filter') {
		#get search parameters
		my ($tagstring, $author, $year, $month, $text) = map { $Konstrukt::CGI->param($_) } qw/tags author year month text/;
		#force numeric values to prevent warning "'SPAM' isn't numeric in numeric gt (>)"
		{
			no warnings;
			map { $_ += 0 if defined $_ } ($author, $year, $month);
		}
		#build "query"
		$select->{tags}   = $tagstring if defined $tagstring and length($tagstring);
		$select->{author} = $author    if defined $author    and $author   > 0;
		$select->{year}   = $year      if defined $year      and $year     > 0;
		$select->{month}  = $month     if defined $month     and $month    > 0 and $month < 13;
		$select->{text}   = $text      if defined $text      and length($text);
	}
	
	#show admin features?
	my $is_admin = $self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_admin');
	$self->add_node($template->node("$self->{template_path}layout/entry_add_link.template"))
		if $is_admin;
		
	#calculate page range
	my $page  = $Konstrukt::CGI->param('page') || 1;
	$page = 1 unless $page > 0;
	my $count = $Konstrukt::Settings->get('blog/entries_per_page');
	my $pages = ceil($self->{backend}->get_entries_count($select) / $count);
	my $start = ($page - 1) * $count;
	
	#show entries
	my $entries = $self->{backend}->get_entries($select, $start, $count);
	if (@{$entries}) {
		my $uid = $self->{user_basic}->id();
		foreach my $entry (@{$entries}) {
			#private entries will only be visible to the author
			my $may_edit   = ($entry->{author} == $uid or $entry->{author} == 0);
			my $may_delete = ($may_edit or $is_admin);
			if (not $entry->{private} or $may_edit) {
				#prepare data
				$entry->{author_id}  = $entry->{author};
				$entry->{author}     = $self->{user_personal}->data($entry->{author_id})->{nick} || undef;
				$entry->{content}    = $self->format_and_cache_content($entry->{id}, $entry->{content});
				$entry->{may_edit}   = $may_edit;
				$entry->{may_delete} = $may_delete;
				map { $entry->{$_} = $Konstrukt::Lib->html_escape($entry->{$_}) } qw/author title description/;
				map { $entry->{$_} = sprintf("%02d", $entry->{$_}) } qw/month day hour minute/;
				
				#get tags
				my @tags = map { $Konstrukt::Lib->html_escape($_) } @{$tags->get('blog', $entry->{id})};
				
				#put entry node
				my $data = { fields => $entry, tags => [ map { { title => $_ } } @tags ] };
				$self->add_node($template->node("$self->{template_path}layout/entry_short.template", $data));
			}
		}
		$self->add_node($template->node("$self->{template_path}layout/entries_nav.template", { prev_page => ($page > 1 ? $page - 1 : 0), next_page => ($page < $pages ? $page + 1 : 0) })) if $pages > 1;
	} else {
		$self->add_node($template->node("$self->{template_path}layout/entries_empty.template"));
	}
}
#= /show_entries


=head2 format_and_cache_content

Take plain text and formats it using the wiki plugin. Caches the result.
If a cached file already exists, the cached result will be used.

Returns a field tag node contatining the formatted output nodes.

B<Parameters>:

=over

=item * $id - The ID of the article

=item * $content - The (plaintext) content

=back

=cut
sub format_and_cache_content {
	my ($self, $id, $content) = @_;
	
	#get cached wiki markup or create it
	my $cached_filename = $Konstrukt::Settings->get("blog/cache_prefix") . $id;
	$cached_filename = $Konstrukt::File->absolute_path($cached_filename);
	my $cached = $Konstrukt::Cache->get_cache($cached_filename);
	if (defined $cached) {
		#we're already done with this file
		$Konstrukt::File->pop();
	} else {
		#render article and cache it.
		$cached = (use_plugin 'wiki')->convert_markup_string($content);
		#cache it
		$Konstrukt::Cache->write_cache($cached_filename, $cached);
	}
	
	return $cached;
}
#= /format_and_cache_content


=head2 delete_cache_content

Deletes the content cache for a given article

B<Parameters>:

=over

=item * $id - The ID of the article

=back

=cut
sub delete_cache_content {
	my ($self, $id) = @_;
	
	#get cached wiki markup or create it
	my $cached_filename = $Konstrukt::Settings->get("blog/cache_prefix") . $id;
	$cached_filename = $Konstrukt::File->absolute_path($cached_filename);
	return $Konstrukt::Cache->delete_cache($cached_filename);
}
#= /delete_cache_content


=head2 add_comment_show

Takes the specified entry ID or HTTP form input and shows the form to add a comment.

Displays the form to add a comment.

B<Parameters>:

=over

=item * $id - ID of the entry, which shall be commented. (optional)

=back

=cut
sub add_comment_show {
	my ($self, $id) = @_;
	
	if (!$id) {
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/entry_show.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			$id = $form->get_value('id');
		} else {
			$self->add_node($form->errors());
			return;
		}
	}
	
	if ($id) {
		my $template = use_plugin 'template';
		my $uid    = $self->{user_basic}->id();
		if ($uid) {
			$self->add_node($template->node("$self->{template_path}layout/comment_add_form_registered.template", { id => $id, author => $self->{user_personal}->data($uid)->{nick}, email => $Konstrukt::Lib->html_escape($self->{user_basic}->data($uid)->{email}) }));
		} else {
			$self->add_node($template->node("$self->{template_path}layout/comment_add_form.template", { id => $id }));
		}
	}
}
#= /add_comment_show


=head2 add_comment

Takes the HTTP form input and adds a new comment.

Displays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_comment {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/comment_add_form.form");
	$form->retrieve_values('cgi');
	my $log = use_plugin 'log';
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $userid   = $self->{user_basic}->id();
		my ($id, $author, $email, $email_public, $email_notify, $text)
			= map { $form->get_value($_) } qw/id author email email_public email_notify text/;
		if (not $Konstrukt::Settings->get('blog/use_captcha') or (use_plugin 'captcha')->check()) {
			#save the authors who want to be notified for a new comment
			my %authors = map { ($_->{email_notify} and $_->{email}) ? ($_->{email} => 1) : ()  } @{$self->{backend}->get_comments($id)};
			$authors{$self->{user_basic}->email($self->{backend}->get_entry($id)->{author})} = 1;
			my @authors = keys %authors;
			#add comment
			if ($self->{backend}->add_comment($id, $userid, $author, $email, $email_public, $email_notify, $text)) {
				#success
				my $author_name = join ' / ', ($author, (($userid ? $self->{user_basic}->email() : undef) || $email) || ());
				my $entry_title = $self->{backend}->get_entry($id)->{title} || '';
				
				#log
				$log->put(__PACKAGE__ . '->add_comment', "$author_name added a new comment to blog entry '$entry_title'.", $id, $entry_title, $author_name);
				
				#send mail to all authors who want notifications
				my $mailfile = $Konstrukt::File->read("$self->{template_path}messages/comment_email_notification.email");
				if (defined($mailfile)) {
					my $mail;
					eval($mailfile);
					#Check for errors
					if ($@) {
						#Errors in eval
						chomp($@);
						$Konstrukt::Debug->error_message("Error while loading mail template '$self->{template_path}messages/comment_email_notification.email'! $@") if Konstrukt::Debug::ERROR;
					} else {
						my $entry = $self->{backend}->get_entry($id);
						my $permalink = $self->generate_permalink($id);
						$mail->{subject} =~ s/\$topic\$/$entry->{title}/gi;
						$mail->{body} =~ s/\$topic\$/$entry->{title}/gi;
						$mail->{body} =~ s/\$author\$/$author/gi;
						$mail->{body} =~ s/\$url\$/$permalink/gi;
						foreach my $notify_author (@authors) {
							$Konstrukt::Lib->mail($mail->{subject}, $mail->{body}, $notify_author)
								if length($notify_author);
						}
					}
				}
				
				#put success message
				$self->add_node($template->node("$self->{template_path}messages/comment_add_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/comment_add_failed.template"));
			}
		} else {
			#captcha not solved
			$self->add_node($template->node("$self->{template_path}messages/comment_add_failed_captcha.template"));
		}
		$self->show_entry($id);
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_comment


=head2 delete_comment

Takes the HTTP form input and removes an existing comment.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_comment {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	if ($self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_admin')) {
		
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/comment_delete_form.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			my $id = $form->get_value('id');
			my $comment = $self->{backend}->get_comment($id);
			if ($self->{backend}->delete_comment($id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/comment_delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/comment_delete_failed.template"));
			}
			$self->show_entry($comment->{entry});
		} else {
			$self->add_node($form->errors());
			return $form->errors();
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/comment_delete_failed_permission_denied.template"));
	}
}
#= /delete_comment


=head2 filter_show

Displays the form to select articles.

=cut
sub filter_show {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $authors = $self->{backend}->get_authors();

	#get author names
	foreach my $author (@{$authors}) {
		$author = {
			id => $author,
			name => $Konstrukt::Lib->html_escape($self->{user_personal}->data($author)->{nick}) || undef
		};
	}
	#sort authors
	$authors = [ sort { ($a->{name} || '') cmp ($b->{name} || '') } @{$authors} ];
	
	$self->add_node($template->node("$self->{template_path}layout/filter_form.template", { authors => [ map { { fields => $_ } } @{$authors} ] }));
}
#= /filter_show


=head2 export_rss

Generates an RSS 2.0 compliant XML file with the content from the database.

=cut
sub export_rss {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	my $tags     = use_plugin 'tags';

	#try to log on user, if parameters specified
	my ($email, $pass) = ($Konstrukt::CGI->param('email'), $Konstrukt::CGI->param('pass'));
	if ($email and $pass) {
		$self->{user_basic}->login($email, $pass);
	}

	#get entries
	my $limit = $Konstrukt::Settings->get('blog/rss2_entries') || 20;
	my $entries = $self->{backend}->get_entries(undef, 0, $limit);
	
	#prepare items
	my @items;
	foreach my $entry (@{$entries}) {
		if (!$entry->{private}) {
			#"generate" author
			my $autor_data = $self->{user_personal}->data($entry->{author});
			my $firstname  = $autor_data->{firstname};
			my $lastname   = $autor_data->{lastname};
			my $nick       = $autor_data->{nick};
			my $email      = $autor_data->{email};
			my $author     = undef;
			if ($nick) {
				$author = $nick;
			}
			if ($firstname and $lastname) {
				$author .= ($author ? " ($firstname $lastname)" : "$firstname $lastname");
			}
			
			#add item
			push @items, {
				id          => $entry->{id},
				title       => $Konstrukt::Lib->xml_escape($entry->{title}),
				description => $Konstrukt::Lib->xml_escape($entry->{description}),
				content     => $Konstrukt::Lib->xml_escape($self->format_and_cache_content($entry->{id}, $entry->{content})),
				author      => $Konstrukt::Lib->xml_escape($author),
				date_w3c    => $Konstrukt::Lib->date_w3c($entry->{year}, $entry->{month}, $entry->{day}, $entry->{hour}, $entry->{minute}),
				date_rfc822 => $Konstrukt::Lib->date_rfc822($entry->{year}, $entry->{month}, $entry->{day}, $entry->{hour}, $entry->{minute}),
#				tags        => [ map { { title => $Konstrukt::Lib->xml_escape($_) } } @{$tags->get('blog', $entry->{id})} ],
			};
		}
	}
	
	#date of the feed
	my $date_w3c    = @items ? $items[0]->{date_w3c}    : '0000-00-00';
	my $date_rfc822 = @items ? $items[0]->{date_rfc822} : '01 Jan 1970 00:00:00 +0000';
	
	#show
	$self->add_node($template->node($Konstrukt::Settings->get('blog/rss2_template'), { date_w3c => $date_w3c, date_rfc822 => $date_rfc822, items => \@items }));

	$Konstrukt::Response->header('Content-Type' => 'text/xml');
}
#= /export_rss


=head2 trackback_ping

Pings a specified trackback address with the specified information.

Returns true on success, false otherwise.

B<Parameters>:

=over

=item * $url - The URL of the trackback link 

=item * $info - The information about the pinging article.
A hashref containing this information:

	{
		url => 'URL of the entry (required)',
		title => 'Title of the entry (optional)',
		excerpt => 'Excerpt of the entry (optional)',
		blog_name => 'Name of the blog (optional)',
	}

=back

=cut
sub trackback_ping {
	my ($self, $url, $info) = @_;
	
	my $template = use_plugin 'template';
	
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new(agent => "Konstrukt/$Konstrukt::VERSION - blog plugin", timeout => 15);
	
	my $response = $ua->post(
		$url,
		$info,
		'Content-Type' => "application/x-www-form-urlencoded; charset=" . $Konstrukt::Settings->get('blog/trackback/content_type')
	);
	
	unless ($response->is_success()) {
		$self->add_node($template->node("$self->{template_path}messages/trackback_ping_failed.template", { url => $url }));
		return;
	}
	
	#was the ping successful?
	my $content = $response->content();
	if ($content =~ /<error>0<\/error>/) {
		$self->add_node($template->node("$self->{template_path}messages/trackback_ping_successful.template", { url => $url, message => $response->status_line() }));
		return 1;
	} else {
		$content =~ /<message>(.*?)<\/message>/;
		my $message = $1 || 'Unknown error';
		$self->add_node($template->node("$self->{template_path}messages/trackback_ping_failed.template", { url => $url, message => $message }));
	}
}
#= /trackback_ping


=head2 trackback_discover

Downloads a blog entry and tries to discover the trackback link to this entry.

Returns the URL of the trackback link on success, undef otherwise.

B<Parameters>:

=over

=item * $url - The URL of the blog entry 

=back

=cut
sub trackback_discover {
	my ($self, $url) = @_;
	
	require LWP::UserAgent;
	my $ua = LWP::UserAgent->new(agent => "Konstrukt/$Konstrukt::VERSION - blog plugin", timeout => 15);

	my $response = $ua->get($url);
	
	unless ($response->is_success()) {
		my $template = use_plugin 'template';
		$self->add_node($template->node("$self->{template_path}messages/trackback_discover_failed.template", { url => $url, message => $response->status_line() }));
		return;
	}
	
	my $content = $response->content();
	
	#parse out all RDF sections, take the one with
	#a dc:identifier == $url and extract the trackback:ping address
	#warn $content =~ /(<rdf:RDF.*?<\/rdf:RDF>)/s;
	my @rdf_sections = $content =~ /(<rdf:RDF.*?<\/rdf:RDF>)/s;
	foreach my $rdf (@rdf_sections) {
		my ($ident_url) = $rdf =~ /dc:identifier="([^"#]+)/;
		if ($ident_url eq $url) {
			$rdf =~ /trackback:ping="([^"#]+)/;
			return $1;
		}
	}
	
	#try to find <a href="..." rel="trackback">
	my ($trackback_link) = $content =~ /<(a [^>]*rel="trackback"[^>]*)>/s;
	if ($trackback_link) {
		my $tag = $Konstrukt::Parser->parse_tag($trackback_link);
		my $href = $tag->{attributes}->{href};
		if ($href) {
			unless ($href =~ /^http:\/\//) {
				#partial href. prepend the rest of the path
				if ($href =~ /^\//) {
					#href starts with a slash. absolute path
					$url =~ /(^http:\/\/[^\/]+)\//;
					$href = "$1$href";
				} else {
					#href is a relative path
					$url =~ /(^http:\/\/.+\/)/;
					$href = "$1$href";
				}
			}
			return $href;
		}
	}
}
#= /trackback_discover


=head2 trackback_process

Processes an incoming trackback request. The ID of the blog entry must be
specified as an URL parameter:

	http://your.site/blog/trackback/id=42

Returns the appropriate response to the client.

B<Parameters>: none

=cut
sub trackback_process {
	my ($self) = @_;
	
	my ($url, $title, $excerpt, $blog_name) = map { $Konstrukt::CGI->param($_) || undef } qw/url title excerpt blog_name/;
	my $entry = $Konstrukt::CGI->url_param('id');
	
	my ($error, $error_message);
	if (not defined $url) {
		($error, $error_message) = (1, "No URL specified");
	} elsif ($url !~ /^http\:\/\/\S+$/i) {
		($error, $error_message) = (1, "Invalid URL: $url");
	} elsif (not defined $entry) {
		($error, $error_message) = (1, "No blog entry ID specified");
	} else {
		#antispam:
		#- check, if the ping source is reachable
		#- and if it contains a link to this website
		
		my $host = $Konstrukt::Handler->{ENV}->{HTTP_HOST};
		require LWP::UserAgent;
		my $ua = LWP::UserAgent->new(agent => "Konstrukt/$Konstrukt::VERSION - blog plugin", timeout => 15);
		my $response = $ua->get($url);
		if (not $response->is_success()) {
			#source url cannot be downloaded
			($error, $error_message) = (1, "Ping source $url cannot be reached.");
		} elsif ($response->content() !~ /href=["']http:\/\/(www\.)?$host\/.+/) {
			#not href to this website found
			($error, $error_message) = (1, "Ping source doesn't contain a link to '$host'");
		} elsif (not defined $self->{backend}->get_entry($entry)) {
			#entry does not exist
			($error, $error_message) = (1, "The entry with the ID $entry does not exist");
		} elsif (not $self->{backend}->add_trackback($entry, $url, $title, $excerpt, $blog_name)) {
			#error on addition
			($error, $error_message) = (1, "An internal error occurred while adding the trackback");
		} else {
			#addition successful
			my $log = use_plugin 'log';
			my $entry_title = $self->{backend}->get_entry($entry)->{title};
			$log->put(__PACKAGE__ . '->trackback_process', "New trackback from $url for blog entry with the title '$entry_title'.", $url, $entry);
			$error = 0;
		}
	}
	
	$Konstrukt::Response->header('Content-Type' => 'text/xml');
	$self->add_node(
		"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<response>\n" .
		"<error>$error</error>\n" .
		($error ? "<message>$error_message</message>\n" : "") .
		"</response>"
	);
}
#= /trackback_process


=head2 delete_trackback

Takes the HTTP form input and removes an existing trackback.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_trackback {
	my ($self) = @_;
	
	my $template = use_plugin 'template';
	
	if ($self->{user_level}->level() >= $Konstrukt::Settings->get('blog/userlevel_admin')) {
		
		my $form = use_plugin 'formvalidator';
		$form->load("$self->{template_path}layout/trackback_delete_form.form");
		$form->retrieve_values('cgi');
		
		if ($form->validate()) {
			my $id = $form->get_value('id');
			my $trackback = $self->{backend}->get_trackback($id);
			if ($self->{backend}->delete_trackback($id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/trackback_delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/trackback_delete_failed.template"));
			}
			$self->show_entry($trackback->{entry});
		} else {
			$self->add_node($form->errors());
			return $form->errors();
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/trackback_delete_failed_permission_denied.template"));
	}
}
#= /delete_trackback


1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::blog::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: export/rss2.template -- >8 --

<?xml version="1.0" encoding="ISO-8859-15"?>
<rss version="2.0" 
	xmlns:admin="http://webns.net/mvcb/"
	xmlns:dc="http://purl.org/dc/elements/1.1/"
	xmlns:sy="http://purl.org/rss/1.0/modules/syndication/"
	xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
	xmlns:content="http://purl.org/rss/1.0/modules/content/">
	<channel>
		<title>untitled website</title>
		<link>http://your.website/</link>
		<description>no description</description>
		<!-- <category>???</category> -->
		<webMaster>mail@some.host</webMaster>
		<ttl>60</ttl>
		<admin:generatorAgent rdf:resource="http://your.website/?v=1.0"/>
		<admin:errorReportsTo rdf:resource="mailto:mail@some.host"/>
		<dc:language>en</dc:language>
		<dc:creator>mail@some.host</dc:creator>
		<dc:rights>Copyright 2000-2050</dc:rights>
		<dc:date><+$ date_w3c / $+></dc:date>
		<sy:updatePeriod>hourly</sy:updatePeriod>
		<sy:updateFrequency>1</sy:updateFrequency>
		<sy:updateBase>2000-01-01T12:00+00:00</sy:updateBase>
		<image>
			<url>http://your.website//gfx/logo.jpg</url>
			<title>untitled</title>
			<link>http://your.website/</link>
			<width>350</width>
			<height>39</height>
		</image>
		<+@ items @+><item rdf:about="http://your.website/blog/?action=show;id=<+$ id / $+>">
			<title><+$ title / $+></title>
			<link>http://www.gedankenkonstrukt.de/blog/?action=show;id=<+$ id / $+></link>
			<description><+$ description / $+></description>
			<!--  <category domain="<+$ category_id / $+>"><+$ category_name / $+></category> -->
			<guid isPermaLink="true">http://your.website/blog/?action=show;id=<+$ id / $+></guid>
			<comments>http://your.website/blog/?action=show;id=<+$ id / $+></comments>
			<pubDate><+$ date_rfc822 / $+></pubDate>
			<dc:date><+$ date_w3c / $+></dc:date>
			<dc:creator><+$ author / $+></dc:creator>
			<!-- <dc:subject><+$ category_name / $+></dc:subject> -->
			<content:encoded><![CDATA[ <+$ content / $+> ]]></content:encoded>
		</item><+@ / @+>
	</channel>
</rss>

-- 8< -- textfile: layout/comment_add_form.form -- >8 --

$form_name = 'addcomment';
$form_specification =
{
	author       => { name => 'Author (not empty)', minlength => 1, maxlength => 64,    match => '' },
	email        => { name => 'Email address'     , minlength => 0, maxlength => 256,   match => '' },
	email_public => { name => 'Publish email'     , minlength => 0, maxlength => 1,     match => '' },
	email_notify => { name => 'Email notification', minlength => 0, maxlength => 1,     match => '' },
	text         => { name => 'Text (not empty)'  , minlength => 1, maxlength => 65536, match => '' },
	id           => { name => 'ID (number)'       , minlength => 1, maxlength => 8,     match => '^\d+$' },
};

-- 8< -- textfile: layout/comment_add_form.template -- >8 --

<& formvalidator form="comment_add_form.form" / &>
<div class="blog form">
	<h1>Add comment</h1>
	<p><strong>Note:</strong> The email address is optional!</p>
	<form name="addcomment" action="" method="post" onsubmit="return validateForm(document.addcomment)">
		<input type="hidden" name="action" value="addcomment" />
		<input type="hidden" name="id"     value="<+$ id $+>0<+$ / $+>" />
		
		<label>Author:</label>
		<input name="author" maxlength="255" />
		<br />
		
		<label>Email:</label>
		<input name="email" maxlength="255" />
		<br />
		
		<label>Publish Email:</label>
		<input name="email_public" id="email_public" type="checkbox" class="checkbox" value="1" />
		<label for="email_public" style="width: 250px; height: 35px">Yes, publish my email-address (it will be obfuscated)</label>
		<br />
		
		<label>Notify on new comments:</label>
		<input name="email_notify" id="email_notify" type="checkbox" class="checkbox" value="1" checked="checked" />
		<label for="email_notify" style="width: 250px; height: 35px">Send me an email when someone writes a new comment.</label>
		<br />
		
		<label>Text:</label>
		<textarea name="text"></textarea>
		<br />
		
		<& captcha template="comment_add_form_captcha_js.template" / &>
		
		<label>&nbsp;</label>
		<input value="Add!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/comment_add_form_captcha.template -- >8 --

<label>Antispam:</label>
<div>
<p>Please type the text '<+$ answer / $+>' into this field:</p>
<input name="captcha_answer" />
<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />
</div>

-- 8< -- textfile: layout/comment_add_form_captcha_js.template -- >8 --

<script type="text/javascript">
<& perl &>
	#generate encrypted answer
	my $answer  = $template_values->{fields}->{answer};
	my $key     = $Konstrukt::Lib->random_password(8);
	my $enctext = $Konstrukt::Lib->uri_encode($Konstrukt::Lib->xor_encrypt("<input name=\"captcha_answer\" type=\"hidden\" class=\"xxl\" value=\"$answer\" />\n", $key), 1);
	print "\tvar enctext = \"$enctext\";\n";
	print "\tvar key = \"$key\";";
<& / &>
	function xor_enc(text, key) {
		var result = '';
		for(i = 0; i < text.length; i++)
			result += String.fromCharCode(key.charCodeAt(i % key.length) ^ text.charCodeAt(i));
		return result;
	}
	document.write(xor_enc(unescape(enctext), key));
</script>

<noscript>
	<label>Antispam:</label>
	<div>
	<p>Please type the text '<+$ answer / $+>' into this field:</p>
	<input name="captcha_answer" />
	</div>
</noscript>

<input name="captcha_hash" type="hidden" value="<+$ hash / $+>" />

-- 8< -- textfile: layout/comment_add_form_registered.template -- >8 --

<& formvalidator form="comment_add_form.form" / &>
<div class="blog form">
	<h1>Add comment:</h1>
	<p><strong>Note:</strong> The email address is optional!</p>
	<form name="addcomment" action="" method="post" onsubmit="return validateForm(document.addcomment)">
		<input type="hidden" name="action" value="addcomment" />
		<input type="hidden" name="id"     value="<+$ id $+>0<+$ / $+>" />
		
		<label>Author:</label>
		<input name="author" maxlength="255" value="<+$ author $+>(No name)<+$ / $+>" readonly="readonly" />
		<br />
		
		<label>Email:</label>
		<input name="email" maxlength="255" value="<+$ email $+><+$ / $+>" />
		<br />
		
		<label>Publish Email:</label>
		<input name="email_public" id="email_public" type="checkbox" class="checkbox" value="1" />
		<label for="email_public" style="width: 250px; height: 35px">Yes, publish my email-address (it will be obfuscated)</label>
		<br />
		
		<label>Notify on new comments:</label>
		<input name="email_notify" id="email_notify" type="checkbox" class="checkbox" value="1" checked="checked" />
		<label for="email_notify" style="width: 250px; height: 35px">Send me an email when someone writes a new comment.</label>
		<br />
		
		<label>Text:</label>
		<textarea name="text"></textarea>
		<br />
		
		<label>&nbsp;</label>
		<input type="submit" class="submit" value="Add!" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/comment_delete_form.form -- >8 --

$form_name = 'delcomment';
$form_specification =
{
	id => { name => 'ID' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/comments.template -- >8 --

<div class="blog comments">
	<h1>Comments</h1>
	
	<+@ comments @+>
	<table>
		<colgroup>
			<col width="100" />
			<col width="*"   />
		</colgroup>
		<tr>
			<th>Author:</th>
			<td><& mail::obfuscator name="<+$ author $+>(Kein Autor)<+$ / $+>" mail="<+$ email / $+>" / &></td>
		</tr>
		<tr>
			<th>Date:</th>
			<td><+$ year / $+>-<+$ month / $+>-<+$ day / $+> at <+$ hour / $+>:<+$ minute / $+>.</td>
		</tr>
		<tr>
			<th>Comment:</th>
			<td><+$ text $+>(No text)<+$ / $+></td>
		</tr>
		<& if condition="<+$ may_delete / $+>" &>
		<tr>
			<th>&nbsp;</th>
			<td><a href="?action=deletecomment;id=<+$ id $+>0<+$ / $+>">Delete comment</a></td>
		</tr>
		<& / &>
	</table>
	<+@ / @+>

</div>

-- 8< -- textfile: layout/comments_empty.template -- >8 --

<p>Currently no comments.</p>

-- 8< -- textfile: layout/entries_empty.template -- >8 --

<p>Currently no entries (for the current filter conditions).</p>

-- 8< -- textfile: layout/entries_nav.template -- >8 --

<& if condition="'<+$ prev_page $+>0<+$ / $+>'" &>
	<div style="float: left;">
		<a href="?page=<+$ prev_page $+>0<+$ / $+>">Newer entries</a>
	</div>
<& / &>

<& if condition="'<+$ next_page $+>0<+$ / $+>'" &>
	<div style="float: right;">
		<a href="?page=<+$ next_page $+>0<+$ / $+>">Older entries</a>
	</div>
<& / &>

<p class="clear" />

-- 8< -- textfile: layout/entry_add_form.form -- >8 --

$form_name = 'add';
$form_specification =
{
	title               => { name => 'Title (not empty)'  , minlength => 1, maxlength => 256,   match => '' },
	description         => { name => 'Summary (not empty)', minlength => 1, maxlength => 4096,  match => '' },
	content             => { name => 'Content (not empty)', minlength => 1, maxlength => 65536, match => '' },
	tags                => { name => 'Tags'               , minlength => 0, maxlength => 512,   match => '' },
	private             => { name => 'Private'            , minlength => 0, maxlength => 1,     match => '' },
	preview             => { name => 'Preview'            , minlength => 0, maxlength => 1,     match => '' },
	trackback_discovery => { name => 'Trackback discovery', minlength => 0, maxlength => 1,     match => '' },
	trackback_links     => { name => 'Trackback links'    , minlength => 0, maxlength => 65536, match => '^(\s*[hH][tT][tT][pP]\:\/\/\S+\s*)*$' },
};

-- 8< -- textfile: layout/entry_add_form.template -- >8 --

<& formvalidator form="entry_add_form.form" / &>
<div class="blog form">
	<h1>Add entry</h1>
	<form name="add" action="" method="post" onsubmit="return validateForm(document.add)">
		<input type="hidden" name="action" value="add" />
		
		<label>Title: (plain text)</label>
		<input name="title" maxlength="255" value="<+$ title / $+>" />
		<br />
		
		<label>Summary:<br />(plain text)</label>
		<textarea name="description"><+$ description / $+></textarea>
		<br />
		
		<label>Text:<br />(Wiki syntax)</label>
		<textarea name="content"><+$ content / $+></textarea>
		<br />
		
		<label>Tags:</label>
		<div>
	    	<input name="tags" id="tags" maxlength="512" value="<+$ tags / $+>" />
	    	<br />
	    	<p>Tags used so far:</p>
	    	<br />
	    	<& tags plugin="blog" /&>
    	</div>
    	<br />
    	
		<label>Private:</label>
		<div>
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" <& if condition="'<+$ private / $+>'" &>checked="checked"<& / &> />
		<label for="private" class="checkbox">This entry is only visible for me.<br />(Useful, if you want to revise the entry before you publish it.)</label>
		</div>
		<br />
		
		<label>Trackback autodiscovery:</label>
		<div>
		<input id="trackback_discovery" name="trackback_discovery" type="checkbox" class="checkbox" value="1" checked="checked" />
		<label for="trackback_discovery" class="checkbox">Try to automatically discover trackback links in the websites, that have been linked in the article.</label>
		</div>
		<br />

		<label>Trackback links:<br />(newline separated)</label>
		<textarea name="trackback_links"><+$ trackback_links / $+></textarea>
		<br />
		
		<label>Preview:</label>
		<input id="preview" name="preview" type="checkbox" class="checkbox" checked="checked" value="1" />
		<label for="preview" class="checkbox">Preview (don't save).</label>
		<br />
		
		<label>&nbsp;</label>
		<input value="Add!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_add_link.template -- >8 --

<p id="addlink">
<a href="?action=showadd">[ Create new entry ]</a>
</p>

-- 8< -- textfile: layout/entry_delete_form.form -- >8 --

$form_name = 'del';
$form_specification =
{
	id           => { name => 'ID (not empty)', minlength => 1, maxlength => 256, match => '^\d+$' },
	confirmation => { name => 'Confirmation'  , minlength => 0, maxlength => 1,   match => '1' },
};

-- 8< -- textfile: layout/entry_delete_form.template -- >8 --

<& formvalidator form="entry_delete_form.form" / &>
<div class="blog form">
	<h1>Confirmation: Delete article</h1>
	<p>Shall the article '<+$ title $+>(no title)<+$ / $+>' really be deleted?</p>
	
	<form name="del" action="" method="post" onsubmit="return validateForm(document.del)">
		<input type="hidden" name="action" value="delete" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<input id="confirmation" name="confirmation" type="checkbox" class="checkbox" value="1" />
		<label for="confirmation" class="checkbox">Yeah, kill it!</label>
		<br />
		
		<input value="Big red button" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_edit_form.form -- >8 --

$form_name = 'edit';
$form_specification =
{
	id                  => { name => 'ID (not empty)'     , minlength => 1, maxlength => 256,   match => '^\d+$' },
	title               => { name => 'Title (not empty)'  , minlength => 1, maxlength => 256,   match => '' },
	description         => { name => 'Summary (not empty)', minlength => 1, maxlength => 4096,  match => '' },
	content             => { name => 'Content (not empty)', minlength => 1, maxlength => 65536, match => '' },
	update_date         => { name => 'Update date'        , minlength => 0, maxlength => 1,     match => '' },
	tags                => { name => 'Tags'               , minlength => 0, maxlength => 512,   match => '' },
	private             => { name => 'Private'            , minlength => 0, maxlength => 1,     match => '' },
	preview             => { name => 'Preview'            , minlength => 0, maxlength => 1,     match => '' },
	trackback_discovery => { name => 'Trackback discovery', minlength => 0, maxlength => 1,     match => '' },
	trackback_links     => { name => 'Trackback links'    , minlength => 0, maxlength => 65536, match => '^(\s*[hH][tT][tT][pP]\:\/\/\S+\s*)*$' },
};

-- 8< -- textfile: layout/entry_edit_form.template -- >8 --

<& formvalidator form="entry_edit_form.form" / &>
<div class="blog form">
	<h1>Edit entry:</h1>
	<form name="edit" action="" method="post" onsubmit="return validateForm(document.edit)">
		<input type="hidden" name="action" value="edit" />
		<input type="hidden" name="id"     value="<+$ id $+>0<+$ / $+>" />
		
		<label>Title: (plain text)</label>
		<input name="title" maxlength="255" value="<+$ title / $+>" />
		<br />
		
		<label>Summary:<br />(plain text)</label>
		<textarea name="description"><+$ description / $+></textarea>
		<br />
		
		<label>Text:<br />(Wiki syntax)</label>
		<textarea name="content"><+$ content / $+></textarea>
		<br />
		
		<label>Tags:</label>
		<div>
	    	<input name="tags" id="tags" maxlength="512" value="<+$ tags / $+>" />
	    	<br />
	    	<p>Tags used so far:</p>
	    	<br />
	    	<& tags plugin="blog" /&>
    	</div>
    	<br />
		
		<label>Private:</label>
		<div style="width: 500px">
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" <& if condition="<+$ private $+>0<+$ / $+>" &>checked="checked"<& / &> />
		<label for="private" class="checkbox">This entry is only visible for me.<br />(Useful, if you want to revise the entry before you publish it.)</label>
		</div>
		<br />
		
		<label>Update publication date:</label>
		<input id="update_date" name="update_date" type="checkbox" class="checkbox" value="1" />
		<label for="update_date" class="checkbox">Set the publication date of this entry to now.</label>
		<br />

		<label>Trackback autodiscovery:</label>
		<div>
		<input id="trackback_discovery" name="trackback_discovery" type="checkbox" class="checkbox" value="1" checked="checked" />
		<label for="trackback_discovery" class="checkbox">Try to automatically discover trackback links in the websites, that have been linked in the article.</label>
		</div>
		<br />
		
		<label>Trackback links:<br />(newline separated)</label>
		<textarea name="trackback_links"><+$ trackback_links / $+></textarea>
		<br />
		
		<label>Preview:</label>
		<input id="preview" name="preview" type="checkbox" class="checkbox" value="1" />
		<label for="preview" class="checkbox">Preview (don't save).</label>
		<br />
		
		<label>&nbsp;</label>
		<input value="Update!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_full.template -- >8 --

<div class="blog entry">
	<!--
	<rdf:RDF
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/">
	<rdf:Description
		rdf:about="http://<& env var="HTTP_HOST" / &>/blog/?action=show;id=<+$ id $+>0<+$ / $+>"
		dc:identifier="http://<& env var="HTTP_HOST" / &>/blog/?action=show;id=<+$ id $+>0<+$ / $+>"
		dc:title="<+$ title $+>(No title)<+$ / $+>"
		trackback:ping="http://<& env var="HTTP_HOST" / &>/blog/trackback/?id=<+$ id $+>0<+$ / $+>" />
	</rdf:RDF>
	-->
	
	<h1>
		<a href="/blog/?action=show;id=<+$ id $+>0<+$ / $+>"><+$ title $+>(No title)<+$ / $+></a>
		<& if condition="<+$ private $+>0<+$ / $+>" &>(private)<& / &>
		<& if condition="<+$ may_edit $+>0<+$ / $+>" &><a href="?action=showedit;id=<+$ id $+>0<+$ / $+>">[ edit ]</a><& / &>
		<& if condition="<+$ may_delete $+>0<+$ / $+>" &><a href="?action=showdelete;id=<+$ id $+>0<+$ / $+>">[ delete ]</a><& / &>
	</h1>
	<div class="description"><p><+$ description $+>(No summary)<+$ / $+></p></div>
	<div class="content"><+$ content $+>(No content)<+$ / $+></div>
	<div class="foot">
		Written on <+$ year / $+>-<+$ month / $+>-<+$ day / $+> at <+$ hour / $+>:<+$ minute / $+> by <+$ author $+>(unknown author)<+$ / $+> (author id: <+$ author_id $+>0<+$ / $+>).<br />
		<& perl &>
			my @tags = @{$template_values->{lists}->{tags}};
			if (@tags) {
				print "Tag" . (@tags > 1 ? 's' : '') . ": ";
				print join ", ", (map { "<a href=\"?action=filter;tags=" . $Konstrukt::Lib->uri_encode($_->{fields}->{title}) . "\" rel=\"tag\">$_->{fields}->{title}</a>" } @tags);
				print ".<br />"
			};
		<& / &>
		<a href="?action=show;id=<+$ id $+>0<+$ / $+>#comments">Comments: <+$ comment_count $+>(none yet)<+$ / $+></a> -
		<a href="?action=show;id=<+$ id $+>0<+$ / $+>#trackbacks">Trackbacks: <+$ trackback_count $+>(none yet)<+$ / $+></a> -
		<a href="http://<& env var="HTTP_HOST" / &>/blog/trackback/?id=<+$ id $+>0<+$ / $+>" rel="trackback">Trackback link</a>.
	</div>
</div> 

-- 8< -- textfile: layout/entry_short.template -- >8 --

<div class="blog entry">
	<!--
	<rdf:RDF
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" 
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:trackback="http://madskills.com/public/xml/rss/module/trackback/">
	<rdf:Description
		rdf:about="http://<& env var="HTTP_HOST" / &>/blog/?action=show;id=<+$ id $+>0<+$ / $+>"
		dc:identifier="http://<& env var="HTTP_HOST" / &>/blog/?action=show;id=<+$ id $+>0<+$ / $+>"
		dc:title="<+$ title $+>(No title)<+$ / $+>"
		trackback:ping="http://<& env var="HTTP_HOST" / &>/blog/trackback/?id=<+$ id $+>0<+$ / $+>" />
	</rdf:RDF>
	-->
	
	<h1>
		<a href="/blog/?action=show;id=<+$ id $+>0<+$ / $+>"><+$ title $+>(No title)<+$ / $+></a>
		<& if condition="<+$ private $+>0<+$ / $+>" &>(private)<& / &>
		<& if condition="<+$ may_edit $+>0<+$ / $+>" &><a href="?action=showedit;id=<+$ id $+>0<+$ / $+>">[ edit ]</a><& / &>
		<& if condition="<+$ may_delete $+>0<+$ / $+>" &><a href="?action=showdelete;id=<+$ id $+>0<+$ / $+>">[ delete ]</a><& / &>
	</h1>
	<div class="description"><p><+$ description $+>(No summary)<+$ / $+></p></div>
	<div class="content"><+$ content $+>(No content)<+$ / $+></div>
	<div class="foot">
		Written on <+$ year / $+>-<+$ month / $+>-<+$ day / $+> at <+$ hour / $+>:<+$ minute / $+> by <+$ author $+>(unknown author)<+$ / $+> (author id: <+$ author_id $+>0<+$ / $+>).<br />
		<& perl &>
			my @tags = @{$template_values->{lists}->{tags}};
			if (@tags) {
				print "Tag" . (@tags > 1 ? 's' : '') . ": ";
				print join ", ", (map { "<a href=\"?action=filter;tags=" . $Konstrukt::Lib->uri_encode($_->{fields}->{title}) . "\" rel=\"tag\">$_->{fields}->{title}</a>" } @tags);
				print ".<br />"
			};
		<& / &>
		<a href="?action=show;id=<+$ id $+>0<+$ / $+>#comments">Comments: <+$ comment_count $+>(none yet)<+$ / $+></a> -
		<a href="?action=show;id=<+$ id $+>0<+$ / $+>#trackbacks">Trackbacks: <+$ trackback_count $+>(none yet)<+$ / $+></a> -
		<a href="http://<& env var="HTTP_HOST" / &>/blog/trackback/?id=<+$ id $+>0<+$ / $+>" rel="trackback">Trackback link</a>.
	</div>
</div>

-- 8< -- textfile: layout/entry_preview.template -- >8 --

<div class="blog entry">
	<h1><+$ title $+>(No title)<+$ / $+> (Preview)</h1>
	<div class="description"><p><+$ description $+>(No summary)<+$ / $+></p></div>
	<div class="content"><+$ content $+>(No content)<+$ / $+></div>
</div> 

-- 8< -- textfile: layout/entry_show.form -- >8 --

$form_name = 'show';
$form_specification =
{
	id => { name => 'ID (not empty)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/filter_form.template -- >8 --

<script type="text/javascript">
<!--
function submitFilter () {
	if (document.filter.text.value == 'Search text...') {
		document.filter.text.value = '';
	}
	return true;
}
function showFilter () {
	document.getElementById("filterlink").style.display = 'none';
	document.getElementById("filterbox").style.display  = 'block';
}
function hideFilter () {
	document.getElementById("filterlink").style.display = 'block';
	document.getElementById("filterbox").style.display  = 'none';
}
-->
</script>
<div id="filterbox" style="display: none;">
	<div class="blog form">
		<h1>Find entry</h1>
		<form name="filter" action="" method="post" onsubmit="return submitFilter()">
			<input type="hidden" name="action" value="filter" />
			
			<label>Tags: (<a href="#" onclick="if (document.getElementById('tagexplain').style.display == 'block') { document.getElementById('tagexplain').style.display = 'none' } else { document.getElementById('tagexplain').style.display = 'block' }">Help</a>)</label>
			<input name="tags" id="tags" value="<& param var="tags" &><& / &>" />
			<br />
			<label>&nbsp;</label>
			<div>
			<& tags plugin="blog" / &>
			<div id="tagexplain" style="width: 500px; display: none;">
				<h2>Description of the tag filter:</h2>
				<p>Multiple tags, which the entry you're looking for must have (AND combination), have to be separated by whitespaces.</p>
				<p>Tags, which contain whitespaces themselves, have to be quoted using doublequotes.</p>
				<p>If you want to define a set of tags of which only at least one has to exist for that entry (OR combination), you have to enclose the tags in curly braces.</p>
				<h2>Example:</h2>
				<p><em>tag1 tag2 tag3 "tag with whitespaces" {tag4 tag5 tag6} {tag7 tag8 tag9}</em></p>
				<h2>Explanation:</h2>
				<p>Only those entries will be selected, that have the tags "tag1", "tag2", "tag3" and "tag with whitespaces" as well as at least one tag of the first and at least one of the second set.</p>
			</div>
			</div>
			<br />
			
			<label>Author:</label>
			<select name="author" size="1">
				<option value="-1">Autor:</option>
				<& perl &>
					foreach my $item (@{$template_values->{lists}->{authors}}) {
						my $id   = defined $item->{fields}->{id}   ? $item->{fields}->{id} + 0 : 0;
						my $name = defined $item->{fields}->{name} ? $item->{fields}->{name}   : '(No name)';
						my $author = $Konstrukt::CGI->param('author');
						{
							no warnings;
							$author += 0 if defined $author; #force numeric context
						}
						print "\t\t<option value=\"$id\"" . (defined $author and $id == $author ? " selected=\"selected\"" : "") . ">$name</option>\n";
					}
				<& / &>
			</select>
			<br />
			
			<label>Date:</label>
			<select name="year" size="1" class="s">
				<option value="-1">Year:</option>
				<& perl &>
					my $year_now = (localtime(time))[5] + 1900;
					my $year     = $Konstrukt::CGI->param('year');
					{
						no warnings; 
						$year += 0 if defined $year; #force numeric context
					}
					for (0 .. 4) {
						print "\t\t<option value=\"" . ($year_now - $_) . "\"" . (defined $year and $year == $year_now - $_ ? " selected=\"selected\"" : "") . ">" . ($year_now - $_) . "</option>\n";
					}
				<& / &>
			</select>
			<select name="month" size="1" class="s">
				<option value="-1">Month:</option>
				<& perl &>
					my @month_name = qw/January February March April May June July August September October November December/;
					my $month = $Konstrukt::CGI->param('month') + 0;
					{
						no warnings; 
						$month += 0 if defined $month; #force numeric context
					}
					for (1 .. 12) {
						print "\t\t<option value=\"$_\"" . (defined $month and $month == $_ ? " selected=\"selected\"" : "") . ">$month_name[$_-1]</option>\n";
					}
				<& / &>
			</select>
			<br />
		
			<label>Text:</label>
			<input name="text" value="<& param var="text" &><& / &>" />
			<br />
			
			<label>&nbsp;</label>
			<input type="submit" class="submit" value="Filter!" />
			<br />
		</form>
		
		<a href="#" onclick="hideFilter();">(hide)</a>
	</div>
</div>

<p id="filterlink">
<a href="#" onclick="showFilter();">[ Find entry ]</a>
</p>

-- 8< -- textfile: layout/trackback_delete_form.form -- >8 --

$form_name = 'deltrackback';
$form_specification =
{
	id => { name => 'ID' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/trackbacks.template -- >8 --

<div class="blog trackbacks">
	<h1>Trackbacks</h1>
	
	<+@ trackbacks @+>
	<table>
		<colgroup>
			<col width="100" />
			<col width="*"   />
		</colgroup>
		<tr>
			<th>Source:</th>
			<td><a href="<+$ url / $+>"><+$ title $+><+$ url / $+><+$ / $+></a></td>
		</tr>
		<tr>
			<th>Date:</th>
			<td><+$ year / $+>-<+$ month / $+>-<+$ day / $+> at <+$ hour / $+>:<+$ minute / $+>.</td>
		</tr>
		<tr>
			<th>Summary:</th>
			<td><+$ excerpt $+>(No text)<+$ / $+></td>
		</tr>
		<& if condition="<+$ may_delete / $+>" &>
		<tr>
			<th>&nbsp;</th>
			<td><a href="?action=deletetrackback;id=<+$ id $+>0<+$ / $+>">Delete trackback</a></td>
		</tr>
		<& / &>
	</table>
	<+@ / @+>

</div>

-- 8< -- textfile: layout/trackbacks_empty.template -- >8 --

<p>Currently no trackbacks.</p>

-- 8< -- textfile: messages/comment_add_failed.template -- >8 --

<div class="blog message failure">
	<h1>Comment not added</h1>
	<p>An internal error occurred while adding your comment</p>
</div>

-- 8< -- textfile: messages/comment_add_failed_captcha.template -- >8 --

<div class="blog message failure">
	<h1>Comment not added</h1>
	<p>The comment could not be added, as the antispam question has not been answered (correctly)!</p>
</div>

-- 8< -- textfile: messages/comment_add_successful.template -- >8 --

<div class="blog message success">
	<h1>Comment added</h1>
	<p>Your comment has been added successfully!</p>
</div>

-- 8< -- textfile: messages/comment_delete_failed.template -- >8 --

<div class="blog message failure">
	<h1>Comment not deleted</h1>
	<p>An internal error occurred while deleting the comment.</p>
</div>

-- 8< -- textfile: messages/comment_delete_failed_permission_denied.template -- >8 --

<div class="blog message failure">
	<h1>Comment not deleted</h1>
	<p>The comment hasn't been deleted, because it can only be deleted by an administator</p>
</div>

-- 8< -- textfile: messages/comment_delete_successful.template -- >8 --

<div class="blog message success">
	<h1>Comment deleted</h1>
	<p>The comment has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/comment_email_notification.email -- >8 --

$mail = {
	subject => 'New comment on topic: $topic$',
	body    =>
'$author$ wrote a new comment on the topic "$topic$".

You can read it at $url$.',
}

-- 8< -- textfile: messages/entry_add_failed.template -- >8 --

<div class="blog message failure">
	<h1>Entry not added</h1>
	<p>An internal error occurred while adding this entry.</p>
</div>

-- 8< -- textfile: messages/entry_add_successful.template -- >8 --

<div class="blog message success">
	<h1>Entry added</h1>
	<p>The entry has been added successfully!</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed.template -- >8 --

<div class="blog message failure">
	<h1>Entry not deleted</h1>
	<p>An internal error occurred while deleting the entry.</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed_permission_denied.template -- >8 --

<div class="blog message failure">
	<h1>Entry not deleted</h1>
	<p>The entry could not be deleted, because it can only be deleted by an administrator!</p>
</div>

-- 8< -- textfile: messages/entry_delete_successful.template -- >8 --

<div class="blog message success">
	<h1>Entry deleted</h1>
	<p>The entry has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed.template -- >8 --

<div class="blog message failure">
	<h1>Entry not updated</h1>
	<p>An internal error occurred while updating the entry.</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed_permission_denied.template -- >8 --

<div class="blog message failure">
	<h1>Entry not updated</h1>
	<p>The entry has not been updated, because it can only be updated by its author or an administrator!</p>
</div>

-- 8< -- textfile: messages/entry_edit_successful.template -- >8 --

<div class="blog message success">
	<h1>Entry updated</h1>
	<p>The entry has been updated successfully</p>
</div>

-- 8< -- textfile: messages/entry_show_failed_not_exists.template -- >8 --

<div class="blog message failure">
	<h1>Entry does not exist</h1>
	<p>The requested entry does not exist!</p>
</div>

-- 8< -- textfile: messages/trackback_ping_failed.template -- >8 --

<div class="blog message failure">
	<h1>Trackback ping failed</h1>
	<p>The ping of the URL <+$ url $+>(no url)<+$ / $+> failed.</p>
	<p>Reason: <+$ message $+>(unknown)<+$ / $+>.</p>
</div>

-- 8< -- textfile: messages/trackback_ping_successful.template -- >8 --

<div class="blog message success">
	<h1>Trackback ping successful</h1>
	<p>The trackback URL <+$ url $+>(no url)<+$ / $+> has been pinged successfully.</p>
</div>

-- 8< -- textfile: messages/trackback_discover_failed.template -- >8 --

<div class="blog message failure">
	<h1>Trackback discovery failed</h1>
	<p>The trackback discovery for the URL <+$ url $+>(no url)<+$ / $+> failed.</p>
	<p>Reason: <+$ message $+>(unknown)<+$ / $+>.</p>
</div>

-- 8< -- textfile: messages/trackback_delete_failed.template -- >8 --

<div class="blog message failure">
	<h1>Trackback not deleted</h1>
	<p>An internal error occurred while deleting the trackback.</p>
</div>

-- 8< -- textfile: messages/trackback_delete_failed_permission_denied.template -- >8 --

<div class="blog message failure">
	<h1>Trackback not deleted</h1>
	<p>The trackback hasn't been deleted, because it can only be deleted by an administator</p>
</div>

-- 8< -- textfile: messages/trackback_delete_successful.template -- >8 --

<div class="blog message success">
	<h1>Trackback deleted</h1>
	<p>The trackback has been deleted successfully!</p>
</div>

-- 8< -- textfile: /blog/rss2/index.html -- >8 --

<& blog show="rss2" / &>

-- 8< -- textfile: /blog/trackback/index.html -- >8 --

<& blog show="trackback" / &>

-- 8< -- binaryfile: /images/blog/rss2.gif -- >8 --

R0lGODlhMgAPALMAAGZmZv9mAP///4mOeQAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
AAAAACwAAAAAMgAPAAAEexDISau9OFvBu/9gKI6dJARoqq4sKgxwLM/0IJhtnr91T9+Ak26Y4vmO
NpyLo+oUmUVZ52eUKgPC7Eq4rVV5VRiQ63w2ua4ZRy3+XU9o17Yp9bbVbzkWuo9/p0ZrbkFEhWFI
g3GFLIeIVoSLOo2OYiYkl5iZQBqcnZ4TEQA7

-- 8< -- textfile: /styles/blog.css -- >8 --

/* CSS definitions for the Konstrukt blog plugin */

div.blog h1 {
	margin-top: 0;
}

div.blog.entry {
	background-color: #eef0f2;
	padding: 15px;
	border: 1px solid #3b8bc8;
	margin: 20px 0 20px 0;
}

div.blog.entry div.description {
	font-style: italic;
}

div.blog.entry div.content {
	margin-top: 10px;
}

div.blog.entry div.foot {
}

img.blog_icon {
	vertical-align: middle;
}
