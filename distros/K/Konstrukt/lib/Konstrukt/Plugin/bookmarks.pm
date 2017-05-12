#TODO: allow users to delete their own category, when all links in this category have been created by this user
#FEATURE: limit depth of category recursion
#FEATURE: category only mode
#FEATURE: display as list (odered by title, visits, last visit, ...)
#FEATURE: move entries between categories
#FEATURE: export to firefox .html bookmarks

=head1 NAME

Konstrukt::Plugin::bookmarks - Bookmark management for registered users

=head1 SYNOPSIS
	
You may simply integrate it by putting
		
		<& bookmarks / &>
		
somewhere in your website.
	
=head1 DESCRIPTION

This Konstrukt Plug-In provides bookmark-facilities for your website.

You may simply integrate it by putting
	
	<& bookmarks / &>
	
somewhere in your website.

To be able to reference the stored bookmarks as links, which will update the
visit counters and last visit timestamps and redirect to the URL stored in
the bookmark create an empty redirect.ihtml (or any othername) with this content:
	
	<& bookmarks show="visit" / &>
	
Then reference the bookmark like this:
	
	<a href="redirect.ihtml?id=<bookmark-id>">Bookmark-Title</a>

=head1 CONFIGURATION
	
You may do some configuration in your konstrukt.settings to let the
plugin know where to get its data and which layout to use. Default:

	#backend
	bookmarks/backend            DBI

See the documentation of the backend modules
(e.g. L<Konstrukt::Plugin::bookmarks::DBI/CONFIGURATION>) for their configuration.

	#layout
	bookmarks/template_path      /templates/bookmarks/
	bookmarks/root_title         Links
	#user levels
	bookmarks/userlevel_write    2
	bookmarks/userlevel_admin    3

=cut

package Konstrukt::Plugin::bookmarks;

use strict;
use warnings;

use base 'Konstrukt::Plugin'; #inheritance
use Konstrukt::Plugin; #import use_plugin

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

Initializes this object. Sets $self->{backend} and $self->{template_path}layout/.
init will be called by the constructor.

