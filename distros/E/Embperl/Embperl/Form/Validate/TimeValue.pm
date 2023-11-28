
###################################################################################
#
#   Embperl - Copyright (c) 1997-2008 Gerald Richter / ecos gmbh  www.ecos.de
#   Embperl - Copyright (c) 2008-2015 Gerald Richter
#   Embperl - Copyright (c) 2015-2023 actevy.io
#
#   You may distribute under the terms of either the GNU General Public
#   License or the Artistic License, as specified in the Perl README file.
#
#   THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR
#   IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
#   WARRANTIES OF MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
#
###################################################################################


package Embperl::Form::Validate::TimeValue ;

use base qw(Embperl::Form::Validate::Integer);
use utf8 ;

my %errutf8 =
    (
	validate_time_long => 'Feld %0: "%1" ist kein gÃ¼ltiges Zeitformat. Geben Sie die Zeit in der Form hh:mm:ss ein',
    ) ;

no utf8 ;

my %error_messages = 
(
    de => 
    {
	validate_timevalue => 'Feld %0: "%1" ist keine gültige Zeit. Geben Sie eine Zahl gefolgt von s, m, h, d oder w ein.',
    },

    'de.utf-8' => \%errutf8,

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
