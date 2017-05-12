package Kwiki::Edit::RequireUserName;

use warnings;
use strict;
use Kwiki::Plugin '-Base';
use mixin 'Kwiki::Installer';

our $VERSION = '0.02';

const class_id => 'EditRequireUserName';
const class_title => 'Require UserName to edit';

sub register {
  my $registry = shift;
  $registry->add(action   => 'edit_noUserName');
  $registry->add(hook => 'edit:edit', pre => 'require_username');

}

sub require_username {
  my $hook = pop;
  my $req_username_obj = $self->hub->load_class('EditRequireUserName');
  my $page = $self->pages->current;
  if (! $req_username_obj->have_UserName) {
    my $page_uri = $page->uri;
    $hook->cancel();		# don't bother calling Kwiki::Edit::edit
    return $self->redirect("action=edit_noUserName&page_name=$page_uri");
  }
}

sub have_UserName {
  my $current_name   = $self->hub->users->current->name ||
    die "Can't determine current UserName";
  my $anonymous_name = $self->config->user_default_name ||
    die "Can't determine local name of anonymous user";  # set in
                                                         # config/user.yaml
  return ($current_name ne $anonymous_name);
}

sub edit_noUserName {
    return $self->render_screen(
        content_pane => 'edit_noUserName.html',
    );
}

1;

__DATA__

=head1 NAME

Kwiki::Edit::RequireUserName - Replaces Kwiki::Edit in order to require a user name to edit

=head1 SYNOPSIS

This plugin helps reduce WikiSpam by requiring that the user have a
user name before editing.  The idea is that SpamBots won't take the
trouble to do this.  Of course this won't prevent spam created
manually.

=head1 REQUIRES

   Kwiki 0.37 (new hooking mechanism)
   Kwiki::UserName (adds user name functionality to Kwiki)
   Kwiki::UserPreferences (adds the ability to change user names)


=head1 INSTALLATION

   perl Makefile.PL
   make
   make test
   make install

   cd ~/where/your/kwiki/is/located
   vi plugins

Add the line

  Kwiki::Edit::RequireUserName

If you don't already have them add the following also

  Kwiki::UserName
  Kwiki::UserPreferences

Then run

  kwiki -update

=head1 UPGRADING

The previous version of Kwiki::Edit::RequireUserName subclassed
Kwik::Edit, so the old documentation asked you to remove Kwiki::Edit
from your list of plugins.  This new version of
Kwiki::Edit::RequireUserName no longer subclasses Kwiki::Edit, so you
should put that line back in.

=head1 AUTHOR

James Peregrino, C<< <jperegrino@post.harvard.edu> >>

=head1 ACKNOWLEDGEMENTS

This plugin was inspired by the techniques used in Kwiki::Scode by
Kang-min Liu.

=head1 BUGS

Please report any bugs or feature requests to
C<bug-kwiki-edit-requireusername@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically
be notified of progress on your bug as I make changes.

=head1 Copyright & License

Copyright 2004 James Peregrino, All Rights Reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
__template/tt2/edit_noUserName.html__
<!-- BEGIN edit_noUserName.html -->
<div class="error">
<p>
This web site does not allow anonymous editing.  Please go to <a
href="?action=user_preferences">User Preferences</a> button and create
a UserName for yourself.
</p>
<p>
</p>
</div>
<!-- END edit_noUserName.html -->
__template/tt2/edit_button.html__
<!-- BEGIN edit_button.html -->
[% IF hub.pages.current.is_writable %]
[% rev_id = hub.have_plugin('revisions') ? hub.revisions.revision_id : 0 %]
<a href="[% script_name %]?action=edit&page_name=[% page_uri %][% IF rev_id %]&revision_id=[% rev_id %][% END %]" accesskey="e" title="Edit This Page">
[% INCLUDE edit_button_icon.html %]
</a>
[% END %]
<!-- END edit_button.html -->
