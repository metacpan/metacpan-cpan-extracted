package Glade::Two::Gnome;
require 5.000; use strict 'vars', 'refs', 'subs';

# Copyright (c) 1999 Dermot Musgrove <dermot.musgrove@virgin.net>
#
# This library is released under the same conditions as Perl, that
# is, either of the following:
#
# a) the GNU General Public License as published by the Free
# Software Foundation; either version 1, or (at your option) any
# later version.
#
# b) the Artistic License.
#
# If you use this library in a commercial enterprise, you are invited,
# but not required, to pay what you feel is a reasonable fee to perl.org
# to ensure that useful software is available now and in the future. 
#
# (visit http://www.perl.org/ or email donors@perlmongers.org for details)

BEGIN {
    use Exporter    qw( );
    use Glade::Two::Source qw( :VARS :METHODS);
    use vars              qw( 
                            $PACKAGE $VERSION $AUTHOR $DATE
                            $enums
                         );
    # These cannot be looked up in the include files
    $enums =      {
        'GNOME_MENU_SAVE_AS_STRING'     => 'Save _As...',
    };
    $PACKAGE      = __PACKAGE__;
    $VERSION      = q(0.01);
    $AUTHOR       = q(Dermot Musgrove <dermot.musgrove@virgin.net>);
    $DATE         = q(Sun Nov 17 06:02:01 GMT 2002 );
}

sub DESTROY {
    # This sub will be called on object destruction
} # End of sub DESTROY

#===============================================================================
#==== This is just a placeholder for the future Gnome widget constructors
#===============================================================================

1;

__END__

