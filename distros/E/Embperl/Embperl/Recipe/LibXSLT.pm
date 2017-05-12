
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED 'AS IS' AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: LibXSLT.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################
 


package Embperl::Recipe::LibXSLT ;

use strict ;
use vars qw{@ISA} ;

use Embperl::Recipe::XSLT ;

@ISA = ('Embperl::Recipe::XSLT') ;

# ---------------------------------------------------------------------------------
#
#   Create a new recipe by converting request parameter
#
# ---------------------------------------------------------------------------------


sub get_recipe

    {
    my ($class, $r, $recipe) = @_ ;

    $r -> component -> config -> xsltproc ('libxslt') ;
    return  Embperl::Recipe::XSLT -> get_recipe ($r, $recipe) ;
    }


1 ;
