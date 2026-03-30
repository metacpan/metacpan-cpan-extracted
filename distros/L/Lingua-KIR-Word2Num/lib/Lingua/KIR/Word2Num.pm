# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::KIR::Word2Num;
# ABSTRACT: Word to number conversion in Kyrgyz

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = kir_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ kir_numerals              create parser for kyrgyz numerals

sub kir_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'нөл'     {  0 }
                  | 'бир'     {  1 }
                  | 'эки'     {  2 }
                  | 'үч'      {  3 }
                  | 'төрт'    {  4 }
                  | 'беш'     {  5 }
                  | 'алты'    {  6 }
                  | 'жети'    {  7 }
                  | 'сегиз'   {  8 }
                  | 'тогуз'   {  9 }

      tens:         'он'        { 10 }
                  | 'жыйырма'  { 20 }
                  | 'отуз'      { 30 }
                  | 'кырк'      { 40 }
                  | 'элүү'      { 50 }
                  | 'алтымыш'  { 60 }
                  | 'жетимиш'  { 70 }
                  | 'сексен'    { 80 }
                  | 'токсон'    { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'жүз' deca    { $item[1] * 100 + $item[3] }
                  | number 'жүз'         { $item[1] * 100            }
                  | 'жүз' deca           { 100 + $item[2]            }
                  | 'жүз'               { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'миң' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'миң'        { $item[1] * 1000            }
                | 'миң' hOd        { 1000 + $item[2]            }
                | 'миң'            { 1000                       }

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
        нөл бир эки үч төрт беш алты жети сегиз тогуз
        он жыйырма отуз кырк элүү алтымыш жетимиш сексен токсон
        жүз миң миллион
    )};

    # Kyrgyz ordinal suffixes (Cyrillic, 4-way vowel harmony).
    # After vowel-final stem:     -нчы  -нчи  -нчу  -нчү
    # After consonant-final stem: -ынчы -инчи -унчу -үнчү
    my @harmony = (
        [ 'нчы', 'ынчы' ],
        [ 'нчи', 'инчи' ],
        [ 'нчу', 'унчу' ],
        [ 'нчү', 'үнчү' ],
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

Lingua::KIR::Word2Num - Word to number conversion in Kyrgyz


=head1 VERSION

version 0.2603300

Lingua::KIR::Word2Num is module for converting Kyrgyz numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8 (Cyrillic script).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::KIR::Word2Num;

 my $num = Lingua::KIR::Word2Num::w2n( 'жүз жыйырма үч' );

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

  1   str    ordinal text (e.g. 'бешинчи')
  =>  str    cardinal text (e.g. 'беш')
      undef  if input is not a recognised ordinal form

Convert Kyrgyz ordinal text to cardinal text by stripping the ordinal
suffix.

=item B<kir_numerals> (void)

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
