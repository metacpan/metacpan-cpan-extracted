package Lingua::JA::Jtruncate;
$Lingua::JA::Jtruncate::VERSION = '0.022';
#------------------------------------------------------------------------------
#
# Start of POD
#
#------------------------------------------------------------------------------

=head1 NAME

Lingua::JA::Jtruncate - module to truncate Japanese encoded text.

=head1 SYNOPSIS

    use Lingua::JA::Jtruncate qw( jtruncate );
    $truncated_jtext = jtruncate( $jtext, $length );

=head1 DESCRIPTION

The jtruncate function truncates text to a length $length less than bytes. It
is designed to cope with Japanese text which has been encoded using one of the
standard encoding schemes - EUC, JIS, and Shift-JIS.
It uses the L<Jcode> module to detect what encoding is being used.
If the text is none of the above Japanese encodings,
the text is just truncated using substr.
If it is detected as Japanese text, it tries to truncate the text as well as
possible without breaking the multi-byte encoding.  It does this by detecting
the character encoding of the text, and recursively deleting Japanese (possibly
multi-byte) characters from the end of the text until it is underneath the
length specified. It should work for EUC, JIS and Shift-JIS encodings.

=head1 FUNCTIONS

=head2 jtruncate( $jtext, $length )

B<jtruncate> takes some japanese text and a byte length as arguments, and
returns the japanese text truncated to that byte length.

    $truncated_jtext = jtruncate( $jtext, $length );

=head1 SEE ALSO

L<Jcode>

=head1 REPOSITORY

L<https://github.com/neilb/HTML-Summary>

=head1 AUTHOR

Originally written by Ave Wrigley (AWRIGLEY),
now maintained by Neil Bowers (NEILB).

=head1 COPYRIGHT

Copyright (c) 1997 Canon Research Centre Europe (CRE). All rights reserved.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

#------------------------------------------------------------------------------
#
# End of POD
#
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
#
# Pragmas
#
#------------------------------------------------------------------------------

require 5.006;
use strict;
use warnings;

#==============================================================================
#
# Modules
#
#==============================================================================

# use Lingua::JA::Jcode;
use Jcode;
require Exporter;

#==============================================================================
#
# Public globals
#
#==============================================================================

use vars qw( 
    @ISA 
    @EXPORT_OK 
    %euc_code_set
    %sjis_code_set
    %jis_code_set
    %char_re
);

@ISA = qw( Exporter );
@EXPORT_OK = qw( jtruncate );

%euc_code_set = (
    ASCII_JIS_ROMAN     => '[\x00-\x7f]',
    JIS_X_0208_1997     => '[\xa1-\xfe][\xa1-\xfe]',
    HALF_WIDTH_KATAKANA => '\x8e[\xa0-\xdf]',
    JIS_X_0212_1990     => '\x8f[\xa1-\xfe][\xa1-\xfe]',
);

%sjis_code_set = (
    ASCII_JIS_ROMAN     => '[\x21-\x7e]',
    HALF_WIDTH_KATAKANA => '[\xa1-\xdf]',
    TWO_BYTE_CHAR       => '[\x81-\x9f\xe0-\xef][\x40-\x7e\x80-\xfc]',
);

%jis_code_set = (
    TWO_BYTE_ESC        => 
        '(?:' .
        join( '|',
            '\x1b\x24\x40',
            '\x1b\x24\x42',
            '\x1b\x26\x40\x1b\x24\x42',
            '\x1b\x24\x28\x44',
        ) .
        ')'
    ,
    TWO_BYTE_CHAR       => '(?:[\x21-\x7e][\x21-\x7e])',
    ONE_BYTE_ESC        => '(?:\x1b\x28[\x4a\x48\x42\x49])',
    ONE_BYTE_CHAR       =>
        '(?:' .
        join( '|', 
            '[\x21-\x5f]',                      # JIS7 Half width katakana
            '\x0f[\xa1-\xdf]*\x0e',             # JIS8 Half width katakana
            '[\x21-\x7e]',                      # ASCII / JIS-Roman
        ) .
        ')'
);

%char_re = (
    'euc'       => '(?:' . join( '|', values %euc_code_set ) . ')',
    'sjis'      => '(?:' . join( '|', values %sjis_code_set ) . ')',
    'jis'       => '(?:' . join( '|', values %jis_code_set ) . ')',
);

#==============================================================================
#
# Public exported functions
#
#==============================================================================

#------------------------------------------------------------------------------
#
# jtruncate( $text, $length )
#
# truncate a string safely (i.e. don't break japanese encoding)
#
#------------------------------------------------------------------------------

sub jtruncate
{
    my $text            = shift;
    my $length          = shift;

    # sanity checks

    return '' if $length == 0;
    return undef if not defined $length;
    return undef if $length < 0;
    return $text if length( $text ) <= $length;

    # save the original text, in case we need to bomb out with a substr

    my $orig_text = $text;

    my $encoding = Jcode::getcode( \$text );
    if ( not defined $encoding or $encoding !~ /^(?:euc|s?jis)$/ )
    {

        # not euc/sjis/jis - just use substr

        return substr( $text, 0, $length );
    }

    $text = chop_jchars( $text, $length, $encoding );
    return substr( $orig_text, 0, $length ) unless defined $text;

    # JIS encoding uses escape sequences to shift in and out of single-byte /
    # multi-byte  modes. If the truncation process leaves the text ending in
    # multi-byte mode, we need to add the single-byte escape sequence.
    # Therefore, we truncate (at least) 3 more bytes from JIS encoded
    # string, so we have room to add the single-byte escape sequence without
    # going over the $length limit

    if ( $encoding eq 'jis' and $text =~ /$jis_code_set{ TWO_BYTE_CHAR }$/ )
    {
        $text = chop_jchars( $text, $length - 3, $encoding );
        return substr( $orig_text, 0, $length ) unless defined $text;
        $text .= "\x1b\x28\x42";
    }
    return $text;
}

sub chop_jchars
{
    my $text = shift;
    my $length = shift;
    my $encoding = shift;

    while( length( $text ) > $length )
    {
        return undef unless $text =~ s!$char_re{ $encoding }$!!o;
    }

    return $text;
}

#==============================================================================
#
# Return true
#
#==============================================================================

1;
