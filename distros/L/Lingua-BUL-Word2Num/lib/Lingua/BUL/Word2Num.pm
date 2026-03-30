# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::BUL::Word2Num;
# ABSTRACT: Word to number conversion in Bulgarian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Carp;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603300';
my  $parser  = bul_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input .= " ";                             # Grant end space before normalizing

    $input =~ s/хиляди /хиляда /g;            # Thousand variations. Normalize to хиляда
    $input =~ s/милиона /милион /g;           # Million variations. Normalize to милион

    return $parser->numeral($input);
}

# }}}
# {{{ bul_numerals                                 create parser for numerals

sub bul_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'деветнадесет '   { $return = 19; }                    # try to find a word from 0 to 19
        |     'осемнадесет '    { $return = 18; }
        |     'седемнадесет '   { $return = 17; }
        |     'шестнадесет '    { $return = 16; }
        |     'петнадесет '     { $return = 15; }
        |     'четиринадесет '  { $return = 14; }
        |     'тринадесет '     { $return = 13; }
        |     'дванадесет '     { $return = 12; }
        |     'единадесет '     { $return = 11; }
        |     'десет '          { $return = 10; }
        |     'девет '          { $return = 9; }
        |     'осем '           { $return = 8; }
        |     'седем '          { $return = 7; }
        |     'шест '           { $return = 6; }
        |     'пет '            { $return = 5; }
        |     'четири '         { $return = 4; }
        |     'три '            { $return = 3; }
        |     'две '            { $return = 2; }
        |     'два '            { $return = 2; }
        |     'един '           { $return = 1; }
        |     'едно '           { $return = 1; }
        |     'нула '           { $return = 0; }

      tens:   'двадесет '       { $return = 20; }                    # try to find a word that represents
        |     'тридесет '       { $return = 30; }                    # values 20,30,..,90
        |     'четиридесет '    { $return = 40; }
        |     'петдесет '       { $return = 50; }
        |     'шестдесет '      { $return = 60; }
        |     'седемдесет '     { $return = 70; }
        |     'осемдесет '      { $return = 80; }
        |     'деветдесет '     { $return = 90; }

     hundreds: 'деветстотин '   { $return = 900; }                   # try to find a word that represents
        |      'осемстотин '    { $return = 800; }                   # values 100,200,..,900
        |      'седемстотин '   { $return = 700; }
        |      'шестстотин '    { $return = 600; }
        |      'петстотин '     { $return = 500; }
        |      'четиристотин '  { $return = 400; }
        |      'триста '        { $return = 300; }
        |      'двеста '        { $return = 200; }
        |      'сто '           { $return = 100; }

      connector: 'и '                                                  # Bulgarian "и" (and) connector

      decade: tens 'и ' number                                        # tens и units (e.g. двадесет и три)
              { $return = $item[1] + $item[3]; }
        |     tens                                                    # plain tens (e.g. петдесет)
              { $return = $item[1]; }
        |     number                                                  # plain number 0-19
              { $return = $item[1]; }

      century: hundreds 'и ' decade(?)                               # hundreds "и" decade (for remainder < 20 or tens only)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   }
                 }
                 $return ||= undef;
               }
        |      hundreds tens 'и ' number                             # hundreds tens "и" units
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   }
                 }
                 $return ||= undef;
               }
        |      hundreds                                              # plain hundreds (e.g. двеста)
               { $return = $item[1]; }

    millenium: century(?) decade(?) 'хиляда ' connector(?) century(?) decade(?)   # try to find words that represents values
               { $return = 0;                                        # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0] && $$_[0] =~ /^\d+$/) {
                     $return += $$_[0];
                   } elsif ($_ eq "хиляда ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: century(?) decade(?)                                  # try to find words that represents values
              'милион '                                              # from 1.000.000 to 999.999.999
               millenium(?) connector(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0] && $$_[0] =~ /^\d+$/) {
                     $return += $$_[0];
                   } elsif ($_ eq "милион ") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
                 $return ||= undef;
               }
    });
}

