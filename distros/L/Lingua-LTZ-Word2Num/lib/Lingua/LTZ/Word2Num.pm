# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::LTZ::Word2Num;
# ABSTRACT: Word to number conversion in Luxembourgish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = ltz_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ ltz_numerals              create parser for Luxembourgish numerals

sub ltz_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'dräizéng'    { 13 }
                  | 'véierzéng'   { 14 }
                  | 'fofzéng'     { 15 }
                  | 'siechzéng'   { 16 }
                  | 'siwwenzéng'  { 17 }
                  | 'uechtzéng'   { 18 }
                  | 'nonzéng'     { 19 }
                  | 'null'        {  0 }
                  | /eent?/       {  1 }
                  | /eng/         {  1 }
                  | 'zwee'        {  2 }
                  | 'dräi'        {  3 }
                  | 'véier'       {  4 }
                  | /fënnef/      {  5 }
                  | 'sechs'       {  6 }
                  | 'siwen'       {  7 }
                  | 'aacht'       {  8 }
                  | 'néng'        {  9 }
                  | 'zéng'        { 10 }
                  | 'eelef'       { 11 }
                  | 'zwielef'     { 12 }

      tens:         'zwanzeg'     { 20 }
                  | 'drësseg'     { 30 }
                  | 'véierzeg'    { 40 }
                  | 'fofzeg'      { 50 }
                  | 'sechzeg'     { 60 }
                  | 'siwwenzeg'   { 70 }
                  | 'achtzeg'     { 80 }
                  | 'nonzeg'      { 90 }

      # connector: 'an' or 'a' (n-rule / Eifel rule)
      connector:    'an'
                  | 'a'

      deca:         connector deca            { $item[2]            }
                  | number connector tens     { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number 'honnert' deca     { $item[1] * 100 + $item[3] }
                  | number 'honnert'          { $item[1] * 100            }
                  | 'honnert' deca            { 100 + $item[2]            }
                  | 'honnert'                 { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'dausend' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'dausend'        { $item[1] * 1000            }
                | 'dausend' hOd        { 1000 + $item[2]            }
                | 'dausend'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /Millioun(en)?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /Millioun(en)?/       { $item[1] * 1_000_000 }
    });
}

# }}}
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Inverse of Luxembourgish ordinal morphology: restore cardinal from ordinal text.
    # Irregulars (standalone or as final element of compound)
    $input =~ s{éischt\z}{eent}xms    and return $input;
    $input =~ s{zweet\z}{zwee}xms     and return $input;
    $input =~ s{drëtt\z}{dräi}xms     and return $input;
    $input =~ s{sechst\z}{sechs}xms    and return $input;  # 6th: stem 's' consumed by suffix
    $input =~ s{siiwent\z}{siwen}xms  and return $input;
    $input =~ s{aacht\z}{aacht}xms    and return $input;  # 8th = cardinal (no change)

    # Regular: strip -st (20+ and compounds ending in tens/honnert/dausend)
    $input =~ s{st\z}{}xms            and return $input;

    # Regular: strip -t (4-19)
    $input =~ s{t\z}{}xms             and return $input;

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::LTZ::Word2Num - Word to number conversion in Luxembourgish


=head1 VERSION

version 0.2603300

Lingua::LTZ::Word2Num is module for converting Luxembourgish
(Lëtzebuergesch) numerals into numbers. Converts whole numbers from 0
up to 999 999 999. Input is expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LTZ::Word2Num;

 my $num = Lingua::LTZ::Word2Num::w2n( 'siwwenzéng' );

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
You can specify a numeral from interval [0,999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'drëtt', 'fënneft', 'zwanzegst')
  =>  str    cardinal text (e.g. 'dräi', 'fënnef', 'zwanzeg')
      undef  if input is not recognised as an ordinal

Convert Luxembourgish ordinal text to cardinal text (morphological reversal).

=item B<ltz_numerals> (void)

  =>  obj  new parser object

Internal parser.

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
 coding:
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
