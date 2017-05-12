package Gtk2::Ex::Dialogs::Message;
###############################################################################
#  Gtk2::Ex::Dialogs::Message - Provides a simple message dialog.
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
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307 USA
###############################################################################
use strict;

BEGIN {
	use vars qw( $VERSION $parent_window $title $icon $text
                 $destroy_with_parent $modal $no_separator );
    $VERSION = '0.11';
}

use Carp;
use Gtk2;
use Glib;
use Gtk2::Ex::Utils     qw( :main :alter                      );
use Gtk2::Ex::Constants qw( :truth :pad :pack :align :justify );

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

    $Gtk2::Ex::Dialogs::Message::title               =
     $cfg->{title}               || '';
    $Gtk2::Ex::Dialogs::Message::text                =
     $cfg->{text}                || '';
    $Gtk2::Ex::Dialogs::Message::icon                =
     $cfg->{icon}                || '';
    $Gtk2::Ex::Dialogs::Message::modal               =
     $cfg->{modal}               || FALSE;
    $Gtk2::Ex::Dialogs::Message::no_separator        =
     $cfg->{no_separator}        || FALSE;
    $Gtk2::Ex::Dialogs::Message::parent_window       =
     $cfg->{parent_window}       || undef;
    $Gtk2::Ex::Dialogs::Message::destroy_with_parent =
     $cfg->{destroy_with_parent} || FALSE;
}


=head1 NAME

Gtk2::Ex::Dialogs::Message - Provides a simple message dialog.

=head1 SYNOPSIS

 use Gtk2::Ex::Dialogs::Message ( destroy_with_parent => TRUE,
                                  modal => TRUE,
                                  no_separator => FALSE );

 # do some stuff like creating your app's main $window then,
 # to ensure that all messages use the right parent, set it:
 $Gtk2::Ex::Dialogs::Message::parent_window = $window;

 # now popup a new dialog ( blocking the main loop if there is one )
 new_and_run
  Gtk2::Ex::Dialogs::Message ( title => "Dialog Title",
                               text => "This is a simple message" );

 # now popup a somwhat useful dialog that doesn't block any main loop
 # but on the other side of the coin, if there is no main loop the
 # dialog will be completely unresponsive.
 new_show
  Gtk2::Ex::Dialogs::Message ( title => "Uhm",
                               text => "Use when there is a main loop." );

=head1 DESCRIPTION

This module provides a simple dialog api that wraps Gtk2::Dialog objectively.
The objective is a clean and simple message dialog (only an "OK" button).

=head1 OPTIONS

All public methods (and the entire class) support the following options:

=over

=item B<title> => STRING

The title of the dialog window. Defaults to an empty string.

=item B<text> => STRING

The text to be displayed. This is the core purpose of the module and is the
only mandatory argument.

=item B<icon> => /path/to/image || stock-id || Gtk2::Gdk::Pixbuf || Gtk2::Image

The dialog-sized image to place to the left of the text. Note: there are five
aliased stock-ids which correspond to the five gtk-dialog-* ids, "warning",
"question", "info", "error" and "authentication". Defaults to no icon being
created at all.

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

=back

=head1 PUBLIC METHODS

=over

=item OBJECT = B<new> ( OPTIONS | STRING )

Create a new Gtk2::Dialog with only an "OK" button, some text and an optional
icon to the left of the text. The icon can be any of the following: a stock-id
string, a Gtk2::Image, Gtk2::Gdk::Pixbuf or the full path to an image. Return
a Gtk2::Ex::Dialogs::Message object. In the special case of being passed only
one argument, all options are set to defaults and the one argument is used as
the B<text> option.

=back

=cut