# }}}
# {{{ ordinal2cardinal             convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Bulgarian (Cyrillic) ordinals: strip gender/definiteness suffixes, then map stems.
    # Indefinite: -и/-а/-о (masc/fem/neut).
    # Definite:   -ият/-ата/-ото (masc/fem/neut), -ия (count form).
    # Special: нулев-и has -ев- insert.

    my %irregular = (
        'нулев'           => 'нула',
        'първ'            => 'един',
        'втор'            => 'два',
        'трет'            => 'три',
        'четвърт'         => 'четири',
        'пет'             => 'пет',
        'шест'            => 'шест',
        'седм'            => 'седем',
        'осм'             => 'осем',
        'девет'           => 'девет',
        'десет'           => 'десет',
        'единадесет'      => 'единадесет',
        'дванадесет'      => 'дванадесет',
        'тринадесет'      => 'тринадесет',
        'четиринадесет'   => 'четиринадесет',
        'петнадесет'      => 'петнадесет',
        'шестнадесет'     => 'шестнадесет',
        'седемнадесет'    => 'седемнадесет',
        'осемнадесет'     => 'осемнадесет',
        'деветнадесет'    => 'деветнадесет',
        'двадесет'        => 'двадесет',
        'тридесет'        => 'тридесет',
        'четиридесет'     => 'четиридесет',
        'петдесет'        => 'петдесет',
        'шестдесет'       => 'шестдесет',
        'седемдесет'      => 'седемдесет',
        'осемдесет'       => 'осемдесет',
        'деветдесет'      => 'деветдесет',
        'двестотен'       => 'двеста',
        'тристотен'       => 'триста',
        'четиристотен'    => 'четиристотин',
        'петстотен'       => 'петстотин',
        'шестстотен'      => 'шестстотин',
        'седемстотен'     => 'седемстотин',
        'осемстотен'      => 'осемстотин',
        'деветстотен'     => 'деветстотин',
        'стотен'          => 'сто',
        'хиляден'         => 'хиляда',
        'милионен'        => 'милион',
    );

    # Hundreds cardinals that require "и" connector in cardinal form
    my %is_hundred = map { $_ => 1 } qw(
        сто двеста триста четиристотин петстотин
        шестстотин седемстотин осемстотин деветстотин
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Strip definiteness + gender suffixes to get ordinal stem
        my $norm = $word;
        $norm =~ s{ият\z}{}xms            # masc definite: петият → пет
            or $norm =~ s{ата\z}{}xms     # fem definite: петата → пет
            or $norm =~ s{ото\z}{}xms     # neut definite: петото → пет
            or $norm =~ s{ия\z}{}xms      # count form: петия → пет
            or $norm =~ s{и\z}{}xms       # masc indef: пети → пет
            or $norm =~ s{а\z}{}xms       # fem indef: пета → пет
            or $norm =~ s{о\z}{}xms;      # neut indef: пето → пет

        if (exists $irregular{$norm}) {
            push @result, $irregular{$norm};
            $matched = 1;
        }
        else {
            push @result, $word;  # pass through unchanged (connectors like "и")
        }
    }

    return undef unless $matched;

    # Bulgarian cardinals require "и" between hundreds and what follows
    # when there's a single-value remainder (unit/teen/round-tens):
    #   "сто първи"           → "сто и един"       (2 words, no existing "и")
    #   "сто двадесети и първи" → "сто двадесет и един" (already has "и")
    # Rule: insert "и" after the hundreds token when no "и" follows yet.
    if (@result >= 2 && exists $is_hundred{$result[0]}
        && !grep { $_ eq 'и' } @result) {
        splice @result, 1, 0, 'и';
    }

    return join(' ', @result);
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::BUL::Word2Num - Word to number conversion in Bulgarian


=head1 VERSION

version 0.2603300

Lingua::BUL::Word2Num is module for converting text containing number
representation in Bulgarian back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::BUL::Word2Num;

 my $num = Lingua::BUL::Word2Num::w2n( 'пет' );

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

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'пети', 'десети', 'трети')
  =>  str    cardinal text (e.g. 'пет', 'десет', 'три')
      undef  if input is not a recognized ordinal

Convert Bulgarian (Cyrillic) ordinal text to cardinal text via morphological reversal.
Handles gender and definiteness inflections (-и/-а/-о, -ият/-ата/-ото).

=item B<bul_numerals> (void)

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
