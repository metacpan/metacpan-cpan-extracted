package Gtk2::Ex::Dialogs;
###############################################################################
#  Gtk2::Ex::Dialogs - Useful tools for Gnome2/Gtk2 Perl GUI design.
#  Copyright (C) 2005  Open Door Software Inc. <ods@opendoorsoftware.com>
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Lesser General Public
#  License as published by the Free Software Foundation; either
#  version 2.1 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#  Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public
#  License along with this library; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
###############################################################################
use strict;

BEGIN {
    use Carp;
    use constant FALSE => 0;
    use Gtk2::Ex::Dialogs::Message;
    use Gtk2::Ex::Dialogs::ErrorMsg;
    use Gtk2::Ex::Dialogs::Question;
    use Gtk2::Ex::Dialogs::ChooseFile;
    use Gtk2::Ex::Dialogs::ChoosePreviewFile;
    use Gtk2::Ex::Dialogs::ChooseDirectory;
	use vars qw( $VERSION $parent_window $title $icon $text
                 $destroy_with_parent $modal $no_separator
                 $default_yes $must_exist $AUTOLOAD );
    $VERSION = '0.11';
}

sub import {
    my $class = shift();
    my $cfg = undef;

    if ( @_ % 2 == 0 ) {
        $cfg = { @_ };
    } elsif ( @_ % 2 >= 1 ) {
        croak( $class . " class received an uneven argument list." );
    } else {
        $cfg = {};
    }

    $Gtk2::Ex::Dialogs::title               =
     $cfg->{title}                   || '';
    Gtk2::Ex::Dialogs->set_title( $Gtk2::Ex::Dialogs::title );

    $Gtk2::Ex::Dialogs::text                =
     $cfg->{text}                    || '';
    Gtk2::Ex::Dialogs->set_text( $Gtk2::Ex::Dialogs::text );

    $Gtk2::Ex::Dialogs::icon                =
     $cfg->{icon}                    || '';
    Gtk2::Ex::Dialogs->set_icon( $Gtk2::Ex::Dialogs::icon );

    $Gtk2::Ex::Dialogs::modal               =
     $cfg->{modal}                   || FALSE;
    Gtk2::Ex::Dialogs->set_modal( $Gtk2::Ex::Dialogs::modal );

    $Gtk2::Ex::Dialogs::no_separator        =
     $cfg->{no_separator}            || FALSE;
    Gtk2::Ex::Dialogs->set_no_separator( $Gtk2::Ex::Dialogs::no_separator );

    $Gtk2::Ex::Dialogs::parent_window       =
     $cfg->{parent_window}           || undef;
    Gtk2::Ex::Dialogs->set_parent_window( $Gtk2::Ex::Dialogs::parent_window );

    $Gtk2::Ex::Dialogs::destroy_with_parent =
     $cfg->{destroy_with_parent}     || FALSE;
    Gtk2::Ex::Dialogs->set_destroy_with_parent( $Gtk2::Ex::Dialogs::destroy_with_parent );

    $Gtk2::Ex::Dialogs::default_yes         =
     $cfg->{"default_yes"}           || FALSE;
    Gtk2::Ex::Dialogs->set_default_yes( $Gtk2::Ex::Dialogs::default_yes );

    $Gtk2::Ex::Dialogs::must_exist          =
     $cfg->{must_exist}              || FALSE;
    Gtk2::Ex::Dialogs->set_must_exist( $Gtk2::Ex::Dialogs::must_exist );

}

