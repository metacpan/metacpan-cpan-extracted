# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::TUR::Word2Num;
# ABSTRACT: Word to number conversion in Turkish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = tur_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ tur_numerals              create parser for turkish numerals

sub tur_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'sıfır'   {  0 }
                  | 'bir'     {  1 }
                  | 'iki'     {  2 }
                  | 'üç'      {  3 }
                  | 'dört'    {  4 }
                  | 'beş'     {  5 }
                  | 'altı'    {  6 }
                  | 'yedi'    {  7 }
                  | 'sekiz'   {  8 }
                  | 'dokuz'   {  9 }

      tens:         'on'      { 10 }
                  | 'yirmi'   { 20 }
                  | 'otuz'    { 30 }
                  | 'kırk'    { 40 }
                  | 'elli'    { 50 }
                  | 'altmış'  { 60 }
                  | 'yetmiş'  { 70 }
                  | 'seksen'  { 80 }
                  | 'doksan'  { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'yüz' deca    { $item[1] * 100 + $item[3] }
                  | number 'yüz'         { $item[1] * 100            }
                  | 'yüz' deca           { 100 + $item[2]            }
                  | 'yüz'               { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'bin' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'bin'        { $item[1] * 1000            }
                | 'bin' hOd        { 1000 + $item[2]            }
                | 'bin'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd 'milyon' kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd 'milyon'       { $item[1] * 1_000_000 }
    });
}

# }}}
# {{{ ordinal2cardinal            convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Known cardinal words (from parser vocabulary).
    state $cardinals = { map { $_ => 1 } qw(
        sıfır bir iki üç dört beş altı yedi sekiz dokuz
        on yirmi otuz kırk elli altmış yetmiş seksen doksan
        yüz bin milyon
    )};

    # Turkish ordinal suffixes (vowel harmony).
    # After vowel-final stem:     -ncı  -nci  -ncu  -ncü
    # After consonant-final stem: -ıncı -inci -uncu -üncü
    # For compound numerals the suffix attaches to the last word only.
    my @harmony = (
        [ 'ncı', 'ıncı' ],
        [ 'nci', 'inci' ],
        [ 'ncu', 'uncu' ],
        [ 'ncü', 'üncü' ],
    );

    for my $pair (@harmony) {
        my ($short, $long) = @{$pair};

        for my $suffix ($long, $short) {
            next unless $input =~ /\Q$suffix\E\z/xms;
            my $candidate = $input =~ s/\Q$suffix\E\z//xmsr;
            next unless length $candidate;

            # For compounds, extract the last word for validation
            my ($last_word) = $candidate =~ /(\S+)\z/xms;

            # Reverse consonant softening before lookup
            my $lookup = $last_word;
            $lookup =~ s/dörd\z/dört/xms;

            if ( exists $cardinals->{$lookup} ) {
                $candidate =~ s/dörd\z/dört/xms;
                return $candidate;
            }
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

Lingua::TUR::Word2Num - Word to number conversion in Turkish


=head1 VERSION

version 0.2603300

Lingua::TUR::Word2Num is module for converting Turkish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::TUR::Word2Num;

 my $num = Lingua::TUR::Word2Num::w2n( 'yüz yirmi üç' );

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

  1   str    ordinal text (e.g. 'beşinci')
  =>  str    cardinal text (e.g. 'beş')
      undef  if input is not a recognised ordinal form

Convert Turkish ordinal text to cardinal text by stripping the ordinal
suffix and reversing consonant softening where applicable.

=item B<tur_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
