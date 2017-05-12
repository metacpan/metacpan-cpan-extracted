#FEATURE: Caching of the image somewhere inside the docroot and redirect to
#         the static file

=head1 NAME

Konstrukt::Plugin::wiki::backend::image - Base class for image backends

=head1 SYNOPSIS
	
	use base 'Konstrukt::Plugin::wiki::backend::image';
	#overwrite the methods
	
	#note that you can use $self->backend_method() in the action methods as
	#only an instance of the backend class will be created and it will inherit your methods.
	
=head1 DESCRIPTION

Base class for a backend class that implements the backend
functionality (store, retrieve, ...) for images (*.jpg, *.gif, *.png, ...).

This one is very similar to L<Konstrukt::Plugin::wiki::backend::file> but adds some
image-specific funtionality.

Includes the control/display code for managing images as it won't change with
different backend types (DBI, file, ...). So the implementing backend class will
inherit this code but must overwrite the data retrieval and update code.

Although currently only DBI-backends exist, it should be easy to develop
other backends (e.g. file based).

Note that the name of the images will be normalized.
All characters but letters, numbers, hyphens, parenthesis, brackets and dots
will be replaced by underscores.
Internally image names are case insensitive. So C<SomeImage.jpg> will point to the same
page as C<someimage.jpg>.

=cut

package Konstrukt::Plugin::wiki::backend::image;

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
	
	#also load wiki plugin to let it define its default settings
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

Responsible for the actions to show manage images.

=cut
sub actions {
	return ('image_show', 'image_edit_show', 'image_edit', 'image_revision_list', 'image_restore_revision', 'image_restore');
}
#= /actions

=head2 prepare

The served image content will of course be dynamic. Don't do anything here.

=cut
sub prepare {
	my ($self, $tag) = @_;
	
	#Don't do anything beside setting the dynamic-flag
	$tag->{dynamic} = 1;
	
	return undef;
}
#= /prepare

=head2 execute

This one will be called, when an image's content will be downloaded. It will
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
	my $backend = use_plugin 'wiki::backend::image::' . $Konstrukt::Settings->get("wiki/backend_type");
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	if (defined $title) {
		#get the revision that should be displayed
		my $revision = $Konstrukt::CGI->param('revision');
		my $width = $Konstrukt::CGI->param('width') || undef;
		my $image = $backend->get_content($title, $revision, $width);
		if	(defined $image) {
			$self->add_node($image->{content});
			$Konstrukt::Response->header('Content-Type' => $image->{mimetype} || 'image/jpeg');
		} else {
			#$self->add_node("Image '$title rev $revision' not found!");
			$Konstrukt::Response->status(404);
		}
	} else {
		$self->add_node("No image specified!");
	}
	
	return $self->get_nodes();
}
#= /execute

=head2 image_show

Will handle the action to show an information page for an image.

=cut
sub image_show {
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
			my $image = $self->get_info($title, $revision);
			
			map { $image->{$_} = sprintf("%02d", $image->{$_}) } qw/month day hour minute/;
			$image->{title}             = $Konstrukt::Lib->html_escape($title);
			$image->{title_uri_encoded} = $Konstrukt::Lib->uri_encode($title);
			$image->{description}       = $Konstrukt::Lib->html_escape($image->{description});
			$image->{author_name}       = $self->{user_personal}->data($image->{author})->{nick};
			$image->{may_write}         = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
			
			$self->add_node($template->node("$self->{template_path}layout/image_info.template", { fields => $image }));
		} else {
			#image doesn't exist yet
			$self->image_edit_show($title);
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/image_info_no_image_specified.template"));
	}
}
#= /image_show

=head2 image_edit_show

Will handle the action to show the form to edit/upload an image.