sub AUTOLOAD {
    my $class = $_[0];
    my $value = $_[1];

    my $method = $AUTOLOAD;
    $method =~ s!^\Q$class\E\:\:!!;

    if ( $method eq 'set_title' ) {
        $Gtk2::Ex::Dialogs::title                                  = $value;
        $Gtk2::Ex::Dialogs::ChooseDirectory::title                 = $value;
        $Gtk2::Ex::Dialogs::ChooseFile::title                      = $value;
        $Gtk2::Ex::Dialogs::ChoosePreviewFile::title               = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::title                        = $value;
        $Gtk2::Ex::Dialogs::Message::title                         = $value;
        $Gtk2::Ex::Dialogs::Question::title                        = $value;
    } elsif ( $method eq 'set_text' ) {
        $Gtk2::Ex::Dialogs::text                                   = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::text                         = $value;
        $Gtk2::Ex::Dialogs::Message::text                          = $value;
        $Gtk2::Ex::Dialogs::Question::text                         = $value;
    } elsif ( $method eq 'set_icon' ) {
        $Gtk2::Ex::Dialogs::icon                                   = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::icon                         = $value;
        $Gtk2::Ex::Dialogs::Message::icon                          = $value;
        $Gtk2::Ex::Dialogs::Question::icon                         = $value;
    } elsif ( $method eq 'set_modal' ) {
        $Gtk2::Ex::Dialogs::modal                                  = $value;
        $Gtk2::Ex::Dialogs::ChooseDirectory::modal                 = $value;
        $Gtk2::Ex::Dialogs::ChooseFile::modal                      = $value;
        $Gtk2::Ex::Dialogs::ChoosePreviewFile::modal               = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::modal                        = $value;
        $Gtk2::Ex::Dialogs::Message::modal                         = $value;
        $Gtk2::Ex::Dialogs::Question::modal                        = $value;
    } elsif ( $method eq 'set_no_separator' ) {
        $Gtk2::Ex::Dialogs::no_separator                           = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::no_separator                 = $value;
        $Gtk2::Ex::Dialogs::Message::no_separator                  = $value;
        $Gtk2::Ex::Dialogs::Question::no_separator                 = $value;
    } elsif ( $method eq 'set_parent_window' ) {
        $Gtk2::Ex::Dialogs::parent_window                          = $value;
        $Gtk2::Ex::Dialogs::ChooseDirectory::parent_window         = $value;
        $Gtk2::Ex::Dialogs::ChooseFile::parent_window              = $value;
        $Gtk2::Ex::Dialogs::ChoosePreviewFile::parent_window       = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::parent_window                = $value;
        $Gtk2::Ex::Dialogs::Message::parent_window                 = $value;
        $Gtk2::Ex::Dialogs::Question::parent_window                = $value;
    } elsif ( $method eq 'set_destroy_with_parent' ) {
        $Gtk2::Ex::Dialogs::destroy_with_parent                    = $value;
        $Gtk2::Ex::Dialogs::ChooseDirectory::destroy_with_parent   = $value;
        $Gtk2::Ex::Dialogs::ChooseFile::destroy_with_parent        = $value;
        $Gtk2::Ex::Dialogs::ChoosePreviewFile::destroy_with_parent = $value;
        $Gtk2::Ex::Dialogs::ErrorMsg::destroy_with_parent          = $value;
        $Gtk2::Ex::Dialogs::Message::destroy_with_parent           = $value;
        $Gtk2::Ex::Dialogs::Question::destroy_with_parent          = $value;
    } elsif ( $method eq 'set_default_yes' ) {
        $Gtk2::Ex::Dialogs::default_yes                            = $value;
        $Gtk2::Ex::Dialogs::Question::default_yes                  = $value;
    } elsif ( $method eq 'set_must_exist' ) {
        $Gtk2::Ex::Dialogs::must_exist                             = $value;
        $Gtk2::Ex::Dialogs::ChooseDirectory::must_exist            = $value;
        $Gtk2::Ex::Dialogs::ChooseFile::must_exist                 = $value;
        $Gtk2::Ex::Dialogs::ChoosePreviewFile::must_exist          = $value;
    } else {
        croak( $class . " does not have a method called " . $AUTOLOAD . "()." );
    }

    return( $value );
}

=head1 NAME

Gtk2::Ex::Dialogs - Useful tools for Gnome2/Gtk2 Perl GUI design.

