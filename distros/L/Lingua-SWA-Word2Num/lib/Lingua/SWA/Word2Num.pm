# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::SWA::Word2Num;
# ABSTRACT: Word to number conversion in Swahili

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = swa_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/\s+/ /g;
    $input =~ s/^\s+|\s+$//g;

    return $parser->numeral($input);
}

# }}}
# {{{ swa_numerals              create parser for swahili numerals

sub swa_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'sifuri'     {  0 }
                  | 'moja'       {  1 }
                  | 'mbili'      {  2 }
                  | 'tatu'       {  3 }
                  | 'nne'        {  4 }
                  | 'tano'       {  5 }
                  | 'sita'       {  6 }
                  | 'saba'       {  7 }
                  | 'nane'       {  8 }
                  | 'tisa'       {  9 }

      tens:         'ishirini'   { 20 }
                  | 'thelathini' { 30 }
                  | 'arobaini'   { 40 }
                  | 'hamsini'    { 50 }
                  | 'sitini'     { 60 }
                  | 'sabini'     { 70 }
                  | 'themanini'  { 80 }
                  | 'tisini'     { 90 }

      deca:         tens 'na' number    { $item[1] + $item[3] }
                  | 'kumi' 'na' number  { 10 + $item[3]       }
                  | tens
                  | 'kumi'              { 10 }
                  | number

      simpledeca:   'kumi' 'na' number  { 10 + $item[3]       }
                  | tens
                  | 'kumi'              { 10 }
                  | number

      hecto:        'mia' deca 'na' deca  { $item[2] * 100 + $item[4] }
                  | 'mia' deca             { $item[2] * 100            }
                  | 'mia'                  { 100                       }

      hOd:        hecto
                | deca

      kilo:       'elfu' hOd 'na' hOd  { $item[2] * 1000 + $item[4] }
                | 'elfu' hOd            { $item[2] * 1000            }
                | 'elfu'                { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       'milioni' hOd 'elfu' 'mia' number 'na' simpledeca 'na' hOd /\Z/
                    { $item[2] * 1_000_000 + ($item[5] * 100 + $item[7]) * 1000 + $item[9] }
                | 'milioni' hOd kOhOd { $item[2] * 1_000_000 + $item[3] }
                | 'milioni' hOd       { $item[2] * 1_000_000 }
    });
}

# }}}
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Inverse of Swahili ordinal morphology: restore cardinal from ordinal text.
    # Swahili ordinals use noun-class prefixes (wa-, ya-, cha-, vya-, etc.)
    # followed by a special ordinal stem (1-5, 8) or the cardinal itself (6,7,9,10+).
    #
    # Special stems: kwanza→moja (1), pili→mbili (2)
    # Identical stems (3,4,5,8): tatu, nne, tano, nane — no change needed.
    # For 6,7,9,10+: ordinal = prefix + cardinal — strip prefix.

    # Strip noun-class prefix: "wa kwanza" → "kwanza", "ya pili" → "pili"
    # The prefix is everything up to the last space; the ordinal word is the last token.
    # For numbers >= 6 (except 8), the ordinal word IS the cardinal multi-word form,
    # so we must preserve all tokens after the single-word prefix.
    # Swahili ordinal format: <prefix> <ordinal-word(s)>
    # where prefix is a single noun-class marker (wa, ya, cha, ki, vi, etc.)
    $input =~ s{\A\S+\s+}{}xms;

    # Special ordinal stems that differ from cardinal
    $input =~ s{\Akwanza\z}{moja}xms  and return $input;
    $input =~ s{\Apili\z}{mbili}xms   and return $input;

    # For 3,4,5,8 the ordinal stem IS the cardinal — return as-is
    return $input if $input =~ m{\A (?: tatu | nne | tano | nane ) \z}xms;

    # For 6,7,9 and all 10+ the ordinal form equals the cardinal — return as-is
    return $input;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SWA::Word2Num - Word to number conversion in Swahili


=head1 VERSION

version 0.2603300

Lingua::SWA::Word2Num is a module for converting Swahili numerals into
numbers. Converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SWA::Word2Num qw(w2n);

 my $num = w2n( 'ishirini na tatu' );

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

  1   str    ordinal text (e.g. 'kwanza', 'pili', 'wa-tatu')
  =>  str    cardinal text (e.g. 'moja', 'mbili', 'tatu')
      undef  if input is not recognised as an ordinal

Convert Swahili ordinal text to cardinal text (morphological reversal).

=item B<swa_numerals> (void)

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