=cut
sub init {
	my ($self) = @_;
	
	#dependencies
	$self->{user_basic}    = use_plugin 'usermanagement::basic'    or return undef;
	$self->{user_level}    = use_plugin 'usermanagement::level'    or return undef;
	$self->{user_personal} = use_plugin 'usermanagement::personal' or return undef;

	#set default settings
	$Konstrukt::Settings->default("bookmarks/backend"         => 'DBI');
	$Konstrukt::Settings->default("bookmarks/template_path"   => '/templates/bookmarks/');
	$Konstrukt::Settings->default("bookmarks/userlevel_write" => 2);
	$Konstrukt::Settings->default("bookmarks/userlevel_admin" => 3);
	$Konstrukt::Settings->default("bookmarks/root_title"      => 'Links');

	$self->{backend} = use_plugin "bookmarks::" . $Konstrukt::Settings->get("bookmarks/backend") or return undef;
	$self->{template_path} = $Konstrukt::Settings->get('bookmarks/template_path');
	
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

We cannot prepare anything as the input data may be different on each
request. The result is completely dynamic.

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
	
	my $show  = $tag->{tag}->{attributes}->{show} || '';
	
	if ($show eq 'visit') {
		$self->visit();
	} else {
		my $action = $Konstrukt::CGI->param('action') || '';
		
		#user logged in?
		if ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_write')) {
			#operations that are accessible to "bookmarkers"
			if ($action eq 'addentryshow') {
				$self->add_entry_show();
			} elsif ($action eq 'addentry') {
				$self->add_entry();
			} elsif ($action eq 'editentryshow') {
				$self->edit_entry_show();
			} elsif ($action eq 'editentry') {
				$self->edit_entry();
			} elsif ($action eq 'delentryshow') {
				$self->delete_entry_show();
			} elsif ($action eq 'delentry') {
				$self->delete_entry();
			} elsif ($action eq 'addcatshow') {
				$self->add_category_show();
			} elsif ($action eq 'addcat') {
				$self->add_category();
			} elsif ($action eq 'editcatshow') {
				$self->edit_category_show();
			} elsif ($action eq 'editcat') {
				$self->edit_category();
			} elsif ($action eq 'delcatshow') {
				$self->delete_category_show();
			} elsif ($action eq 'delcat') {
				$self->delete_category();
			} elsif ($action eq 'showentry') {
				$self->show_entry();
			} else {
				$self->show_entries();
			}
		} else {
			#operatiosn that are accessible to all visitors
			if ($action eq 'showentry') {
				$self->show_entry();
			} else {
				$self->show_entries();
			}
		}
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 add_entry_show

Displays the form to add a bookmark.

=cut
sub add_entry_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_add_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $cat      = $self->{backend}->get_category($form->get_value('id'));
		$self->add_node($template->node("$self->{template_path}layout/entry_add_show.template", { category_id => $cat->{id}, category_title => $cat->{title} }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_entry_show

=head2 add_entry

Takes the HTTP form input and adds a new bookmark entry.

Diesplays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_add.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		
		my $cat      = $form->get_value('category');
		my $url      = $form->get_value('url');
		my $title    = $form->get_value('title');
		my $private  = $form->get_value('private');
		my $author   = $self->{user_basic}->id();
		if ($self->{backend}->add_entry($cat, $url, $title, $private, $author)) {
			#success
			$self->add_node($template->node("$self->{template_path}messages/entry_add_successful.template"));
		} else {
			#failed
			$self->add_node($template->node("$self->{template_path}messages/entry_add_failed.template"));
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_entry

=head2 edit_entry_show

Displays the form to edit a bookmark.

=cut
sub edit_entry_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_edit_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $entry = $self->{backend}->get_entry($form->get_value('id'));
		my $may_edit = ($entry->{author} == $self->{user_basic}->id());
		my $may_delete = ($may_edit or $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin'));
		if (!$entry->{private} or ($entry->{private} and $may_edit)) {
			my $template = use_plugin 'template';
			$entry->{url}   = $Konstrukt::Lib->html_escape($entry->{url});
			$entry->{title} = $Konstrukt::Lib->html_escape($entry->{title});
			my @categories = $self->get_flat_category_list();
			map { $_->{title} = "*" x $_->{depth} . " " . $Konstrukt::Lib->html_escape($_->{title}); $_->{current} = 1 if $_->{id} == $entry->{category} } @categories;
			$self->add_node($template->node("$self->{template_path}layout/entry_edit_show.template", { id => $entry->{id}, title => $entry->{title}, url => $entry->{url}, private => $entry->{private}, categories => [ map { { fields => $_ } } @categories ] }));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_entry_show

=head2 get_flat_category_list

Flattens the tree of categories into an array of references to the category:

	(
		{
			id      => ..,
			title   => ..,
			author  => ..,
			private => ..,
			depth   => ..,
			categories => [ ... ],
			bookmarks => [ ... ]
		},
		{ ... },
		...
	)

B<Parameters>:

=over

=item * $id - The id of the catetegory whose sub-categories should be flattened. (optional)

=item * $depth - The current depth. (optional)

=back

=cut
sub get_flat_category_list {
	my ($self, $id, $depth) = @_;
	
	$id ||= 0;
	$depth ||= 0;
	
	my @result;
	my $category = $self->{backend}->get_entries($id, $self->{user_basic}->id());
	my @subcats = @{$category->{categories}};
	$category->{depth} = $depth;
	push @result, $category;
	foreach my $subcat (@subcats) {;
		push @result, $self->get_flat_category_list($subcat->{id}, $depth + 1);
	}
	
	return @result;
}
#= /get_flat_category_list

=head2 edit_entry

Takes the HTTP form input and updates the requested bookmark.

Displays a confirmation of the successful update or error messages otherwise.

=cut
sub edit_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_edit.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		
		my $id       = $form->get_value('id');
		my $url      = $form->get_value('url');
		my $title    = $form->get_value('title');
		my $private  = $form->get_value('private');
		my $category = $form->get_value('category');
		my $entry    = $self->{backend}->get_entry($id);
		if ($entry->{author} == $self->{user_basic}->id()) {
			if ($self->{backend}->update_entry($id, $url, $title, $private, $category)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/entry_edit_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/entry_edit_failed_permission_denied.template"));
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_entry

=head2 delete_entry_show

Displays the confirmation form to delete an entry.

=cut
sub delete_entry_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_delete_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $entry = $self->{backend}->get_entry($form->get_value('id'));
		$entry->{url}   = $Konstrukt::Lib->html_escape($entry->{url});
		$entry->{title} = $Konstrukt::Lib->html_escape($entry->{title});
		$self->add_node($template->node("$self->{template_path}layout/entry_delete_show.template", { id => $entry->{id}, title => $entry->{title}, url => $entry->{url} }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_entry_show

=head2 delete_entry

Deletes the specified entry.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_entry {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/entry_delete.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $id       = $form->get_value('id');
		my $entry    = $self->{backend}->get_entry($id);
		if ($entry->{author} == $self->{user_basic}->id() or $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin')) {
			if ($id and $self->{backend}->delete_entry($id)) {
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

Shows the requested bookmark.

B<Parameters>:

=over

=item * $id - ID of the bookmark to show (optional)

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
		my $template = use_plugin 'template';
		my $entry    = $self->{backend}->get_entry($id);
		
		#collect category path to this bookmark
		my $category = $entry->{category};
		my @categories;
		while ($category >= 0) {
			my $new_category = $self->{backend}->get_category($category);
			unshift @categories, $new_category;
			#halt when the root element is found
			$category = ($new_category->{id} == 0 ? -1 : $new_category->{parent});
		}
		
		#put out bookmark info
		my $may_edit   = ($entry->{author} == $self->{user_basic}->id());
		my $may_delete = ($may_edit or $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin'));
		if (!$entry->{private} or ($entry->{private} and $may_edit)) {
			my $author = $self->{user_personal}->data($entry->{author})->{nick};
			my $data = { 
				fields => {
					id         => $entry->{id},
					title      => $Konstrukt::Lib->html_escape($entry->{title}),
					url        => $Konstrukt::Lib->html_escape($entry->{url}),
					author     => $author,
					author_id  => $entry->{author},
					private    => $entry->{private},
					visits     => $entry->{visits},
					year       => $entry->{year},
					month      => sprintf("%02d", $entry->{month}),
					day        => sprintf("%02d", $entry->{day}),
					hour       => sprintf("%02d", $entry->{hour}),
					minute     => sprintf("%02d", $entry->{minute}),
					may_edit   => $may_edit,
					may_delete => $may_delete,
				},
				lists => {
					categories => [ map { { fields => { id => $_->{id}, title => $_->{title} } } } @categories ]
				}
			};
			$self->add_node($template->node("$self->{template_path}layout/entry_show.template", $data));
		}
	}
}
#= /show_entry

=head2 show_entries

Shows the categories and bookmarks.

B<Parameters>:

=over

=item * $category - The category whose entries should be displayed

=back

=cut
sub show_entries {
	my ($self, $id) = @_;
	
	my $template = use_plugin 'template';
	
	$id ||= $Konstrukt::CGI->param('cat') || 0;
	
	#cache some user info:
	my $user_id         = $self->{user_basic}->id();
	my $user_level      = $self->{user_level}->level();
	my $userlevel_admin = $Konstrukt::Settings->get('bookmarks/userlevel_admin');
	my $userlevel_write = $Konstrukt::Settings->get('bookmarks/userlevel_write');
	
	$self->add_node(
		$self->show_entries_collect_data($id, $user_id, $user_level, $user_level >= $userlevel_write, $user_level >= $userlevel_admin)
	);
}
#= /show_entries

=head2 show_entries_collect_data

Recursively generates the tree of categories and bookmarks.

Returns a Konstrukt node that will display the tree.

Only used internally by L</show_entries>.

B<Parameters>:

=over

=item * $id = The id if the category that should be handled

=item * $user_id = The id of the user currently logged in

=item * $user_level = The user level of the user currently logged in

=item * $user_write = True, if the current user may create new entries

=item * $user_admin = True, if the current user is an admin

=item * $tree = Tree symbol of this category. Passed from the parent entry.

=back

=cut
sub show_entries_collect_data {
	my ($self, $id, $user_id, $user_level, $user_write, $user_admin, $tree) = @_;
	
	my $template = use_plugin 'template';
	my $parent = $self->{backend}->get_entries($id, $user_id);
	
	#mark last node
	if (@{$parent->{categories}}) {
		if (@{$parent->{bookmarks}}) {
			$parent->{bookmarks}->[-1]->{last_one} = 1;
		} else {
			$parent->{categories}->[-1]->{last_one} = 1;
		}
	} elsif (@{$parent->{bookmarks}}) {
		$parent->{bookmarks}->[-1]->{last_one} = 1;
	}
	
	#get all entries into a list
	#each item has some tree symbols in front of it:
	#0 = no symbol      (   )
	#1 = pipe           ( | )
	#2 = left turned T  ( T )
	#3 = L              ( L )
	
	#data for the generated template
	my $data = {
		fields => {
			id         => $parent->{id},
			title      => $Konstrukt::Lib->html_escape($parent->{title}),
			author     => $parent->{author},
			private    => $parent->{private},
			may_edit   => ($parent->{id} > 0 and ($parent->{author} == $user_id or $user_admin) ? 1 : 0),
			may_delete => ($parent->{id} > 0 and $user_admin ? 1 : 0),
			may_write  => ($user_write ? 1 : 0),
			tree       => ($tree || 0),
		},
		lists => {
			categories => [ map { { fields => {
				category   => $self->show_entries_collect_data($_->{id}, $user_id, $user_level, $user_write, $user_admin, (exists $_->{last_one} ? 3 : 2)),
				tree       => (exists $_->{last_one} ? 3 : 2),
			} } } @{$parent->{categories}} ],
			bookmarks => [ map { { fields => {
				id       => $_->{id},
				title    => $Konstrukt::Lib->html_escape($_->{title}),
				url      => $_->{url},
				author   => $_->{author},
				private  => $_->{private},
				tree     => (exists $_->{last_one} ? 3 : 2),
				may_edit => ($_->{author} == $user_id or $user_admin ? 1 : 0),
			} } } @{$parent->{bookmarks}} ]
		}
	};
	
	#return node
	return $template->node("$self->{template_path}layout/tree_category.template", $data);
}
#= /show_entries_collect_data

=head2 add_category_show

Displays the form to add a category.

=cut
sub add_category_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_add_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $parent_id = $form->get_value('id');
		my $parent_title;
		$parent_title = $self->{backend}->get_category($parent_id)->{title};
		$self->add_node($template->node("$self->{template_path}layout/category_add_show.template", { parent_id => $parent_id, parent_title => $parent_title }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_category_show

=head2 add_category

Takes the HTTP form input and adds a new bookmark category.

Displays a confirmation of the successful addition or error messages otherwise.

=cut
sub add_category {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_add.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template  = use_plugin 'template';
		
		my $parent_id = $form->get_value('parent_id');
		my $title     = $form->get_value('title');
		my $private   = $form->get_value('private') || 0;
		my $author    = $self->{user_basic}->id();
		if ($self->{backend}->add_category($parent_id, $title, $author, $private)) {
			#success
			$self->add_node($template->node("$self->{template_path}messages/category_add_successful.template"));
			
		} else {
			#failed
			$self->add_node($template->node("$self->{template_path}messages/category_add_failed.template"));
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /add_category

=head2 edit_category_show

Displays the form to edit a category.

=cut
sub edit_category_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_edit_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $id = $form->get_value('id') || 0;
		if ($id > 0) {
			my $category = $self->{backend}->get_category($form->get_value('id'));
			my $may_edit = ($category->{author} == $self->{user_basic}->id());
			my $may_delete = ($may_edit or $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin'));
			if (!$category->{private} or ($category->{private} and $may_edit)) {
				my $template = use_plugin 'template';
				$category->{title} = $Konstrukt::Lib->html_escape($category->{title});
				my @categories = grep { $_->{id} != $id } $self->get_flat_category_list();
				map { $_->{title} = "*" x $_->{depth} . " " . $Konstrukt::Lib->html_escape($_->{title}); $_->{current} = 1 if $_->{id} == $category->{parent} } @categories;
				$self->add_node($template->node("$self->{template_path}layout/category_edit_show.template", { id => $category->{id}, title => $category->{title}, private => $category->{private}, categories => [ map { { fields => $_ } } @categories ] }));
			}
		} else {
			$Konstrukt::Debug->error_message("Cannot edit root category!") if Konstrukt::Debug::ERROR;
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_category_show

=head2 edit_category

Takes the HTTP form input and updates an existing bookmark category.

Displays a confirmation of the successful update or error messages otherwise.

=cut
sub edit_category {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_edit.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		
		my $id       = $form->get_value('id') || 0;
		my $title    = $form->get_value('title') || '';
		my $private  = $form->get_value('private') || 0;
		my $parent   = $form->get_value('category') || 0;
		
		if ($id > 0) {
			my $category = $self->{backend}->get_category($id);
			if ($category->{author} == $self->{user_basic}->id() or $self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin')) {
				if ($self->{backend}->update_category($id, $title, $private, $parent)) {
					#success
					$self->add_node($template->node("$self->{template_path}messages/category_edit_successful.template"));
				} else {
					#failed
					$self->add_node($template->node("$self->{template_path}messages/category_edit_failed.template"));
				}
			} else {
				#permission denied
				$self->add_node($template->node("$self->{template_path}messages/category_edit_failed_permission_denied.template"));
			}
		} else {
			$Konstrukt::Debug->error_message("Cannot edit root category!") if Konstrukt::Debug::ERROR;
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /edit_category

=head2 delete_category_show

Displays the confirmation form to delete a category.

=cut
sub delete_category_show {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_delete_show.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $cat = $self->{backend}->get_category($form->get_value('id'));
		$cat->{title} = $Konstrukt::Lib->html_escape($cat->{title});
		$self->add_node($template->node("$self->{template_path}layout/category_delete_show.template", { id => $cat->{id}, title => $cat->{title} }));
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_category_show

=head2 delete_category

Takes the HTTP form input and removes an existing bookmark category.

Displays a confirmation of the successful removal or error messages otherwise.

=cut
sub delete_category {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/category_delete.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		
		my $id       = $form->get_value('id');
		my $category = $self->{backend}->get_category($id);
		if ($self->{user_level}->level() >= $Konstrukt::Settings->get('bookmarks/userlevel_admin')) {
			if ($self->{backend}->delete_category($id)) {
				#success
				$self->add_node($template->node("$self->{template_path}messages/category_delete_successful.template"));
			} else {
				#failed
				$self->add_node($template->node("$self->{template_path}messages/category_delete_failed.template"));
			}
		} else {
			#permission denied
			$self->add_node($template->node("$self->{template_path}messages/category_delete_failed_permission_denied.template"));
		}
		$self->show_entries();
	} else {
		$self->add_node($form->errors());
	}
}
#= /delete_category

=head2 visit

Redirects to a given bookmark.
Increases the "visits" counter and updates the "last visit" date.

=cut
sub visit {
	my ($self) = @_;
	
	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/visit.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $id     = $form->get_value('id');
		my $entry  = $self->{backend}->get_entry($id);
		unless ($self->{backend}->visit($id)) {
			$Konstrukt::Debug->error_message("Backend error") if Konstrukt::Debug::ERROR;
		}
		$Konstrukt::CGI->redirect($entry->{url});
	} else {
		$self->add_node($form->errors());
	}
}
#= /visit

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt::Plugin::bookmarks::DBI>, L<Konstrukt::Plugin>, L<Konstrukt>

=cut

__DATA__

-- 8< -- textfile: layout/category_add.form -- >8 --

$form_name = 'addcat';
$form_specification =
{
	title     => { name => 'Title (not empty)'                 , minlength => 1, maxlength => 256, match => '' },
	parent_id => { name => 'ID of the parent-category (number)', minlength => 1, maxlength => 256, match => '' },
	private   => { name => 'Private'                           , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/category_add_show.form -- >8 --

$form_name = 'addcatshow';
$form_specification =
{
	id => { name => 'ID of the parent-category (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/category_add_show.template -- >8 --

<& formvalidator form="category_add.form" / &>
<div class="bookmarks form">
	<h1>Add category</h1>
	<form name="addcat" action="" method="post" onsubmit="return validateForm(document.addcat)">
		<input type="hidden" name="action"    value="addcat" />
		<input type="hidden" name="parent_id" value="<+$ parent_id $+>0<+$ / $+>" />
		
		<label>Parent-category:</label>
		<p><+$ parent_title $+>(no title)<+$ / $+></p>
		<br />
		
		<label>Title of the new category:</label>
		<input name="title" maxlength="255" />
		<br />
		
		<label>Private:</label>
		<div style="width: 500px">
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" />
		<label for="private" class="checkbox">This category is only visible for me.</label>
		<p>Subordinate categories and bookmarks will also only be visible to me.</p>
		</div>
		<br />
		
		<label>&nbsp;</label>
		<input type="submit" class="submit" value="Add!" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/category_delete.form -- >8 --

$form_name = 'delcat';
$form_specification =
{
	id           => { name => 'ID of the category (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
	confirmation => { name => 'Confirmation'               , minlength => 0, maxlength => 1, match => '1' },
};

-- 8< -- textfile: layout/category_delete_show.form -- >8 --

$form_name = 'delcatshow';
$form_specification =
{
	id => { name => 'ID of the category (number)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/category_delete_show.template -- >8 --

<& formvalidator form="category_delete.form" / &>
<div class="bookmarks form">
	<h1>Confirmation: Delete category</h1>
	
	<p>Shall the category '<+$ title $+>(no title)<+$ / $+>' really be deleted with all its subordinate categories and bookmarks?</p>
	
	<form name="delcat" action="" method="post" onsubmit="return validateForm(document.delcat)">
		<input type="hidden" name="action" value="delcat" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<input id="confirmation" name="confirmation" type="checkbox" class="checkbox" value="1" />
		<label for="confirmation" class="checkbox">Yeah, kill it!</label>
		<br />
		
		<input value="Big red button" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/category_edit.form -- >8 --

$form_name = 'editcat';
$form_specification =
{
	id        => { name => 'ID of the category (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
	title     => { name => 'Title (not empty)'          , minlength => 1, maxlength => 256, match => '' },
	category  => { name => 'Parent-category (number)'   , minlength => 1, maxlength => 8,   match => '^\d+$' },
	private   => { name => 'Private'                    , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/category_edit_show.form -- >8 --

$form_name = 'editcategoryshow';
$form_specification =
{
	id => { name => 'ID of the category (number)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/category_edit_show.template -- >8 --

<& formvalidator form="category_edit.form" / &>
<div class="bookmarks form">
	<h1>Edit category</h1>
	<form name="editcat" action="" method="post" onsubmit="return validateForm(document.editcat)">
		<input type="hidden" name="action" value="editcat" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<label>Title:</label>
		<input name="title" maxlength="255" value="<+$ title / $+>" />
		<br />
		
		<label>Category:</label>
		<select name="category">
			<+@ categories @+><option value="<+$ id $+>0<+$ / $+>"<& if condition="<+$ current $+>0<+$ / $+>"&> selected="selected"<& / &>><+$ title $+>(Kein Titel)<+$ / $+></option>
			<+@ / @+>
		</select>
		<br />
		
		<& if condition="<+$ private / $+>" &>
		<label>Private:</label>
		<div style="width: 500px">
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" checked="checked" />
		<label for="private" class="checkbox">This category is only visible for me.</label>
		<p>Subordinate categories and bookmarks will also be only visible to me.</p>
		<p>Attention: As soon as a category gets public, it cannot be hidden again, as other users might have added new categories and bookmarks!</p>
		</div>
		<br />
		<& / &>
		
		<label>&nbsp;</label>
		<input value="Update!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_add.form -- >8 --

$form_name = 'addentry';
$form_specification =
{
	title     => { name => 'Title (not empty)'          , minlength => 1, maxlength => 256, match => '' },
	url       => { name => 'URL (http://*.*, ftp://*.*)', minlength => 1, maxlength => 256, match => '^([hH][tT]|[fF])[tT][pP]\:\/\/\S+\.\S+$' },
	category  => { name => 'ID of the category (number)', minlength => 1, maxlength => 8,   match => '^\d+$' },
	private   => { name => 'Private'                    , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/entry_add_show.form -- >8 --

$form_name = 'addentryshow';
$form_specification =
{
	id => { name => 'ID of the category (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_add_show.template -- >8 --

<& formvalidator form="entry_add.form" / &>
<div class="bookmarks form">
	<h1>Add bookmark</h1>
	<form name="addentry" action="" method="post" onsubmit="return validateForm(document.addentry)">
		<input type="hidden" name="action"   value="addentry" />
		<input type="hidden" name="category" value="<+$ category_id / $+>" />
		
		<label>Category:</label>
		<p><+$ category_title $+>(no title)<+$ / $+></p>
		<br />
		
		<label>Title:</label>
		<input name="title" maxlength="255" />
		<br />
		
		<label>URL:</label>
		<input name="url" maxlength="255" />
		<br />
		
		<label>Private:</label>
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" />
		<label for="private" class="checkbox">This entry is only visible for me.</label>
		<br />
		
		<label>&nbsp;</label>
		<input value="Add!" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_delete.form -- >8 --

$form_name = 'delentry';
$form_specification =
{
	id           => { name => 'ID of the bookmark (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
	confirmation => { name => 'Confirmation'               , minlength => 0, maxlength => 1, match => '1' },
};

-- 8< -- textfile: layout/entry_delete_show.form -- >8 --

$form_name = 'deleteentryshow';
$form_specification =
{
	id => { name => 'Bookmark-ID (number)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_delete_show.template -- >8 --

<& formvalidator form="entry_delete.form" / &>
<div class="bookmarks form">
	<h1>Confirmation: Delete bookmark</h1>
	
	<p>Shall the bookmark '<+$ title $+>(no title)<+$ / $+>' with the target '<+$ url $+>(no address)<+$ / $+>' really be deleted?</p>
		
	<form name="delentry" action="" method="post" onsubmit="return validateForm(document.delentry)">
		<input type="hidden" name="action" value="delentry" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<input id="confirmation" name="confirmation" type="checkbox" class="checkbox" value="1" />
		<label for="confirmation" class="checkbox">Yeah, kill it!</label>
		<br />
		
		<input value="Big red button" type="submit" class="submit" />
		<br />
	</form>
</div>

-- 8< -- textfile: layout/entry_edit.form -- >8 --

$form_name = 'editentry';
$form_specification =
{
	title     => { name => 'Title (not empty)'          , minlength => 1, maxlength => 256, match => '' },
	url       => { name => 'URL (http://*.*, ftp://*.*)', minlength => 1, maxlength => 256, match => '^([hH][tT]|[fF])[tT][pP]\:\/\/\S+\.\S+$' },
	id        => { name => 'ID of the bookmark (number)', minlength => 1, maxlength => 8,   match => '^\d+$' },
	category  => { name => 'Parent-category (number)'   , minlength => 1, maxlength => 8,   match => '^\d+$' },
	private   => { name => 'Private'                    , minlength => 0, maxlength => 1,   match => '' },
};

-- 8< -- textfile: layout/entry_edit_show.form -- >8 --

$form_name = 'editentryshow';
$form_specification =
{
	id => { name => 'ID of the bookmark (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_edit_show.template -- >8 --

<& formvalidator form="entry_edit.form" / &>
	<h1>Edit bookmark</h1>
	
	<form name="editentry" action="" method="post" onsubmit="return validateForm(document.editentry)">
		<input type="hidden" name="action" value="editentry" />
		<input type="hidden" name="id"     value="<+$ id / $+>" />
		
		<label>Title:</label>
		<input name="title" maxlength="255" value="<+$ title / $+>" />
		<br />
		
		<label>URL:</label>
		<input id="url" name="url" maxlength="255" value="<+$ url   / $+>" />
		<br />
		
		<label>Category:</label>
		<select id="category" name="category">
			<+@ categories @+><option value="<+$ id $+>0<+$ / $+>"<& if condition="<+$ current $+>0<+$ / $+>"&> selected="selected"<& / &>><+$ title $+>(Kein Titel)<+$ / $+></option>
			<+@ / @+>
		</select>
		<br />
		
		<label>Private:</label>
		<div>
		<input id="private" name="private" type="checkbox" class="checkbox" value="1" <& if condition="<+$ private / $+>" &>checked="checked"<& / &> />
		<label for="private" class="checkbox">This entry is only visible for me.</label>
		</div>
		<br />
		
		<label>&nbsp;</label>
		<input value="Update!" type="submit" class="submit" />
		<br />
	</form>
</div>	

-- 8< -- textfile: layout/entry_show.form -- >8 --

$form_name = 'entryshow';
$form_specification =
{
	id => { name => 'ID of the bookmark (number)' , minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: layout/entry_show.template -- >8 --

<div class="bookmarks details">
	<h1>Bookmark details</h1>
	<table>
		<colgroup>
			<col width="150" />
			<col width="550" />
		</colgroup>
		<tr><td>Path:            </td><td><+@ categories @+>/<a href="?cat=<+$ id / $+>"><+$ title $+>(no title)<+$ / $+></a><+@ / @+></td></tr>
		<tr><td>Title:           </td><td><+$ title $+>(no title)<+$ / $+></td></tr>
		<tr><td>URL:             </td><td><a href="/links/visit/?id=<+$ id / $+>"><+$ url $+>(no URL)<+$ / $+></a></td></tr>
		<tr><td>Private:         </td><td><& perl &>my $priv = '<+$ private / $+>'; print ($priv ? 'Yes' : 'No');<& / &></td></tr>
		<tr><td>Author:          </td><td><a href="/intern/personal/show/?id=<+$ author_id / $+>"><+$ author $+>(no name)<+$ / $+></a></td></tr>
		<tr><td>Number of visits:</td><td><+$ visits $+>0<+$ / $+></td></tr>
		<tr><td>Last visit:      </td><td>On <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> at <+$ hour $+>??<+$ / $+>:<+$ minute $+>??<+$ / $+></td></tr>
	</table>
</div>

-- 8< -- textfile: layout/symbol_legend.template -- >8 --

<hr />

<h2>Legend:</h2>

<h3>[ edit ]</h3>
<p><strong>Edit</strong> an existing entry.</p>
<p>Only possible, when you are the creator of the entry or an administator.</p>

<h3>[ delete ]</h3>
<p><strong>Delete</strong> an existing entry.<br />
<p>Only possible, when you are the creator of the entry or an administator.</p>

<h3>[ add folder ]</h3>
<p><strong>Add</strong> a new category.</p>

<h3>[ add entry ]</h3>
<p><strong>Add</strong> a new bookmark.</p>

-- 8< -- textfile: layout/tree_category.template -- >8 --

<div class="bookmark_category_tree<+$ tree $+>0<+$ / $+>">
	<& if condition="'<+$ tree $+>0<+$ / $+>'" &>
		<img src="/images/bookmarks/tree<+$ tree $+>0<+$ / $+>.gif" alt="L" style="float: left; margin-left: -26px;" />
	<& / &>
	
	<span class="title">
	<a href="?cat=<+$ id $+>0<+$ / $+>"><+$ title $+>(no title)<+$ / $+></a>
	
	<& if condition="<+$ private / $+>" &>
		(private)
	<& / &>
	</span>
	
	<span class="actions">
	<& if condition="<+$ may_write  / $+>" &>
		<a href="?action=addcatshow;id=<+$ id / $+>">[ add folder ]</a>
		<a href="?action=addentryshow;id=<+$ id / $+>">[ add entry ]</a>
	<& / &>
	
	<& if condition="<+$ may_edit / $+>" &>
		<a href="?action=editcatshow;id=<+$ id / $+>">[ edit ]</a>
	<& / &>
	
	<& if condition="<+$ may_delete / $+>" &>
		<a href="?action=delcatshow;id=<+$ id / $+>">[ delete ]</a>
	<& / &>
	</span>
	
	<+@ categories @+>
		<+$ category $+>(empty)<+$ / $+>
	<+@ / @+>
	
	<+@ bookmarks @+>
		<div class="bookmark_entry_tree<+$ tree $+>0<+$ / $+>">
			<span class="title">
			<a href="/links/visit/?id=<+$ id / $+>">* <+$ title $+>(no title)<+$ / $+></a>
			</span>
			
			<span class="actions">
			<& if condition="<+$ private / $+>" &>
				(private)
			<& / &>
			
			<a href="?action=showentry;id=<+$ id / $+>">[ details ]</a>
			
			<& if condition="<+$ may_edit / $+>" &>
				<a href="?action=editentryshow;id=<+$ id / $+>">[ edit ]</a>
				<a href="?action=delentryshow;id=<+$ id / $+>">[ delete ]</a>
			<& / &>
			</span>
		</div>
	<+@ / @+>
</div>

<& if condition="<+$ id $+>0<+$ / $+> == 0 and <+$ may_write $+>0<+$ / $+>" &>
	<& template src="symbol_legend.template" / &>
<& / &>

-- 8< -- textfile: layout/visit.form -- >8 --

$form_name = 'visit';
$form_specification =
{
	id => { name => 'ID of the bookmark (number)', minlength => 1, maxlength => 8, match => '^\d+$' },
};

-- 8< -- textfile: messages/category_add_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Category not added</h1>
	<p>An internal error occurred while adding the category.</p>
</div>

-- 8< -- textfile: messages/category_add_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Category added</h1>
	<p>The category has been added successfully!</p>
</div>

-- 8< -- textfile: messages/category_delete_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Category not deleted</h1>
	<p>An internal error occurred while deleting the category.</p>
</div>

-- 8< -- textfile: messages/category_delete_failed_permission_denied.template -- >8 --

<div class="bookmarks message failure">
	<h1>Category not deleted</h1>
	<p>The category has not been deleted, because only administrators can delete categories!</p>
</div>

-- 8< -- textfile: messages/category_delete_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Category deleted</h1>
	<p>The category has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/category_edit_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Category not updated</h1>
	<p>An internal error occurred while updating the category.</p>
</div>

-- 8< -- textfile: messages/category_edit_failed_permission_denied.template -- >8 --

<div class="bookmarks message failure">
	<h1>Category not updated</h1>
	<p>The category has not been updated, because you have to be the author of this category or an administrator!</p>
</div>

-- 8< -- textfile: messages/category_edit_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Category updated</h1>
	<p>The category has been updated successfully</p>
</div>

-- 8< -- textfile: messages/entry_add_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Bookmark not added</h1>
	<p>An internal error occurred while adding the bookmark.</p>
</div>

-- 8< -- textfile: messages/entry_add_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Bookmark added</h1>
	<p>The bookmark has been added successfully!</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Bookmark not deleted</h1>
	<p>An internal error occurred while deleting the bookmark.</p>
</div>

-- 8< -- textfile: messages/entry_delete_failed_permission_denied.template -- >8 --

<div class="bookmarks message failure">
	<h1>Bookmark not deleted</h1>
	<p>The bookmark has not been deleted, because only the author of this bookmark or an administrator can delete this bookmark!</p>
</div>

-- 8< -- textfile: messages/entry_delete_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Bookmark deleted</h1>
	<p>The bookmark has been deleted successfully!</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed.template -- >8 --

<div class="bookmarks message failure">
	<h1>Bookmark not updated</h1>
	<p>An internal error occured while updating this bookmark.</p>
</div>

-- 8< -- textfile: messages/entry_edit_failed_permission_denied.template -- >8 --

<div class="bookmarks message failure">
	<h1>Bookmark not updated</h1>
	<p>The bookmark has not been updated, because only the author of this bookmark can update it!</p>
</div>

-- 8< -- textfile: messages/entry_edit_successful.template -- >8 --

<div class="bookmarks message success">
	<h1>Bookmark updated</h1>
	<p>The bookmark has been updated successfully!</p>
</div>

-- 8< -- textfile: /styles/bookmarks.css -- >8 --

/* CSS definitions for the Konstrukt bookmarks plugin */

div.bookmark_category_tree2 {
	background: url(/images/bookmarks/tree1bg.gif) repeat-y;
	padding: 0 0 5px 26px;
}
div.bookmark_category_tree3 {
	padding: 0 0 5px 26px;
}

div.bookmark_entry_tree2 {
	background: url(/images/bookmarks/tree2bg.gif) no-repeat center left;
	padding-left: 26px;
}
div.bookmark_entry_tree3 {
	background: url(/images/bookmarks/tree3bg.gif) no-repeat center left;
	padding-left: 26px;
}

div.bookmark_category_tree0 img, div.bookmark_category_tree2 img, div.bookmark_category_tree3 img {
	vertical-align: middle;
	width: 20px;
	height: 20px;
}

div.bookmark_category_tree0 span.title, div.bookmark_category_tree1 span.title,
div.bookmark_category_tree2 span.title, div.bookmark_category_tree3 span.title {
	font-size: 1.4em;
} 

div.bookmark_category_tree0 span.actions, div.bookmark_category_tree1 span.actions,
div.bookmark_category_tree2 span.actions, div.bookmark_category_tree3 span.actions {
	font-size: 1.2em;
} 

-- 8< -- binaryfile: /images/bookmarks/tree1.gif -- >8 --

R0lGODlhFAAUAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUABQAAAIjlC+By6gNz4twUmav
0y3z9C0eN2rldVJptFbh9hptF8s1eBUAOw==

-- 8< -- binaryfile: /images/bookmarks/tree2.gif -- >8 --

R0lGODlhFAAUAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUABQAAAImlC+By6gNz4twUmav
0y3z9C3BSJZkF26p4XGt9l4xNUd1tbI5eBUAOw==

-- 8< -- binaryfile: /images/bookmarks/tree3.gif -- >8 --

R0lGODlhFAAUAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUABQAAAIelC+By6gNz4twUmav
0y3z9C3BSJZkiKbqyrbuC8cFADs=

-- 8< -- binaryfile: /images/bookmarks/tree1bg.gif -- >8 --

R0lGODlhFAAUAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUABQAAAIjlC+By6gNz4twUmav
0y3z9C0eN2rldVJptFbh9hptF8s1eBUAOw==

-- 8< -- binaryfile: /images/bookmarks/tree2bg.gif -- >8 --

R0lGODlhFAAoAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUACgAAAI9lC+By6gNz4twUmav
0y3z9C0eN2rldVJptFbh9hptF8t1EuT6ntP1jLkBRcLizxgbwpLIl1LSDD1txyqlAAA7

-- 8< -- binaryfile: /images/bookmarks/tree3bg.gif -- >8 --

R0lGODlhFAAoAJEAAP///wAAAAAAAP///yH5BAEAAAIALAAAAAAUACgAAAIzlC+By6gNz4twUmav
0y3z9C0eN2rldVJptFbh9hptF8vBjed3zff+DwwKh8Si8YhMKjUFADs=
