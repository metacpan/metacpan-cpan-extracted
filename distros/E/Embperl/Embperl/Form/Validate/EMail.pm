
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
#   $Id: EMail.pm 1578075 2014-03-16 14:01:14Z richter $
#
###################################################################################


package Embperl::Form::Validate::EMail ;

use base qw(Embperl::Form::Validate::Default);

my %error_messages = 
(
    de => 
    {
	validate_email => 'Die eingegebene E-Mail-Adresse "%0" in Feld "%1" ist ungültig, sie muß genau ein "@" enthalten und darf keine Leerzeichen, Klammern oder Umlaute enthalten.',
	validate_email_nomailto => 'Die eingegebene E-Mail-Adresse "%0" in Feld "%1" scheint mit einem "mailto:" zu beginnen. Bitte geben Sie nur eine E-Mail-Adresse ein und keine mit "mailto:" beginnende URL.',
    },

    'de.utf-8' => 
    {
	validate_email => 'Die eingegebene E-Mail-Adresse "%0" in Feld "%1" ist ungÃ¼ltig, sie muÃŸ genau ein "@" enthalten und darf keine Leerzeichen, Klammern oder Umlaute enthalten.',
	validate_email_nomailto => 'Die eingegebene E-Mail-Adresse "%0" in Feld "%1" scheint mit einem "mailto:" zu beginnen. Bitte geben Sie nur eine E-Mail-Adresse ein und keine mit "mailto:" beginnende URL.',
    },

    en =>
    {
	validate_email => 'The given e-mail address "%0" in field "%1" is not valid. It must have exactly one "@" and must not contain any blanks, parentheses or special charactes like umlauts.',  
	validate_email_nomailto => 'The given e-mail address "%0" in field "%1" seems to be prepended by "mailto:". Please enter only an e-mail address and no URL starting with "mailto:".',
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
    
    # The valid address "user@tld" or local addresses are not valid in this more general ruleset
    if ($value !~ /^[^ <>()@¡-ÿ]+@[^ <>()@¡-ÿ]+\.[a-zA-Z]{2,4}$/ or
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
    
    return ('((obj.value.search(/^[^ <>()@\x80-\xff]+@[^ <>()@\x80-\xff]+\.[a-zA-Z]{2,4}$/) >= 0) && (obj.value.search(/@(\.|.*(\.\.|@))|mailto:/i) < 0))', 
	    ['validate_email', "'+obj.value+'"]) ;
    }

1;
