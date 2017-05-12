package Gtk2::Ex::Utils;
###############################################################################
#  Gtk2::Ex::Utils - Extra Gtk2 Utilities for working with Gnome2/Gtk2 in Perl.
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
	use Exporter;
	use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );
	$VERSION = '0.09';
	@ISA = qw( Exporter );
	@EXPORT_OK = qw( );
    $EXPORT_TAGS{all}    = [ qw( ) ];
    $EXPORT_TAGS{main}   = [ qw( ) ];
    $EXPORT_TAGS{format} = [ qw( ) ];
    $EXPORT_TAGS{create} = [ qw( ) ];
}

use Gtk2;
use Gtk2::Ex::Constants qw( :all );

=head1 NAME

Gtk2::Ex::Utils - Extra Gtk2 Utilities for working with Gnome2/Gtk2 in Perl.

=head1 SYNOPSIS

 use Gtk2::Ex::Utils qw( :main );

 # do stuff
 ...

 # Update the UI and react to pending events
 process_pending_events();

 # do more stuff
 ...

 # Exit the program with a value of 255 for some reason
 process_main_exit( 255 );

=head1 DESCRIPTION

This module provides simple utility functions useful for Gnome2/Gtk2 Perl
programming.

=head1 EXPORT TAGS

=over

:all :main :alter :create

=back

=head1 FUNCTIONS BY TAG

=head2 B<:main>

=item B<process_pending_events> ( )

For all pending events, run through the main loop once. Useful for long
processes to update the user interface.

=cut

push( @EXPORT_OK,              'process_pending_events' );
push( @{ $EXPORT_TAGS{all}  }, 'process_pending_events' );
push( @{ $EXPORT_TAGS{main} }, 'process_pending_events' );
sub process_pending_events {
	while ( events_pending Gtk2 ) {
		main_iteration Gtk2;
	}
}

=item B<process_main_exit> ( [ EXIT_VALUE ] )

This will quit the main event loop after all pending events have been
given a run through the main loop one last time. Once the UI work is
done, exit with the value given or zero. Should the exit value passed
be the string 'no-exit', the function will return TRUE instead of
exiting.

=cut

push( @EXPORT_OK,              'process_main_exit' );
push( @{ $EXPORT_TAGS{all}  }, 'process_main_exit' );
push( @{ $EXPORT_TAGS{main} }, 'process_main_exit' );
sub process_main_exit {
    my $exit_value = $_[0] || '0';
	while ( events_pending Gtk2 ) {
		main_iteration Gtk2;
	}
    main_quit Gtk2;
    unless ( $exit_value =~ /^no\-exit$/i ) {
        $exit_value = '0' unless $exit_value =~ m!^\d+$!;
        exit( $exit_value );
    }
    return( TRUE );
}

=head2 :alter

=item DOUBLE = B<force_progress_bounds> ( DOUBLE )

Used with Gtk2 progress bars to ensure a given value is within the 0.00
to 1.00 bounds for valid percentages. This function will modify invalid
values appropriately to either 0.00 or 1.00 should the value be out of
bounds.

=cut

push( @EXPORT_OK,               'force_progress_bounds' );
push( @{ $EXPORT_TAGS{all}   }, 'force_progress_bounds' );
push( @{ $EXPORT_TAGS{alter} }, 'force_progress_bounds' );
sub force_progress_bounds {
    my $frac = $_[0] || return ( 0.00 );
    return( ( not $frac ) ? '0.00' :
            ( ( $frac > 1.00 ) ? 1.00 :
              ( ( $frac < 0.00 ) ? '0.00' : $frac ) ) );
}

=item Gtk2::Label = B<make_label_wrap_left_centred> ( Gtk2::Label )

Given a Gtk2::Label will center the alignment, left justify the text,
make the label selectable and make the label wrap lines.

=cut

