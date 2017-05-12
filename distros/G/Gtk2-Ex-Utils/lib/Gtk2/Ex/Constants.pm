package Gtk2::Ex::Constants;
use strict;
###############################################################################
#  Gtk2::Constants - Useful constants for working with Gnome2/Gtk2 Perl.
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

=head1 NAME

Gtk2 Ex Constants - Extra Constants for working with Gnome2/Gtk2 in Perl.

=head1 SYNOPSIS

 # import only the PACKing and PADing constants
 use Gtk2::Constants qw( :pack :pad );

=head1 DESCRIPTION

This module provides many constant values for specific aspects of working with
Gnome2/Gtk2 Perl. The main purpose of these constants (aside from unified values)
is to aide in the creation of human readable code that follows consistent
naming conventions.

=cut

BEGIN {
	use Exporter;
	use vars qw( $VERSION @ISA @EXPORT_OK %EXPORT_TAGS );
	$VERSION = '0.08';
	@ISA = qw( Exporter );
	@EXPORT_OK = qw( TRUE FALSE
					 PAD_EDGE PAD_WIDGET PAD_ZERO
					 PACK_EXPAND PACK_FILL PACK_ZERO PACK_GROW
					 A_LEFT A_CENTRE A_CENTER A_RIGHT A_TOP A_MIDDLE A_BOTTOM
					 J_LEFT J_CENTRE J_CENTER J_RIGHT J_FILL
					 P_ALWAYS P_AUTO P_NEVER
				   );

	$EXPORT_TAGS{truth}   = [ qw( TRUE FALSE ) ];
	$EXPORT_TAGS{pad}     = [ qw( PAD_EDGE PAD_WIDGET PAD_ZERO ) ];
	$EXPORT_TAGS{pack}    = [ qw( PACK_EXPAND PACK_FILL PACK_ZERO PACK_GROW ) ];
	$EXPORT_TAGS{align}   = [ qw( A_LEFT A_CENTER A_RIGHT
								  A_TOP A_MIDDLE A_BOTTOM ) ];
	$EXPORT_TAGS{justify} = [ qw( J_LEFT J_CENTER J_RIGHT J_FILL ) ];
	$EXPORT_TAGS{policy}  = [ qw( P_NEVER P_AUTO P_ALWAYS ) ];

	$EXPORT_TAGS{all}     = [ qw( TRUE FALSE
							      PAD_EDGE PAD_WIDGET PAD_ZERO
							      PACK_EXPAND PACK_FILL PACK_ZERO PACK_GROW
							      A_LEFT A_CENTER A_RIGHT
                                  A_TOP A_MIDDLE A_BOTTOM
							      J_LEFT J_CENTER J_RIGHT J_FILL
							      P_ALWAYS P_AUTO P_NEVER
							    )
                            ];
}

=head1 EXPORT TAGS

=over

:all :truth :pad :pack :align :justify :policy

=back

=head1 CONSTANTS BY TAG

=head2 :truth

=over

=item B<TRUE> = 1

=item B<FALSE> = 0

=back

=cut

use constant TRUE => 1;
use constant FALSE => 0;

=head2 :pad

=over

=item B<PAD_EDGE> = 12

=item B<PAD_WIDGET> = 8

=item B<PAD_ZERO> = 0

=back

=cut

use constant PAD_EDGE => 12;
use constant PAD_WIDGET => 6;
use constant PAD_ZERO => 0;

=head2 :pack

=over

=item B<PACK_EXPAND> = ( 1, 0 )

=item B<PACK_FILL> = ( 0, 1 )

=item B<PACK_ZERO> = ( 0, 0 )

=item B<PACK_GROW> = ( 1, 1 )

=back

=cut

use constant PACK_EXPAND => ( 1, 0 );
use constant PACK_FILL => ( 0, 1 );
use constant PACK_ZERO => ( 0, 0 );
use constant PACK_GROW => ( 1, 1 );

=head2 :align

=over

=item B<A_LEFT> = 0.00

=item B<A_CENTRE> = 0.50

=item B<A_RIGHT> = 1.00

=item B<A_TOP> = 0.00

=item B<A_MIDDLE> = 0.50

=item B<A_BOTTOM> = 1.00

=back

=cut

use constant A_LEFT => 0.00;
use constant A_CENTRE => 0.50;
use constant A_CENTER => 0.50;
use constant A_RIGHT => 1.00;
use constant A_TOP => 0.00;
use constant A_MIDDLE => 0.50;
use constant A_BOTTOM => 1.00;

=head2 :justify

=over

=item B<J_LEFT> = 'left'

=item B<J_CENTRE> = 'center'

=item B<J_RIGHT> = 'right'

=item B<J_FILL> = 'fill'

=back

=cut

use constant J_LEFT => 'left';
use constant J_CENTRE => 'center';
use constant J_CENTER => 'center';
use constant J_RIGHT => 'right';
use constant J_FILL => 'fill';

=head2 :policy

=over

=item B<P_ALWAYS> = 'always'

=item B<P_AUTO> = 'automatic'

=item B<P_NEVER> = 'never'

=back

=cut

use constant P_ALWAYS => 'always';
use constant P_AUTO => 'automatic';
use constant P_NEVER => 'never';

1;

__END__

=head1 BUGS

Please report any bugs to the mailing list.

=head1 CONTRIBUTE

If you've got constants that are related to Gnome2/Gtk2 Perl, that
are not already implemented in here and feel that others may benefit from
their inclusion here, please do not hesitate to send them to the mailing list.

=head1 MAILING LIST

 http://opendoorsoftware.com/lists/gtk2-ex-list
 gtk2-ex-list@opendoorsoftware.com

=head1 AUTHORS

 Kevin C. Krinke, <kckrinke@opendoorsoftware.com>
 James Greenhalgh, <jgreenhalgh@opendoorsoftware.com>

=head1 COPYRIGHT AND LICENSE

 Gtk2::Ex::Constants - Useful constants for working with Gnome2/Gtk2 Perl.
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