=cut
sub image_edit_show {
	my ($self, $tag) = @_;
	
	#user logged in?
	my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
	
	my $template = use_plugin 'template';
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
	if ($may_edit) {
		#get the revision that should be displayed
		my $latest_revision = $self->revision($title);
		
		my $image;
		if (defined $latest_revision) {
			$image = $self->get_info($title);
			$image->{description} = $Konstrukt::Lib->html_escape($image->{description});
		}
		$image->{title}             = $title_html_escaped;
		$image->{title_uri_encoded} = $title_uri_encoded;
		
		$self->add_node($template->node("$self->{template_path}layout/image_edit_form.template", { fields => $image }));
	} else {
		$self->add_node($template->node("$self->{template_path}messages/image_edit_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /image_edit_show 

=head2 image_edit

Will handle the action to update an image.

=cut
sub image_edit {
	my ($self, $tag) = @_;

	my $form = use_plugin 'formvalidator';
	$form->load("$self->{template_path}layout/image_edit_form.form");
	$form->retrieve_values('cgi');
	
	if ($form->validate()) {
		my $template = use_plugin 'template';
		my $title = $form->get_value('title');
		#user logged in?
		my $may_edit = ($self->{user_basic}->id() and $self->{user_level}->level() >= $Konstrukt::Settings->get('wiki/userlevel_write'));
		
		if ($may_edit) {
			my ($filename, $mimetype, $extension, $content, $description);
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
			my $result = $self->store($title, $store_description, $description, $store_content, $content, $mimetype, $self->{user_basic}->id(), $Konstrukt::Handler->{ENV}->{REMOTE_ADDR});
			my $values = {
				title             => $Konstrukt::Lib->html_escape($title),
				title_uri_encoded => $Konstrukt::Lib->uri_encode($title)
			};
			if (defined $result and $result == -1) {
				#no change
				$self->add_node($template->node("$self->{template_path}messages/image_edit_no_change.template", $values));
				$self->image_edit_show();
			} elsif (defined $result and $result == -2) {
				#invalid image
				$self->add_node($template->node("$self->{template_path}messages/image_edit_failed_invalid_image.template", $values));
				$self->image_edit_show();
			} elsif (defined $result) {
				#success
				$self->image_show();
			} else {
				#error
				$self->add_node($template->node("$self->{template_path}messages/image_edit_failed.template", $values));
			}
		} else {
			$self->add_node($template->node("$self->{template_path}messages/image_edit_failed_permission_denied.template", { title => $Konstrukt::Lib->html_escape($title), title_uri_encoded => $Konstrukt::Lib->uri_encode($title) }));
		}
	} else {
		$self->add_node($form->errors());
	}
}
#= /image_edit

=head2 image_revision_list

Will handle the action to show the revision history of an image.

=cut
sub image_revision_list {
	my ($self, $tag) = @_;
	
	my $template = use_plugin 'template';
	
	my $title = $Konstrukt::CGI->param('title') || undef;
	my $title_html_escaped = $Konstrukt::Lib->html_escape($title);
	my $title_uri_encoded  = $Konstrukt::Lib->uri_encode($title);
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
		$self->add_node($template->node("$self->{template_path}layout/image_revision_list.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded, revision_count => $revision_count, revisions => $revisions }));
	} else {
		#error
		$self->add_node($template->node("$self->{template_path}messages/image_revision_list_failed.template"));
	}
}
#= /image_revision_list

=head2 image_restore

Will handle the action to restore an image's content and/or description.

=cut
sub image_restore {
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
				$self->add_node($template->node("$self->{template_path}messages/image_restore_failed.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			} elsif ($result == -1) {
				#no change
				$self->add_node($template->node("$self->{template_path}messages/image_restore_failed_no_change.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
			}
			$self->image_revision_list();
		} else {
			$self->add_node($template->node("$self->{template_path}messages/image_restore_failed_incomplete.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
		}
	} else {
		$self->add_node($template->node("$self->{template_path}messages/image_restore_failed_permission_denied.template", { title => $title_html_escaped, title_uri_encoded => $title_uri_encoded }));
	}
}
#= /image_restore

=head2 exists

This method will return true, if a specified image exists. It will return
undef otherwise.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the image

=item * $revision - Optional: A specific revision of an image

=back

=cut
sub exists {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /exists

=head2 revision

This method will return the latest revision number/number of revisions of a
specified image. It will return undef if the specified image does not
exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the image

=back

=cut
sub revision {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 revisions

This method will return all revisions of the specified image as an array of
hash references ordered by ascending revision numbers:

	[
		{ revision => 1, description => 'foo', description_revision => 3, content_revision => 4, content => 1, author => 'bar', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },
		{ revision => 2, ...},
		...
	]
	
Will return undef, if the image doesn't exist.

Note that description_revision and content_revision may also be 0 if no content has been saved yet.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the image

=back

=cut
sub revisions {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /revision

=head2 get_info

This method will return the image info as a hashref:

		{ title => 'foo', revision => 7, description => 'some text', description_revision => 3, content_revision => 4, width, height, mimetype, author => 'foo', host => '123.123.123.123', year => 2005, month => 1, day => 1, hour => 0, => minute => 0 },

Will return undef, if the requested image doesn't exist.

Note that the description_revision and content_revision may also be 0 if no content has been saved yet.

If there is no content yet (content_revision == 0), the fields width, height and mimetype will be undefined/will not exist.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the image

=item * $revision - Optional: A specific revision of an image. When not
specified, the latest revision will be returned.

=back

=cut
sub get_info {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /get_info

=head2 get_content

This method will return the image content as a hashref:

		{ content => 'binarydata', mimetype => 'image/jpg', width => 800, height => 600, original => 'boolean' }

Will return undef, if the requested image doesn't exist or there is no content yet.

Must be overwritten by the implementing class.

B<Parameters>:

=over

=item * $title - The title of the image

=item * $revision - Optional: A specific revision of an image's content (which).
When not defined, the latest revision will be returned.

=item * $width - Optional: Return a resized version of this image. The image
should only be downscaled and not upscaled. When not defined, the original
resolution will be used.

=back

=cut
sub get_content {
	$Konstrukt::Debug->error_message('This method must be overwritten by the implementing class!') if Konstrukt::Debug::ERROR;
	return undef;
}
#= /get_content

=head2 store

This method will add a new image (or new revision if the image already
exists) to the store.

If the image already exists, you may also just add a new description or a new
content for the image. Pass undef for the value, you don't want to change.

Will return -1 if no change has been made (which is the case, when no new
content and no new description has been passed and the image already exists in
the database).

Will return -2 if the passed content is no valid image file.

Will return true on successful update and undef on error.

B<Parameters>:

=over

=item * $title - The title of the image

=item * $store_description - True, if a new description should be stored. False,
if the old one should be left.

=item * $description - A description of this image. May be undef to reset (delete)
the description for the new revision.

=item * $store_content - True, if a new content should be stored. False,
if the old one should be left.

=item * $content - The (binary) content that should be stored. May be undef
to reset (delete) the content for the new revision.

=item * $mimetype - The MIME type of the image

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

This method will restore a description and/or a content from a given image revision.

Will return -1 if no change has been made (which is the case, when the current
data and the data, which should be restored, are the same).
Will return true on successful update and undef on error.

B<Parameters>:

=over

=item * $title - The title of the image

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

-- 8< -- textfile: layout/image_edit_form.form -- >8 --

$form_name = 'edit';
$form_specification =
{
	title             => { name => 'Title (not empty)', minlength => 1, maxlength =>        256, match => '' },
	description       => { name => 'Description'      , minlength => 0, maxlength =>      65536, match => '' },
	content           => { name => 'Content'          , minlength => 0, maxlength => 4294967296, match => '' },
};

-- 8< -- textfile: layout/image_edit_form.template -- >8 --

<& formvalidator form="image_edit_form.form" / &>
<div class="wiki form">
	<h1>Edit/upload image:</h1>
	
	<form name="edit" action="" method="post" enctype="multipart/form-data" onsubmit="return validateForm(document.edit)">
		<input type="hidden" name="action" value="image_edit" />
		
		<label>Title:</label>
		<input name="title" maxlength="255" value="<+$ title $+>(no title)<+$ / $+>" />
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
		
		<label>Image:</label>
		<div style="width: 600px">
			<p>Current image:</p>
			<p>
			<& perl &>
				my $content = '<+$ content_revision $+>0<+$ / $+>';
				my $title_uri_encoded = '<+$ title_uri_encoded / $+>';
				if ($content) {
					print "<a href=\"/wiki/image/?action=file_content;title=$title_uri_encoded;revision=$content;width=<+$ width $+>0<+$ / $+>\">
						<img src=\"/wiki/image/?action=image_content;title=$title_uri_encoded;revision=$content;width=100\" alt=\"Vorschau\" />
					</a>";
				} else {
					print '(no image yet)';
				}
			<& / &>
			</p>
			<input id="store_content" name="store_content" type="checkbox" class="checkbox" value="1" />
			<label for="store_content" class="checkbox">New image: (keep empty to remove the image)</label>
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
	<p>It's possible to create a new image without a description and without a content. Those can be added later.</p>
</div>

-- 8< -- textfile: layout/image_info.template -- >8 --

<div class="wiki image info">
	<h1>Image: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	<p>Description:</p>
	<p><+$ description $+>(no description)<+$ / $+></p>
	<hr />
	<& if condition="<+$ content_revision $+>0<+$ / $+>" &>
		<$ then $>
			<p>Original resolution: <+$ width $+>?<+$ / $+> x <+$ height $+>?<+$ / $+> px</p>
			<p>Preview (click for original image):</p>
			<p>
			<a href="/wiki/image/?action=image_content;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>;width=0">
			<img src="/wiki/image/?action=image_content;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>;width=500" alt="Preview" />
			</a>
			</p>
		<$ / $>
		<$ else $><p>(no image yet)</p><$ / $>
	<& / &>
	
	<& if condition="<+$ may_write $+>0<+$ / $+>" &>
	<hr />
	<p>Revision <+$ revision $+>(no revision)<+$ / $+>. Created on <+$ year $+>????<+$ / $+>-<+$ month $+>??<+$ / $+>-<+$ day $+>??<+$ / $+> by <+$ author_name $+>(no author)<+$ / $+> (author ID: <+$ author $+>0<+$ / $+>).</p>
	<p><a href="?action=image_edit_show;title=<+$ title_uri_encoded / $+>">Edit</a>, <a href="?action=image_revision_list;title=<+$ title_uri_encoded / $+>">Revisions</a></p>
	<& / &>
</div>

-- 8< -- textfile: layout/image_revision_list.template -- >8 --

<div class="wiki image revisionlist">
	<h1>Revisionlist for image: <+$ title $+>(no title)<+$ / $+></h1>
	<hr />
	<form name="restore" action="" method="post">
		<input type="hidden" name="action" value="image_restore" />
		<input type="hidden" name="title" value="<+$ title / $+>" />
		
		<table>
			<tr><th>Revision/Preview</th><th>Description</th><th>Date</th><th>Author</th><th>Restore</th></tr>
			<+@ revisions @+><tr>
				<td>
					<a href="?action=image_show;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>"><+$ revision / $+><& if condition="<+$ content_revision $+>0<+$ / $+>" &>
						<img src="/wiki/image/?action=image_content;title=<+$ title_uri_encoded / $+>;revision=<+$ revision / $+>;width=50" alt="Preview" />
					<& / &></a>
				</td>
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

-- 8< -- textfile: messages/image_edit_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Image '<+$ title $+>(no title)<+$ / $+>' could be updated!</h1>
	<p>An internal error occurred</p>
</div>

-- 8< -- textfile: messages/image_edit_failed_invalid_image.template -- >8 --

<div class="wiki message failure">
	<h1>The uploaded image is invalid</h1>
	<p>Only the following formats are supported: <a href="http://www.imagemagick.org/script/formats.php">ImageMagick formats</a></p>
	<p>Maybe the upload was interrupted or the image is broken.</p>
</div>

-- 8< -- textfile: messages/image_edit_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>Image '<+$ title $+>(no title)<+$ / $+>' cannot be edited!</h1>
	<p>You don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/image_edit_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>No changes for image '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>Neither a new description nor a new image have been specified (or the specified contents are identical to the current ones) and there already exists an entry for this image title.</p>
</div>

-- 8< -- textfile: messages/image_info_no_file_specified.template -- >8 --

<div class="wiki message failure">
	<h1>Image cannot be displayed</h1>
	<p>No image specified.</p>
<& / &>

-- 8< -- textfile: messages/image_restore_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Contents of the image '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>An internal error occurred.</p>
</div>

-- 8< -- textfile: messages/image_restore_failed_incomplete.template -- >8 --

<div class="wiki message failure">
	<h1>Image '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The needed information (title, revision, data to restore) are incomplete.</p>
</div>

-- 8< -- textfile: messages/image_restore_failed_no_change.template -- >8 --

<div class="wiki message failure">
	<h1>Image '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The requested restore has not been performed as it would leed to no change. The revision to restore is identical to the current one.</p>
</div>

-- 8< -- textfile: messages/image_restore_failed_permission_denied.template -- >8 --

<div class="wiki message failure">
	<h1>Image '<+$ title $+>(no title)<+$ / $+>' not restored</h1>
	<p>The image has not been restored, because you don't have the appropriate permissions!</p>
</div>

-- 8< -- textfile: messages/image_revision_list_failed.template -- >8 --

<div class="wiki message failure">
	<h1>Cannot display revision list for image '<+$ title $+>(no title)<+$ / $+>'</h1>
	<p>Either this file does not exist or an internal error occurred.</p>
</div>

-- 8< -- textfile: /wiki/image/index.html -- >8 --

<& wiki::backend::image / &>