push( @EXPORT_OK,               'make_label_wrap_left_centred' );
push( @{ $EXPORT_TAGS{all}   }, 'make_label_wrap_left_centred' );
push( @{ $EXPORT_TAGS{alter} }, 'make_label_wrap_left_centred' );
sub make_label_wrap_left_centred {
    my $label = $_[0] || return();
    $label->set_line_wrap( TRUE );
    $label->set_justify( J_LEFT );
    $label->set_alignment( A_CENTER, A_MIDDLE );
    $label->set_selectable( TRUE );
    return( $label );
}
push( @EXPORT_OK,                'make_label_wrap_left_centered' );
push( @{ $EXPORT_TAGS{all}    }, 'make_label_wrap_left_centered' );
push( @{ $EXPORT_TAGS{allter} }, 'make_label_wrap_left_centered' );
sub make_label_wrap_left_centered {
    my $label = $_[0] || return();
    $label->set_line_wrap( TRUE );
    $label->set_justify( J_LEFT );
    $label->set_alignment( A_CENTER, A_MIDDLE );
    $label->set_selectable( TRUE );
    return( $label );
}

=head2 :create

=item Gtk2::Button = B<create_mnemonic_icon_button> ( ICON, STRING )

This will create a new Gtk2::Button, a Gtk2::Image and a label then
pack the image and label into an hbox inside the button. The label
is new_with_mnemonic and the ICON given can be one of the following
types: a stock-id string, the path to an image file, a Gtk2::Image
object or a Gtk2::Gdk::Pixbuf object. The button has references to
the three components as follows: $button->{HBOX}, $button->{LABEL}
and $button->{IMAGE}.

=cut

push( @EXPORT_OK,                'create_mnemonic_icon_button' );
push( @{ $EXPORT_TAGS{all}    }, 'create_mnemonic_icon_button' );
push( @{ $EXPORT_TAGS{create} }, 'create_mnemonic_icon_button' );
sub create_mnemonic_icon_button {
    my ( $icon, $text ) = ( @_ );
    my $button = new Gtk2::Button;
    my $hbox = new Gtk2::HBox ( FALSE, 0 );
    $button->{HBOX} = $hbox;
    $button->add( $hbox );
    if ( $icon ) {
        my $image = undef;
        if ( ref( $icon ) eq "Gtk2::Gdk::Pixbuf" ) {
            $image = new_from_pixbuf Gtk2::Image ( $icon );
        } elsif ( ref( $icon ) eq "Gtk2::Image" ) {
            $image = $icon;
        } elsif ( -f $icon ) {
            $image = new_from_file Gtk2::Image ( $icon );
        } elsif ( $icon =~ /^gtk\-/ ) {
            $image = new_from_stock Gtk2::Image ( $icon, 'menu' );
        }
        unless ( not $image ) {
            $button->{IMAGE} = $image;
            $hbox->pack_start( $image, PACK_ZERO, PAD_WIDGET );
            $image->set_alignment( A_LEFT, A_MIDDLE );
        }
    }
    my $label = new_with_mnemonic Gtk2::Label ( $text );
    $button->{LABEL} = $label;
    $hbox->pack_start( $label, PACK_FILL, PAD_WIDGET );
    $label->set_mnemonic_widget( $button );
    $label->set_justify( J_RIGHT );
    $label->set_alignment( A_RIGHT, A_MIDDLE );
    return( $button );
}


1;

__END__

=head1 BUGS

 Please report all bugs to the mailing list.

=head1 CONTRIBUTE

If you've got a utility function that is related to Gnome2/Gtk2 Perl, that
is not already implemented in here and feel that others may benefit from
it's inclusion here, please do not hesitate to send it to the mailing list.

=head1 MAILING LIST

 http://opendoorsoftware.com/lists/gtk2-ex-list
 gtk2-ex-list@opendoorsoftware.com

=head1 AUTHORS

 Kevin C. Krinke, <kckrinke@opendoorsoftware.com>
 James Greenhalgh, <jgreenhalgh@opendoorsoftware.com>

=head1 COPYRIGHT AND LICENSE

 Gtk2::Ex::Utils - Useful utility functions for working with Gnome2/Gtk2 Perl.
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
