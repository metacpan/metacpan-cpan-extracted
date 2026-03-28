package EBook::Ishmael::CharDet;
use 5.016;
our $VERSION = '2.04';
use strict;
use warnings;

use Exporter 'import';
our @EXPORT = qw(chardet);

use EBook::Ishmael::CharDet::Constants qw(:CONSTANTS);
use EBook::Ishmael::CharDet::Big5;
use EBook::Ishmael::CharDet::CP1250;
use EBook::Ishmael::CharDet::CP1251;
use EBook::Ishmael::CharDet::CP1252;
use EBook::Ishmael::CharDet::CP1253;
use EBook::Ishmael::CharDet::CP1254;
use EBook::Ishmael::CharDet::CP1255;
use EBook::Ishmael::CharDet::CP1256;
use EBook::Ishmael::CharDet::EUCJP;
use EBook::Ishmael::CharDet::EUCKR;
use EBook::Ishmael::CharDet::GB2312;
use EBook::Ishmael::CharDet::HZ;
use EBook::Ishmael::CharDet::ISO2022JP;
use EBook::Ishmael::CharDet::ISO2022KR;
use EBook::Ishmael::CharDet::ISO88595;
use EBook::Ishmael::CharDet::ShiftJIS;
use EBook::Ishmael::CharDet::UTF8;

# Based encoding detection algorithm off of the chardet python library:
# - https://chardet.readthedocs.io/en/latest/
# These particular documents were especially useful:
# - https://chardet.readthedocs.io/en/latest/how-it-works.html
# - https://www-archive.mozilla.org/projects/intl/universalcharsetdetection

# TODO: Optimize performance

# TODO: UTF16{BE,LE} support?
# TODO: UTF32{BE,LE} support?
# TODO: ISO-8859-* support?

sub has_high_bit {

    my ($str) = @_;

    return $str =~ /[\x80-\xff]/;

}

sub chardet_bom {

    my ($str) = @_;

    if ($str =~ /^\xef\xbb\xbf/) {
        return 'UTF-8';
    } elsif ($str =~ /^\xfe\xff/) {
        return 'UTF-16BE';
    } elsif ($str =~ /^\xff\xfe/) {
        return 'UTF-16LE';
    } elsif ($str =~ /^\x00\x00\xfe\xff/) {
        return 'UTF-32BE';
    # This could be wrong, as this could also be UTF-16LE starting with a
    # null character, but I believe its most likely to be a UTF-32.
    } elsif ($str =~ /^\xff\xfe\x00\x00/) {
        return 'UTF-32LE';
    }

    return undef;

}

sub chardet_utf16 {

    my ($str) = @_;

    if (length($str) % 2 != 0) {
        return undef;
    }

    my $len = length $str > 1024 ? 1024 : length $str;

    my $leading_null   = 0; # UTF-16BE
    my $trailling_null = 0; # UTF-16LE
    my $none = 0;
    for (my $i = 0; $i < $len; $i += 2) {
        my $char = substr $str, $i, 2;
        my $got_null = 0;
        if ($char =~ /^\0/) {
            $leading_null++;
            $got_null = 1;
        }
        if ($char =~ /\0$/) {
            $trailling_null++;
            $got_null = 1;
        }
        if (!$got_null) {
            $none++;
        }
    }

    if ($leading_null > $trailling_null && $leading_null > $none) {
        return 'UTF-16BE';
    } elsif ($trailling_null > $leading_null && $trailling_null > $none) {
        return 'UTF-16LE';
    } else {
        return undef;
    }

}

sub chardet_utf32 {

    my ($str) = @_;

    if (length($str) % 4 != 0) {
        return undef;
    }

    my $len = length $str > 1024 ? 1024 : length $str;

    my $leading_null   = 0; # UTF-32BE
    my $trailling_null = 0; # UTF-32LE
    my $none = 0;
    for (my $i = 0; $i < $len; $i += 4) {
        my $char = substr $str, $i, 4;
        my $got_null = 0;
        if ($char =~ /^\0\0\0/) {
            $leading_null++;
            $got_null = 1;
        }
        if ($char =~ /\0\0\0$/) {
            $trailling_null++;
            $got_null = 1;
        }
        if (!$got_null) {
            $none++;
        }
    }

    if ($leading_null > $trailling_null && $leading_null > $none) {
        return 'UTF-32BE';
    } elsif ($trailling_null > $leading_null && $trailling_null > $none) {
        return 'UTF-32LE';
    } else {
        return undef;
    }

}

