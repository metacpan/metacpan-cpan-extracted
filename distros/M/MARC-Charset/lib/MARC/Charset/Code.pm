package MARC::Charset::Code;

use strict;
use warnings;
use base qw(Class::Accessor);
use Carp qw(croak);
use Encode qw(encode_utf8);
use MARC::Charset::Constants qw(:all);

MARC::Charset::Code
    ->mk_accessors(qw(marc ucs name charset is_combining alt
                      marc_right_half marc_left_half));

=head1 NAME

MARC::Charset::Code - represents a MARC-8/UTF-8 mapping

=head1 SYNOPSIS

=head1 DESCRIPTION

Each mapping from a MARC-8 value to a UTF-8 value is represented by 
a MARC::Charset::Code object in a MARC::Charset::Table.

=head1 METHODS 

=head2 new()

The constructor.

=head2 name()

A descriptive name for the code point.

=head2 marc()

A string representing the MARC-8 bytes codes.

=head2 ucs()

A string representing the UCS code point in hex.

=head2 charset_code()

The MARC-8 character set code.

=head2 is_combining()

Returns true/false to tell if the character is a combining character.

=head2 marc_left_half()

If the character is the right half of a "double diacritic", returns
a hex string representing the MARC-8 value of the left half.

=head2 marc_right_half()

If the character is the left half of a "double diacritic", returns
a hex string representing the MARC-8 value of the right half.

=head2 to_string()

A stringified version of the object suitable for pretty printing.

=head2 char_value()

Returns the unicode character. Essentially just a helper around
ucs().

=cut

sub char_value
{
    return chr(hex(shift->ucs()));
}

=head2 g0_marc_value()

The string representing the MARC-8 encoding
for lookup.

=cut

sub g0_marc_value
{
    my $code = shift;
    my $marc = $code->marc();
    if ($code->charset_name eq 'CJK') {
        return 
            chr(hex(substr($marc,0,2))) .
            chr(hex(substr($marc,2,2))) .
            chr(hex(substr($marc,4,2)));
    } else {
         return chr(hex($marc));
    }
}

=head2 marc_value()

The string representing the MARC-8 encodingA
for output.

=cut

sub marc_value
{
    my $code = shift;
    my $marc = $code->marc();
    if ($code->charset_name eq 'CJK') {
        return 
            chr(hex(substr($marc,0,2))) .
            chr(hex(substr($marc,2,2))) .
            chr(hex(substr($marc,4,2)));
    } else {
        if ($code->default_charset_group() eq 'G0') {
            return chr(hex($marc));
        } else {
            return chr(hex($marc) + 128);
        }
    }
}


=head2 charset_name()

Returns the name of the character set, instead of the code.

=cut

sub charset_name
{
    return MARC::Charset::Constants::charset_name(shift->charset_value());
}

=head2 to_string()

Returns a stringified version of the object.

=cut

sub to_string
{
    my $self = shift;
    my $str = 
        $self->name() . ': ' .
        'charset_code=' . $self->charset() . ' ' .
        'marc='         . $self->marc() . ' ' . 
        'ucs='          . $self->ucs() .  ' ';

    $str .= ' combining' if $self->is_combining();
    return $str;
}


=head2 marc8_hash_code()

Returns a hash code for this Code object for looking up the object using
MARC8. First portion is the character set code and the second is the 
MARC-8 value.

=cut

sub marc8_hash_code 
{
    my $self = shift;
    return sprintf('%s:%s', $self->charset_value(), $self->g0_marc_value());
}


=head2 utf8_hash_code()

Returns a hash code for uniquely identifying a Code by it's UCS value.

=cut 

sub utf8_hash_code
{
    return int(hex(shift->ucs()));
}


=head2 default_charset_group

Returns 'G0' or 'G1' indicating where the character is typicalling used 
in the MARC-8 environment.

=cut

sub default_charset_group
{
    my $charset = shift->charset_value();

    return 'G0'
        if $charset eq ASCII_DEFAULT 
            or $charset eq GREEK_SYMBOLS
            or $charset eq SUBSCRIPTS
            or $charset eq SUPERSCRIPTS
            or $charset eq BASIC_LATIN
            or $charset eq BASIC_ARABIC
            or $charset eq BASIC_CYRILLIC
            or $charset eq BASIC_GREEK
            or $charset eq BASIC_HEBREW
            or $charset eq CJK;

    return 'G1';
}


=head2 get_marc8_escape

Returns an escape sequence to move to the Code from another marc-8 character
set.

=cut

sub get_escape 
{
    my $charset = shift->charset_value();

    return ESCAPE . $charset
        if $charset eq ASCII_DEFAULT 
            or $charset eq GREEK_SYMBOLS
            or $charset eq SUBSCRIPTS
            or $charset eq SUPERSCRIPTS;

    return ESCAPE . SINGLE_G0_A . $charset
        if $charset eq ASCII_DEFAULT
            or $charset eq BASIC_LATIN
            or $charset eq BASIC_ARABIC
            or $charset eq BASIC_CYRILLIC
            or $charset eq BASIC_GREEK
            or $charset eq BASIC_HEBREW;

    return ESCAPE . SINGLE_G1_A . $charset
        if $charset eq EXTENDED_ARABIC
            or $charset eq EXTENDED_LATIN
            or $charset eq EXTENDED_CYRILLIC;

    return ESCAPE . MULTI_G0_A . CJK
        if $charset eq CJK;
}

=head2 charset_value

Returns the charset value, not the hex sequence.

=cut

sub charset_value
{
    return chr(hex(shift->charset()));
}



1;
