# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::KAZ::Word2Num;
# ABSTRACT: Word to number conversion in Kazakh

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = kaz_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ kaz_numerals              create parser for kazakh numerals

sub kaz_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'нөл'     {  0 }
                  | 'бір'     {  1 }
                  | 'екі'     {  2 }
                  | 'үш'      {  3 }
                  | 'төрт'    {  4 }
                  | 'бес'     {  5 }
                  | 'алты'    {  6 }
                  | 'жеті'    {  7 }
                  | 'сегіз'   {  8 }
                  | 'тоғыз'   {  9 }

      tens:         'он'        { 10 }
                  | 'жиырма'    { 20 }
                  | 'отыз'      { 30 }
                  | 'қырық'     { 40 }
                  | 'елу'       { 50 }
                  | 'алпыс'     { 60 }
                  | 'жетпіс'    { 70 }
                  | 'сексен'    { 80 }
                  | 'тоқсан'    { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'жүз' deca    { $item[1] * 100 + $item[3] }
                  | number 'жүз'         { $item[1] * 100            }
                  | 'жүз' deca           { 100 + $item[2]            }
                  | 'жүз'               { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'мың' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'мың'        { $item[1] * 1000            }
                | 'мың' hOd        { 1000 + $item[2]            }
                | 'мың'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'миллион' kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd 'миллион'       { $item[1] * 1_000_000 }
    });
}

# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        w2n => 1,
    };
}

# }}}
# {{{ ordinal2cardinal            convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Known cardinal words (from parser vocabulary).
    state $cardinals = { map { $_ => 1 } qw(
        нөл бір екі үш төрт бес алты жеті сегіз тоғыз
        он жиырма отыз қырық елу алпыс жетпіс сексен тоқсан
        жүз мың миллион
    )};

    # Kazakh ordinal suffixes (Cyrillic, 2-way vowel harmony).
    # After vowel-final stem:     -ншы  (back) -нші  (front)
    # After consonant-final stem: -ыншы (back) -інші (front)
    my @harmony = (
        [ 'ншы', 'ыншы' ],
        [ 'нші', 'інші' ],
    );

    for my $pair (@harmony) {
        my ($short, $long) = @{$pair};

        for my $suffix ($long, $short) {
            next unless $input =~ /\Q$suffix\E\z/xms;
            my $candidate = $input =~ s/\Q$suffix\E\z//xmsr;
            next unless length $candidate;

            my ($last_word) = $candidate =~ /(\S+)\z/xms;
            return $candidate if exists $cardinals->{$last_word};
        }
    }

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::KAZ::Word2Num - Word to number conversion in Kazakh


=head1 VERSION

version 0.2603300

Lingua::KAZ::Word2Num is module for converting Kazakh numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8 (Cyrillic script).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::KAZ::Word2Num;

 my $num = Lingua::KAZ::Word2Num::w2n( 'жүз жиырма үш' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'бесінші')
  =>  str    cardinal text (e.g. 'бес')
      undef  if input is not a recognised ordinal form

Convert Kazakh ordinal text to cardinal text by stripping the ordinal
suffix.

=item B<kaz_numerals> (void)

  =>  obj  new parser object

Internal parser.

=item B<capabilities> (void)

  =>  hashref    hash of supported features

Returns a hash reference indicating which conversion features are supported.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item w2n

=item ordinal2cardinal

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
