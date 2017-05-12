package MARC::Charset::Constants;

=head1 NAME 

MARC::Charset::Constants - constants for MARC::Charset

=head1 SYNOPSIS

    use MARC::Charset::Constants qw(:all);

=head1 DESCRIPTION

MARC::Charset needs to recognize various codes which are given 
descriptive names and assigned to constants in this package.

=cut

use strict;
use warnings;
use base qw( Exporter );

use constant ESCAPE		=> chr(0x1B);

use constant SINGLE_G0_A	=> chr(0x28);
use constant SINGLE_G0_B	=> chr(0x2C);
use constant MULTI_G0_A		=> chr(0x24);
use constant MULTI_G0_B		=> chr(0x24) . chr(0x2C);

use constant SINGLE_G1_A	=> chr(0x29);
use constant SINGLE_G1_B	=> chr(0x2D);
use constant MULTI_G1_A		=> chr(0x24) . chr(0x29);
use constant MULTI_G1_B		=> chr(0x24) . chr(0x2D);

use constant GREEK_SYMBOLS	=> chr(0x67);
use constant SUBSCRIPTS		=> chr(0x62);
use constant SUPERSCRIPTS	=> chr(0x70);
use constant ASCII_DEFAULT	=> chr(0x73);

use constant BASIC_ARABIC	=> chr(0x33);
use constant EXTENDED_ARABIC	=> chr(0x34);
use constant BASIC_LATIN	=> chr(0x42);
use constant EXTENDED_LATIN	=> chr(0x45);
use constant CJK		=> chr(0x31);
use constant BASIC_CYRILLIC	=> chr(0x4E);
use constant EXTENDED_CYRILLIC	=> chr(0x51);
use constant BASIC_GREEK	=> chr(0x53);
use constant BASIC_HEBREW	=> chr(0x32);

our %EXPORT_TAGS = ( all => [ qw( 
	ESCAPE  GREEK_SYMBOLS  SUBSCRIPTS  SUPERSCRIPTS  ASCII_DEFAULT
	SINGLE_G0_A  SINGLE_G0_B  MULTI_G0_A  MULTI_G0_B  SINGLE_G1_A 
	SINGLE_G1_B  MULTI_G1_A  MULTI_G1_B  BASIC_ARABIC  
	EXTENDED_ARABIC BASIC_LATIN EXTENDED_LATIN CJK  BASIC_CYRILLIC  
	EXTENDED_CYRILLIC BASIC_GREEK BASIC_HEBREW) ]);

our @EXPORT_OK = qw(
	ESCAPE  GREEK_SYMBOLS  SUBSCRIPTS  SUPERSCRIPTS ASCII_DEFAULT
	SINGLE_G0_A  SINGLE_G0_B  MULTI_G0_A  MULTI_G0_B  SINGLE_G1_A 
	SINGLE_G1_B  MULTI_G1_A  MULTI_G1_B  BASIC_ARABIC  
	EXTENDED_ARABIC BASIC_LATIN EXTENDED_LATIN CJK  BASIC_CYRILLIC  
	EXTENDED_CYRILLIC BASIC_GREEK BASIC_HEBREW);

sub charset_name
{
    my $charset = shift;
    return 'GREEK_SYMBOLS' if $charset eq GREEK_SYMBOLS;
    return 'SUBSCRIPTS' if $charset eq SUBSCRIPTS;
    return 'SUPERSCRIPTS' if $charset eq SUPERSCRIPTS;
    return 'ASCII_DEFAULT' if $charset eq ASCII_DEFAULT;
    return 'BASIC_ARABIC' if $charset eq BASIC_ARABIC;
    return 'EXTENDED_ARABIC' if $charset eq EXTENDED_ARABIC;
    return 'BASIC_LATIN' if $charset eq BASIC_LATIN;
    return 'EXTENDED_LATIN' if $charset eq EXTENDED_LATIN;
    return 'CJK' if $charset eq CJK;
    return 'BASIC_CYRILLIC' if $charset eq BASIC_CYRILLIC;
    return 'EXTENDED_CYRILLIC' if $charset eq EXTENDED_CYRILLIC;
    return 'BASIC_GREEK' if $charset eq BASIC_GREEK;
    return 'BASIC_HEBREW' if $charset eq BASIC_HEBREW;
}


1;
