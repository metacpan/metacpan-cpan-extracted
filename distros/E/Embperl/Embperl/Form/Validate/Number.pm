
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


package Embperl::Form::Validate::Number ;

use base qw(Embperl::Form::Validate::Default);
use utf8 ;

my
$VERSION = '3.0.1' ;

my %errutf8 =
    (
	validate_number => '"%0" muÃŸ eine Zahl sein',
    ) ;

no utf8 ;

my %error_messages = 
(
    de => 
    {
	validate_number => '"%0" muß eine Zahl sein',
    },

    'de.utf-8' => \%errutf8,

    en =>
    {
	validate_number => '"%0" must be a number',
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
    
    return $value =~ /^\s*[0-9+-.,][0-9.,eE]*\s*$/ ? undef : ['validate_number', $value] ;
    }

# --------------------------------------------------------------

sub getscript_validate 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ('obj.value.search(/^\s*[0-9+-.,][0-9.,eE]*\s*$/) >= 0', ['validate_number', "'+obj.value+'"]) ;
    }

# --------------------------------------------------------------

sub validate_eq 
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value == $arg ? undef : ['validate_eq', $value, $arg] ;
    }

# --------------------------------------------------------------

sub getscript_eq 
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value == $arg", ['validate_eq', "+'obj.value'+", $arg]) ;
    }

# --------------------------------------------------------------

sub validate_gt
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value > $arg ? undef : ['validate_gt', $value, $arg] ;
    }

# --------------------------------------------------------------

sub getscript_gt
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value > $arg", ['validate_gt', "+'obj.value'+", $arg]) ;
    }

# --------------------------------------------------------------

sub validate_lt
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value < $arg ? undef : ['validate_lt', $value, $arg] ;
    }

# --------------------------------------------------------------

sub getscript_lt
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value < $arg", ['validate_lt', "+'obj.value'+", $arg]) ;
    }

# --------------------------------------------------------------

sub validate_ge
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value >= $arg ? undef : ['validate_ge', $value, $arg] ;
    }

# --------------------------------------------------------------

sub getscript_ge
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value >= $arg", ['validate_ge', "+'obj.value'+", $arg]) ;
    }

# --------------------------------------------------------------

sub validate_le
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value <= $arg ? undef : ['validate_le', $value, $arg] ;
    }


# --------------------------------------------------------------

sub getscript_le
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value <= $arg", ['validate_le', "+'obj.value'+", $arg]) ;
    }

# --------------------------------------------------------------

sub validate_ne
    {
    my ($self, $key, $value, $arg, $fdat, $pref) = @_ ;
    
    return $value != $arg ? undef : ['validate_ne', $value, $arg] ;
    }

# --------------------------------------------------------------

sub getscript_ne
    {
    my ($self, $arg, $pref) = @_ ;
    
    return ("obj.value != $arg", ['validate_ne', "+'obj.value'+", $arg]) ;
    }


1;
