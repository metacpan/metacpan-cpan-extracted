# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::KOR::Num2Word;
# ABSTRACT: Number to word conversion in Korean

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;
use Export::Attrs;
use Readonly;

# }}}
# {{{ variable declarations

my Readonly::Scalar $COPY = 'Copyright (c) PetaMem, s.r.o. 2002-present';
our $VERSION = '0.2603300';

# }}}

# {{{ num2kor_cardinal                 convert number to text

sub num2kor_cardinal :Export {
    my $positive = shift;

    croak 'You should specify a number from interval [0, 999_999_999_999]'
        if    !defined $positive
           || $positive !~ m{\A\d+\z}xms
           || $positive < 0
           || $positive > 999_999_999_999;

    my @digits = ('영', '일', '이', '삼', '사', '오', '육', '칠', '팔', '구');

    return $digits[$positive] if ($positive >= 0 && $positive <= 9);    # 0 .. 9
    return '십'               if ($positive == 10);                     # 10

    my $out;          # string for return value construction
    my $one_idx;      # index for digits array
    my $remain;       # remainder

    if ($positive > 10 && $positive < 100) {                            # 11 .. 99
        $one_idx = int ($positive / 10);
        $remain  = $positive % 10;

        $out  = $one_idx > 1 ? "$digits[$one_idx]십" : '십';
        $out .= $remain ? $digits[$remain] : '';
    }
    elsif ($positive > 99 && $positive < 1000) {                        # 100 .. 999
        $one_idx = int ($positive / 100);
        $remain  = $positive % 100;

        $out  = $one_idx > 1 ? "$digits[$one_idx]백" : '백';
        $out .= $remain ? num2kor_cardinal($remain) : '';
    }
    elsif ($positive > 999 && $positive < 10_000) {                     # 1000 .. 9999
        $one_idx = int ($positive / 1000);
        $remain  = $positive % 1000;

        $out  = $one_idx > 1 ? "$digits[$one_idx]천" : '천';
        $out .= $remain ? num2kor_cardinal($remain) : '';
    }
    elsif ($positive > 9_999 && $positive < 100_000_000) {              # 10000 .. 99_999_999
        $one_idx = int ($positive / 10000);
        $remain  = $positive % 10000;

        $out  = num2kor_cardinal($one_idx) . '만';
        $out .= $remain ? num2kor_cardinal($remain) : '';
    }
    elsif ($positive > 99_999_999
           && $positive < 1_000_000_000_000) {                          # 100_000_000 .. 999_999_999_999
        $one_idx = int ($positive / 100_000_000);
        $remain  = $positive % 100_000_000;

        $out  = num2kor_cardinal($one_idx) . '억';
        $out .= $remain ? num2kor_cardinal($remain) : '';
    }

    return $out;
}

# }}}


# {{{ num2kor_ordinal                 convert number to ordinal text

sub num2kor_ordinal :Export {
    my $number = shift;

    croak 'You should specify a number from interval [1, 999_999_999_999]'
        if    !defined $number
           || $number !~ m{\A\d+\z}xms
           || $number < 1
           || $number > 999_999_999_999;

    # Korean ordinals use native Korean numbers + 번째 (beonjjae).
    # 1st is the special form 첫 번째 (cheot beonjjae).
    # Native Korean numbers exist for 1-99; beyond that, use
    # Sino-Korean cardinal + 번째.

    return '첫 번째' if $number == 1;

    # Native Korean ones (adnominal/counter forms used before 번째)
    # Index maps to digit value: 0=unused, 1=한, 2=두, ...
    my @native_ones = ('', '한', '두', '세', '네', '다섯', '여섯', '일곱', '여덟', '아홉');
    my @native_tens = ('열', '스물', '서른', '마흔', '쉰', '예순', '일흔', '여든', '아흔');

    if ($number >= 2 && $number <= 99) {
        my $tens = int($number / 10);
        my $ones = $number % 10;

        my $out = '';
        $out .= $native_tens[$tens - 1] if $tens > 0;
        $out .= $native_ones[$ones]     if $ones > 0;
        $out .= ' 번째';
        return $out;
    }

    # For 100+, fall back to Sino-Korean cardinal + 번째
    return num2kor_cardinal($number) . ' 번째';
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::KOR::Num2Word - Number to word conversion in Korean


=head1 VERSION

version 0.2603300

Lingua::KOR::Num2Word is module for converting numbers into their written
representation in Korean (Sino-Korean system). Converts whole numbers
from 0 up to 999 999 999 999.

Text output is encoded in UTF-8 using Korean characters.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::KOR::Num2Word;

 my $text = Lingua::KOR::Num2Word::num2kor_cardinal( 123 );
 # $text eq '백이십삼'

 print $text || "sorry, can't convert this number into korean language.";

 my $ord = Lingua::KOR::Num2Word::num2kor_ordinal( 3 );
 print $ord;    # "세 번째"

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<num2kor_cardinal> (positional)

  1   num    number to convert
  =>  str    converted string
      undef  if input number is not known

Convert number to text representation.
Only numbers from interval [0, 999_999_999_999] will be converted.

=item B<num2kor_ordinal> (positional)

  1   num    number to convert
  =>  str    converted ordinal string

Convert number to ordinal text using native Korean numbers + 번째.
For 1, returns the special form 첫 번째. For 2-99, uses native Korean
numerals. For 100+, falls back to Sino-Korean cardinal + 번째.
Only numbers from interval [1, 999_999_999_999] will be converted.


=item B<capabilities> (void)

  =>  href   hashref indicating supported conversion types

Returns a hashref of capabilities for this language module.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item num2kor_cardinal

=item num2kor_ordinal

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHORS

 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