sub new {
    my $proto = shift();
    my $class = ref($proto) || $proto;
    my $cfg = undef;

	if ( @_ % 2 == 0 ) {
        $cfg = { @_ };
    } elsif ( @_ == 1 ) {
        $cfg = { text => $_[0] };
    } else {
        $cfg = {};
    }

    croak( $class . " will not create a dialog without a message." )
     unless $cfg && $cfg->{text};

    my $self = { CFG => $cfg };
    bless($self, $class);

	$cfg->{title}               ||= $Gtk2::Ex::Dialogs::Message::title;
	$cfg->{text}                ||= $Gtk2::Ex::Dialogs::Message::text;
	$cfg->{icon}                ||= $Gtk2::Ex::Dialogs::Message::icon;
	$cfg->{parent_window}       ||= $Gtk2::Ex::Dialogs::Message::parent_window;
	$cfg->{destroy_with_parent} ||= $Gtk2::Ex::Dialogs::Message::destroy_with_parent;
	$cfg->{modal}               ||= $Gtk2::Ex::Dialogs::Message::modal;
	$cfg->{no_separator}        ||= $Gtk2::Ex::Dialogs::Message::no_separator;

	my $flags = [];
	push( @{ $flags }, 'destroy-with-parent' ) if $cfg->{destroy_with_parent};
	push( @{ $flags }, 'modal'               ) if $cfg->{modal};
	push( @{ $flags }, 'no-separator'        ) if $cfg->{no_separator};

	$self->{dialog} = new Gtk2::Dialog ( $cfg->{title},
										 $cfg->{parent_window},
										 $flags,
										 'gtk-ok' => 'accept' );

	$self->{hbox} = new Gtk2::HBox ( FALSE, 0 );
	$self->{dialog}->vbox->pack_start( $self->{hbox}, PACK_GROW, PAD_WIDGET );

    if ( $cfg->{icon} ) {
        $self->{icon} = undef;
        my $ICON_ALIASES = 'question|warning|error|info|authentication';
        if ( ref( $cfg->{icon} ) eq "Gtk2::Gdk::Pixbuf" ) {
            $self->{icon} = new_from_pixbuf Gtk2::Image ( $cfg->{icon} );
        } elsif ( ref( $cfg->{icon} ) eq "Gtk2::Image" ) {
            $self->{icon} = $cfg->{icon};
        } elsif ( -f $cfg->{icon} ) {
            $self->{icon} = new_from_file Gtk2::Image ( $cfg->{icon} );
        } elsif ( $cfg->{icon} =~ /^gtk\-|$ICON_ALIASES/ ) {
            $cfg->{icon} = 'gtk-dialog-' . $cfg->{icon}
             unless $cfg->{icon} =~ /^gtk\-/;
            $self->{icon} = new_from_stock Gtk2::Image ( $cfg->{icon}, 'dialog' );
        }
        unless ( not $self->{icon} ) {
            $self->{hbox}->pack_start( $self->{icon}, PACK_ZERO, PAD_WIDGET );
            $self->{icon}->set_alignment( A_LEFT, A_MIDDLE );
        }
    }

	$self->{label} = new Gtk2::Label;
    make_label_wrap_left_centred( $self->{label} );
	$self->{label}->set_markup( $cfg->{text} );
	$self->{hbox}->pack_start( $self->{label}, PACK_GROW, PAD_WIDGET );

	return( $self );
}

=over

=item B<new_and_run> ( OPTIONS )

Supports all the same arguments as new(). This will create a new
Gtk2::Ex::Dialogs::Message, show_all(), run() and then destroy the dialog immediately.

=back

=cut

sub new_and_run {
	my $class = shift();
	my $run = new Gtk2::Ex::Dialogs::Message ( @_ );
	$run->dialog->show_all();
	$run->dialog->run();
	$run->dialog->destroy();
}

=over

=item B<new_and_show> ( OPTIONS )

Supports all the same arguments as new(). This will create a new
Gtk2::Ex::Dialogs::Message, show_all() and process any pending gtk events. This
functionality is only of any practical use when there is a Gtk2 main loop
running. If there is no main loop running the dialog will be visible but
completely unresponsive to the end-user.

=back

=cut

sub new_and_show {
	my $class = shift();
	my $show = new Gtk2::Ex::Dialogs::Message ( @_ );
	$show->dialog->signal_connect( response => sub { $_[0]->destroy(); } );
	$show->dialog->signal_connect( 'delete-event' => sub { $_[0]->destroy(); } );
	$show->dialog->show_all();
    process_pending_events();
}

#
# PRIVATE METHODS
#

sub dialog { return( $_[0]->{dialog} ); }

1;

__END__

=head1 SEE ALSO

 Gtk2::Dialog
 Gtk2::MessageDialog
 Gtk2::Ex::Dialogs
 Gtk2::Ex::Dialogs::ChooseDirectory
 Gtk2::Ex::Dialogs::ChooseFile
 Gtk2::Ex::Dialogs::ChoosePreviewFile
 Gtk2::Ex::Dialogs::ErrorMsg
 Gtk2::Ex::Dialogs::Message

=head1 BUGS

Please report any bugs to the mailing list.

=head1 MAILING LIST

 http://opendoorsoftware.com/lists/gtk2-ex-list
 gtk2-ex-list@opendoorsoftware.com

=head1 AUTHORS

 Kevin C. Krinke, <kckrinke@opendoorsoftware.com>
 James Greenhalgh, <jgreenhalgh@opendoorsoftware.com>

=head1 COPYRIGHT AND LICENSE

 Gtk2::Ex::Dialogs::Message - Provides a simple message dialog.
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
