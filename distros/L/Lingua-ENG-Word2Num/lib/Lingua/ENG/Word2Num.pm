# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::ENG::Word2Num;
# ABSTRACT: Word to number conversion in English

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603300';

my $parser   = eng_numerals();

# }}}

# {{{ w2n                     convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}

# {{{ eng_numerals            create parser for numerals

sub eng_numerals {
    return Parse::RecDescent->new(q{
        <autoaction: { $item[1] } >

        numeral:     mega
                  |  kOhOd
                  | { }

         number:    'twelve'     { 12 }
                  | 'thirteen'   { 13 }
                  | 'fourteen'   { 14 }
                  | 'fifteen'    { 15 }
                  | 'sixteen'    { 16 }
                  | 'seventeen'  { 17 }
                  | 'eighteen'   { 18 }
                  | 'nineteen'   { 19 }
                  | 'zero'       {  0 }
                  | 'one'        {  1 }
                  | 'two'        {  2 }
                  | 'three'      {  3 }
                  | 'four'       {  4 }
                  | 'five'       {  5 }
                  | 'six'        {  6 }
                  | 'seven'      {  7 }
                  | 'eight'      {  8 }
                  | 'nine'       {  9 }
                  | 'ten'        { 10 }
                  | 'eleven'     { 11 }

         tens:      'twenty'     { 20 }
                  | 'thirty'     { 30 }
                  | 'forty'      { 40 }
                  | 'fifty'      { 50 }
                  | 'sixty'      { 60 }
                  | 'seventy'    { 70 }
                  | 'eighty'     { 80 }
                  | 'ninety'     { 90 }

         deca:      tens /(-|\s)?/ number  { $item[1] + $item[3] }
                  | tens
                  | number

        hecto:      number 'hundred' deca  { $item[1] * 100  + $item[3] }
                  | number 'hundred'       { $item[1] * 100 }

          hOd:      hecto
                  | deca

         kilo:      hOd /thousand,?/ hOd   { $item[1] * 1000 + $item[3] }
                  | hOd /thousand,?/       { $item[1] * 1000 }
                  |     /thousand,?/ hOd   { 1000 + $item[2] }
                  |     /thousand,?/       { 1000 }

        kOhOd:      kilo
                  | hOd

         mega:      hOd /millions?,?/ kOhOd   { $item[1] * 1_000_000 + $item[3] }
                  | hOd /millions?,?/         { $item[1] * 1_000_000 }
                  |     'million'     kOhOd   { 1_000_000 + $item[2] }
                  |     'million'             { 1_000_000 }

    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # English ordinals: irregulars, -ieth (tens), regular -th
    # For compounds like "twenty-first", only the last element is ordinal.

    my %irregular = (
        'first'    => 'one',
        'second'   => 'two',
        'third'    => 'three',
        'fifth'    => 'five',
        'eighth'   => 'eight',
        'ninth'    => 'nine',
        'twelfth'  => 'twelve',
    );

    # Compound: "twenty-first" or "twenty first" → convert last word only
    # Num2Word produces space-separated: "twenty first", "one hundred third"
    if ($input =~ m{\A (?<prefix>.+) [-\s] (?<last>\S+) \z}xms) {
        my $prefix = $+{prefix};
        my $last   = $+{last};
        my $sep    = ($input =~ m{-}) ? '-' : ' ';

        # Convert the last (ordinal) element to cardinal
        my $cardinal = ordinal2cardinal($last) // return;
        return "${prefix}${sep}${cardinal}";
    }

    # Irregular standalone
    return $irregular{$input} if exists $irregular{$input};

    # Tens ending in -ieth: twentieth→twenty, thirtieth→thirty, etc.
    if ($input =~ s{ieth\z}{y}xms) {
        return $input;
    }

    # Regular -th: fourteenth→fourteen, hundredth→hundred, etc.
    if ($input =~ s{th\z}{}xms) {
        return $input;
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

Lingua::ENG::Word2Num - Word to number conversion in English


=head1 VERSION

version 0.2603300

Lingua::ENG::Word2Num is module for converting text containing number
representation in English back into number. Converts whole numbers from 0 up
to 999 999 999.

Text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ENG::Word2Num;

 my $num = Lingua::ENG::Word2Num::w2n( 'nineteen' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str     string to convert
  =>  num     converted number
      undef   if input string is not known

Convert text representation to number.

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'first', 'twenty-third', 'fiftieth')
  =>  str    cardinal text (e.g. 'one', 'twenty-three', 'fifty')
      undef  if input is not recognised as an ordinal

Convert English ordinal text to cardinal text (morphological reversal).
Handles irregular forms, -ieth tens, regular -th, and hyphenated compounds.

=item B<eng_numerals> (void)

  =>  obj  new parser object

Internal function.

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
 coding (until 2005):
   Roman Vasicek E<lt>info@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