sub chardet_with {

    my ($str, @guessers) = @_;

    my $len = length $str > 8192 ? 8192 : length $str;

    for (my $i = 0; $i < $len; $i += 16) {
        my $c = substr $str, $i, 16;
        for my $j (0 .. $#guessers) {
            if ($j > $#guessers) {
                last;
            }
            my $take = $guessers[$j]->take($c);
            if ($take == TAKE_MUST_BE) {
                return ([ $guessers[$j]->encoding, 1.0 ]);
            } elsif ($take == TAKE_BAD) {
                splice @guessers, $j, 1;
            }
        }
        if (!@guessers) {
            return ();
        }
    }

    return map { [ $_->encoding, $_->confidence ] } @guessers;

}

sub chardet_7bit {

    my ($str) = @_;

    my @guesses = chardet_with(
        $str,
        EBook::Ishmael::CharDet::HZ->new,
        EBook::Ishmael::CharDet::ISO2022JP->new,
        EBook::Ishmael::CharDet::ISO2022KR->new,
    );
    push @guesses, [ 'ASCII', 0.75 ];

    return @guesses;

}

sub chardet_multibyte {

    my ($str) = @_;

    return chardet_with(
        $str,
        EBook::Ishmael::CharDet::UTF8->new,
        EBook::Ishmael::CharDet::Big5->new,
        EBook::Ishmael::CharDet::ShiftJIS->new,
        EBook::Ishmael::CharDet::EUCJP->new,
        EBook::Ishmael::CharDet::EUCKR->new,
        EBook::Ishmael::CharDet::GB2312->new,
    );

}

sub chardet_singlebyte {

    my ($str) = @_;

    return chardet_with(
        $str,
        EBook::Ishmael::CharDet::CP1250->new,
        EBook::Ishmael::CharDet::CP1251->new,
        EBook::Ishmael::CharDet::CP1252->new,
        EBook::Ishmael::CharDet::CP1253->new,
        EBook::Ishmael::CharDet::CP1254->new,
        EBook::Ishmael::CharDet::CP1255->new,
        EBook::Ishmael::CharDet::CP1256->new,
        EBook::Ishmael::CharDet::ISO88595->new,
    );

}

sub chardet {

    my ($str) = @_;

    my $char = chardet_bom($str);
    if (defined $char) {
        return $char;
    }

    $char = chardet_utf16($str);
    if (defined $char) {
        return $char;
    }

    $char = chardet_utf32($str);
    if (defined $char) {
        return $char;
    }

    my @chars;

    if (!has_high_bit($str)) {
        @chars = sort { $b->[1] <=> $a->[1] } chardet_7bit($str);
        return @chars > 0 ? $chars[0]->[0] : 'ASCII';
    }

    @chars = chardet_multibyte($str);
    push @chars, chardet_singlebyte($str);
    @chars = sort { $b->[1] <=> $a->[1] } @chars;

    return @chars > 0 ? $chars[0]->[0] : undef;

}

1;

=head1 NAME

=encoding UTF-8

EBook::Ishmael::CharDet - Guess the character encoding of given text

=head1 SYNOPSIS

  use EBook::Ishmael::CharDet;

  use Encode qw(encode);

  # $encoding should be 'CP1250'
  my $encoding = chardet(encode('CP1250', 'Obecná veřejná'));

=head1 DESCRIPTION

B<EBook::Ishmael::CharDet> is a module that provides the C<chardet()> subroutine
which guesses character encoding of given text. This is a private module,
please consult the L<ishmael> manual for user documentation.

=head1 SUBROUTINES

=over 4

=item $encoding = chardet($text)

Guesses the encoding for the encoded text C<$text> through a series of
heuristics. If C<chardet()> cannot come to a conclusion, C<undef> is returned.

The follow encodings are supported so far:

=over 2

=item ASCII

=item UTF-8

=item UTF-16BE

=item UTF-16LE

=item UTF-32BE

=item UTF-32LE

=item GB2312

=item CP1250

=item CP1251

=item CP1252

=item CP1253

=item CP1254

=item CP1255

=item CP1256

=item HZ

=item ISO-2022-JP

=item ISO-2022-KR

=item ISO-8859-5

=item EUC-JP

=item EUC-KR

=item Big5

=item Shift_JIS

=back

=back

=head1 AUTHOR

Written by Samuel Young, E<lt>samyoung12788@gmail.comE<gt>.

This project's source can be found on its
L<Codeberg Page|https://codeberg.org/1-1sam/ishmael>. Comments and pull
requests are welcome!

=head1 COPYRIGHT

Copyright (C) 2025-2026 Samuel Young

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

=cut
