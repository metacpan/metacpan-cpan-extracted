
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: Select.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Form::Validate::Select ;

use base qw(Embperl::Form::Validate::Default);


# --------------------------------------------------------------

sub getscript_required
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('obj.selectedIndex != 0', ['validate_required']) ;
    }


1;

