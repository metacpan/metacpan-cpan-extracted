
###################################################################################
#
#   Embperl  - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl  - Copyright (c) 2008-2014 Gerald Richter
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
#   $Id: EMailRFC.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Form::Validate::EMailRFC ;

use base qw(Embperl::Form::Validate::EMail);

# --------------------------------------------------------------

sub validate 
    {
    my ($self, $key, $value, $fdat, $pref) = @_ ;
    
    # The valid address "user@tld" or local addresses are valid in this RFC conforming ruleset
    if ($value !~ /^[^ <>()@¡-ÿ]+@[^ <>()@¡-ÿ]+$/ or
	$value =~ /@(\.|.*(\.\.|@))/)
	{
	return ['validate_email', $value, $key] ;
	}

    if ($value =~ /^mailto:/i)
	{
	return ['validate_email_nomailto', $value, $key] ;
	}

    return undef ;
    }

# --------------------------------------------------------------

sub getscript_validate 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('((obj.value.search(/^[^ <>()@¡-ÿ]+@[^ <>()@¡-ÿ]+$/) >= 0) && (obj.value.search(/@(\.|.*(\.\.|@))|mailto:/i) < 0))', 
	    ['validate_email', "'+obj.value+'"]) ;
    }

1;
