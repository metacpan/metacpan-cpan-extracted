
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
#   $Id: IPAddr.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Form::Validate::IPAddr ;

use base qw(Embperl::Form::Validate::Default);

my %error_messages = 
(
    de => 
    {
	validate_ipaddr => 'Feld %0: "%1" ist keine gültige IP-Adresse. Geben Sie die IP-Adresse in der Form nnn.nnn.nnn.nnn ein',
    },

    'de.utf-8' => 
    {
	validate_ipaddr => 'Feld %0: "%1" ist keine gÃ¼ltige IP-Adresse. Geben Sie die IP-Adresse in der Form nnn.nnn.nnn.nnn ein',
    },

    en =>
    {
	validate_ipaddr => 'Field %0: "%1" isn\\\'t a valid ip-address. Please enter the ip-address as nnn.nnn.nnn.nnn',
    }
 );

# --------------------------------------------------------------

sub getmsg
    {
    my ($self, $id, $language, $default_language) = @_ ;

    return $error_messages{$language}{$id} || 
           $error_messages{$default_language}{$id} ||
           $self -> SUPER::getmsg ($id, $language, $default_language) ;
    }


# --------------------------------------------------------------

sub validate 
    {
    my ($self, $key, $value, $fdat, $pref) = @_ ;
    
    if ($value =~ /^(\d+)\.(\d+).(\d+)\.(\d+)$/)
	{
	if ($1 < 0 || $1 > 255 ||
	    $2 < 0 || $2 > 255 ||
	    $3 < 0 || $3 > 255 ||
	    $4 < 0 || $4 > 255)
	    {
            return ['validate_ipaddr', $value] ;		
	    }
	return undef ;
	}
    return ['validate_ipaddr', $value] ; 
    }

# --------------------------------------------------------------

sub getscript_validate 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('obj.value.search(/^\d+\.\d+.\d+.\d+$/) >= 0', ['validate_ipaddr', "'+obj.value+'"]) ;
    }


1;
