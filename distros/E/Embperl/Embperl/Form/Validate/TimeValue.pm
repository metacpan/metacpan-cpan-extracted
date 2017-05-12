
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
#   $Id: Integer.pm,v 1.3 2004/01/23 06:50:57 richter Exp $
#
###################################################################################


package Embperl::Form::Validate::TimeValue ;

use base qw(Embperl::Form::Validate::Integer);

my %error_messages = 
(
    de => 
    {
	validate_timevalue => 'Feld %0: "%1" ist keine gültige Zeit. Geben Sie eine Zahl gefolgt von s, m, h, d oder w ein.',
    },

    'de.utf-8' => 
    {
	validate_timevalue => 'Feld %0: "%1" ist keine gÃ¼ltige Zeit. Geben Sie eine Zahl gefolgt von s, m, h, d oder w ein.',
    },

    en =>
    {
	validate_timevalue => 'Field %0: "%1" isn\\\'t a valid time value. Please enter a number followed by s, m, h, d or w.',
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
    
    return $value =~ /^\s*[0-9+][0-9]*(?:s|m|h|d|w)\s*$/ ? undef : ['validate_timevalue', $value] ;
    }

# --------------------------------------------------------------

sub getscript_validate 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('obj.value.search(/^\s*[0-9+][0-9]*(?:s|m|h|d|w)\s*$/) >= 0', ['validate_timevalue', "'+obj.value+'"]) ;
    }



1;
