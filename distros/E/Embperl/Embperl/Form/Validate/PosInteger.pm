
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


package Embperl::Form::Validate::PosInteger ;

use base qw(Embperl::Form::Validate::Integer);
use utf8 ;

my %errutf8 =
    (
	validate_pos_number => '"%0" muß eine Zahl größer oder gleich Null sein',
    ) ;

no utf8 ;

my %error_messages = 
(
    de => 
    {
	validate_pos_number => '"%0" mu� eine Zahl gr��er oder gleich Null sein',
    },

    'de.utf-8' => \%errutf8,

    en =>
    {
	validate_pos_number => '"%0" must be a number greater or equal zero',
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

# --------------------------------------------------------------

sub validate 
    {
    my ($self, $key, $value, $fdat, $pref) = @_ ;
    
    return $value =~ /^\s*[0-9+][0-9]*\s*$/ ? undef : ['validate_pos_number', $value] ;
    }

# --------------------------------------------------------------

sub getscript_validate 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('obj.value.search(/^\s*[0-9+][0-9]*\s*$/) >= 0', ['validate_pos_number', "'+obj.value+'"]) ;
    }



1;