=head1 SYNOPSIS

 use Gtk2::Ex::Dialogs ( destroy_with_parent => TRUE,
                         modal => TRUE,
                         no_separator => FALSE );

 # do some stuff like creating your app's main $window then,
 # to ensure that all messages use the right parent, set it:
 Gtk2::Ex::Dialogs->set_parent_window( $window );

 # now popup a new dialog
 my $r = ask Gtk2::Ex::Dialogs::Question ( "Is Perl only hacker's glue?" );
 if ( $r ) {
   # end-user thinks so
 } else {
   # end-user does not think so
 }

 # now popup a new dialog ( blocking the main loop if there is one )
 new_and_run
  Gtk2::Ex::Dialogs::Message ( title => "Dialog Title",
                               text => "This is a simple message" );

 # now popup a new dialog ( blocking the main loop if there is one )
 new_and_run
  Gtk2::Ex::Dialogs::ErrorMsg ( "Simple error message." );

=head1 DESCRIPTION

This module provides the Gtk2::Ex::Dialogs::Message, Gtk2::Ex::Dialogs::ErrorMsg and
Gtk2::Ex::Dialogs::Question classes to the main application while setting the initial
defaults to those specified upon using Gtk2::Ex::Dialogs.

=head1 OPTIONS

Gtk2::Ex::Dialogs supports the following options:

=over

=item B<title> => STRING

The title of the dialog window. Defaults to an empty string.

=item B<text> => STRING

The text to be displayed. This is the core purpose of the module and is the
only mandatory argument.

=item B<icon> => /path/to/image || stock-id || Gtk2::Gdk::Pixbuf || Gtk2::Image

The dialog-sized image to place to the left of the text. Note: there are five
aliased stock-ids which correspond to the five gtk-dialog-* ids, "warning",
"question", "info", "error" and "authentication". Defaults to the stock-id
"gtk-dialog-question".

=item B<parent_window> => Gtk2::Window

Reference to the main application window.

=item B<destroy_with_parent> => BOOL

When the B<parent_window> is destroyed, what do we do? Defaults to FALSE.

=item B<modal> => BOOL

Does this message make the B<parent_window> freeze while the message exists.
Defaults to FALSE.

=item B<no_separator> => BOOL

Draw the horizontal separator between the content area and the button area
below. Defaults to FALSE.

=item B<default_yes> => BOOL

Autofocus on the "YES" button. Defaults to FALSE.

=item B<must_exist> => BOOL

The end-user must supply a path to an existing file or directory. Should the
end-user provide a non-existant path, the dialog will be respawned until an
existing file is chosen. Defaults to FALSE.

=back

=head1 FUNCTIONS

This module provides a "set_" function for all options that takes a signle
argument that is then used as the default for all three modules
Gtk2::Ex::Dialogs::Message, Gtk2::Ex::Dialogs::ErrorMsg and Gtk2::Ex::Dialogs::Question. For clarity,
the function names are as follows:

=over

=item Gtk2::Ex::Dialogs->set_title

=item Gtk2::Ex::Dialogs->set_text

=item Gtk2::Ex::Dialogs->set_icon

=item Gtk2::Ex::Dialogs->set_modal

=item Gtk2::Ex::Dialogs->set_parent_window

=item Gtk2::Ex::Dialogs->set_destroy_with_parent

=item Gtk2::Ex::Dialogs->set_default_yes

=item Gtk2::Ex::Dialogs->set_must_exist

=back

=cut

1;

__END__

=head1 SEE ALSO

 Gtk2::Dialog
 Gtk2::MessageDialog
 Gtk2::Ex::Dialogs::ChooseDirectory
 Gtk2::Ex::Dialogs::ChooseFile
 Gtk2::Ex::Dialogs::ChoosePreviewFile
 Gtk2::Ex::Dialogs::Message
 Gtk2::Ex::Dialogs::ErrorMsg
 Gtk2::Ex::Dialogs::Question

=head1 BUGS

Please report any bugs to the mailing list.

=head1 MAILING LIST

 http://odsgnulinux.com/lists/gtk2-ex-list
 gtk2-ex-list@odsgnulinux.com

=head1 AUTHORS

 Kevin C. Krinke, <kckrinke@opendoorsoftware.com>
 James Greenhalgh, <jgreenhalgh@opendoorsoftware.com>

=head1 COPYRIGHT AND LICENSE

 Gtk2::Ex::Dialogs - Useful tools for Gnome2/Gtk2 Perl GUI design.
 Copyright (C) 2005 Open Door Software Inc. <ods@opendoorsoftware.com>

 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA

=cut
