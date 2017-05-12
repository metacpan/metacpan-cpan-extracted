package GappX::Dialogs;
{
  $GappX::Dialogs::VERSION = '0.005';
}

use GappX::Dialogs::Meta::Widget::Trait::ConfirmDialog;
use GappX::Dialogs::Meta::Widget::Trait::ErrorDialog;
use GappX::Dialogs::Meta::Widget::Trait::InfoDialog;
use GappX::Dialogs::Meta::Widget::Trait::MessageDialog;
use GappX::Dialogs::Meta::Widget::Trait::QuestionDialog;
use GappX::Dialogs::Meta::Widget::Trait::WarningDialog;

1;

__END__

=pod

=head1 NAME

GappX::Dialogs - Traits for common dialog windows

=head1 SYNOPSIS

  use Gapp;

  use GappX::Dialogs;

  $dlg = Gapp::Dialog->new(

    traits => [qw( InfoDialog )],

    text => 'Primary Text',

    secondary => 'Secondary Text',

  );

  $dlg->run;
     
=head1 DESCRIPTION

GappX::Dialogs provides a number of traits to be used with L<Gapp::Dialog> widgets.
Use these traits to display commonly used dialog windows.

=head1 PROVIDED TRAITS

All of the traits in this package apply the L<MessageDialog|GappX::Dialogs::Meta::Widget::Trait::MessageDialog>
trait to your object. See  L<GappX::Dialogs::Meta::Widget::Trait::MessageDialog> for more information.

=over 4

=item ConfirmDialog

L<GappX::Dialogs::Meta::Widget::Trait::ConfirmDialog>

=item ErrorDialog

L<GappX::Dialogs::Meta::Widget::Trait::ErrorDialog>

=item InfoDialog

L<GappX::Dialogs::Meta::Widget::Trait::InfoDialog>

=item MessageDialog

L<GappX::Dialogs::Meta::Widget::Trait::MessageDialog>

=item QuestionDialog

L<GappX::Dialogs::Meta::Widget::Trait::QuestionDialog>

=item WarningDialog

L<GappX::Dialogs::Meta::Widget::Trait::WarningDialog>

=back

=head1 SUPPORT

Support for this module is provided via the gapp-list@chronosoft.ws email list.
See L<http://chronosoft.ws/gapp/list> for details.

=head1 SEE ALSO

=over 4

=item L<Gapp>

=item L<Gtk2>

=item L<Moose>

=back

=head1 AUTHORS

Jeffrey Ray Hallock E<lt>jeffrey.hallock at gmail dot comE<gt>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2012 Jeffrey Ray Hallock.
    
This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
