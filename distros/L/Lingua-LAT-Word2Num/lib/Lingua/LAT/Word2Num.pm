# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::LAT::Word2Num;
# ABSTRACT: Word to number conversion in Latin

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = lat_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ lat_numerals              create parser for latin numerals

sub lat_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      kOhOd
                  | { }

      number:       'quattuordecim' { 14 }
                  | 'quattuor'      {  4 }
                  | 'quindecim'     { 15 }
                  | 'quinque'       {  5 }
                  | 'tredecim'      { 13 }
                  | 'duodeviginti'  { 18 }
                  | 'undeviginti'   { 19 }
                  | 'duodecim'      { 12 }
                  | 'undecim'       { 11 }
                  | 'septendecim'   { 17 }
                  | 'sedecim'       { 16 }
                  | 'nulla'         {  0 }
                  | 'unus'          {  1 }
                  | 'duo'           {  2 }
                  | 'tres'          {  3 }
                  | 'sex'           {  6 }
                  | 'septem'        {  7 }
                  | 'octo'          {  8 }
                  | 'novem'         {  9 }
                  | 'decem'         { 10 }

      tens:         'viginti'       { 20 }
                  | 'triginta'      { 30 }
                  | 'quadraginta'   { 40 }
                  | 'quinquaginta'  { 50 }
                  | 'sexaginta'     { 60 }
                  | 'septuaginta'   { 70 }
                  | 'octoginta'     { 80 }
                  | 'nonaginta'     { 90 }

      # Subtractive forms: duode/unde + next decade (written as one word)
      subtractive:  'duodetriginta'      { 28 }
                  | 'undetriginta'       { 29 }
                  | 'duodequadraginta'   { 38 }
                  | 'undequadraginta'    { 39 }
                  | 'duodequinquaginta'  { 48 }
                  | 'undequinquaginta'   { 49 }
                  | 'duodesexaginta'     { 58 }
                  | 'undesexaginta'      { 59 }
                  | 'duodeseptuaginta'   { 68 }
                  | 'undeseptuaginta'    { 69 }
                  | 'duodeoctoginta'     { 78 }
                  | 'undeoctoginta'      { 79 }
                  | 'duodenonaginta'     { 88 }
                  | 'undenonaginta'      { 89 }
                  | 'undecentum'         { 99 }

      deca:         tens number          { $item[1] + $item[2] }
                  | subtractive
                  | tens
                  | number

      hecto:        /ducenti/            deca  { 200 + $item[2] }
                  | /ducenti/                  { 200 }
                  | /trecenti/           deca  { 300 + $item[2] }
                  | /trecenti/                 { 300 }
                  | /quadringenti/       deca  { 400 + $item[2] }
                  | /quadringenti/             { 400 }
                  | /quingenti/          deca  { 500 + $item[2] }
                  | /quingenti/                { 500 }
                  | /sescenti/           deca  { 600 + $item[2] }
                  | /sescenti/                 { 600 }
                  | /septingenti/        deca  { 700 + $item[2] }
                  | /septingenti/              { 700 }
                  | /octingenti/         deca  { 800 + $item[2] }
                  | /octingenti/               { 800 }
                  | /nongenti/           deca  { 900 + $item[2] }
                  | /nongenti/                 { 900 }
                  | 'centum'             deca  { 100 + $item[2] }
                  | 'centum'                   { 100 }

      hOd:        hecto
                | deca

      kilo:       hOd 'milia' hOd     { $item[1] * 1000 + $item[3] }
                | hOd 'milia'          { $item[1] * 1000            }
                | 'mille' hOd          { 1000 + $item[2]            }
                | 'mille'              { 1000                        }

      kOhOd:      kilo
                | hOd
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Latin ordinals are entirely table-driven with suppletive stems.
    # Includes subtractive forms (duodevicesimus → duodeviginti).
    # Compounds: space-separated, each part is converted.

    my %ordinal_to_cardinal = (
        # Units
        'primus'       => 'unus',
        'prima'        => 'unus',
        'primum'       => 'unus',
        'secundus'     => 'duo',
        'secunda'      => 'duo',
        'secundum'     => 'duo',
        'tertius'      => 'tres',
        'tertia'       => 'tres',
        'tertium'      => 'tres',
        'quartus'      => 'quattuor',
        'quarta'       => 'quattuor',
        'quartum'      => 'quattuor',
        'quintus'      => 'quinque',
        'quinta'       => 'quinque',
        'quintum'      => 'quinque',
        'sextus'       => 'sex',
        'sexta'        => 'sex',
        'sextum'       => 'sex',
        'septimus'     => 'septem',
        'septima'      => 'septem',
        'septimum'     => 'septem',
        'octavus'      => 'octo',
        'octava'       => 'octo',
        'octavum'      => 'octo',
        'nonus'        => 'novem',
        'nona'         => 'novem',
        'nonum'        => 'novem',
        'decimus'      => 'decem',
        'decima'       => 'decem',
        'decimum'      => 'decem',
        # Teens
        'undecimus'    => 'undecim',
        'duodecimus'   => 'duodecim',
        # Subtractive (both -censimus and -cesimus spellings)
        'duodevicesimus'    => 'duodeviginti',
        'undevicesimus'     => 'undeviginti',
        'duodetricensimus'  => 'duodetriginta',
        'duodetricesimus'   => 'duodetriginta',
        'undetricensimus'   => 'undetriginta',
        'undetricesimus'    => 'undetriginta',
        'duodequadragesimus' => 'duodequadraginta',
        'undequadragesimus'  => 'undequadraginta',
        'duodequinquagesimus' => 'duodequinquaginta',
        'undequinquagesimus'  => 'undequinquaginta',
        'duodesexagesimus'   => 'duodesexaginta',
        'undesexagesimus'    => 'undesexaginta',
        'duodeseptuagesimus' => 'duodeseptuaginta',
        'undeseptuagesimus'  => 'undeseptuaginta',
        'duodeoctogesimus'   => 'duodeoctoginta',
        'undeoctogesimus'    => 'undeoctoginta',
        'duodenonagesimus'   => 'duodenonaginta',
        'undenonagesimus'    => 'undenonaginta',
        'duodecentesimus'    => 'nonaginta octo',
        'undecentesimus'     => 'undecentum',
        # Tens (both -censimus/-gesimus and -cesimus spellings)
        'vicesimus'    => 'viginti',
        'vicensimus'   => 'viginti',
        'tricensimus'  => 'triginta',
        'trigesimus'   => 'triginta',
        'tricesimus'   => 'triginta',
        'quadragesimus' => 'quadraginta',
        'quinquagesimus' => 'quinquaginta',
        'sexagesimus'  => 'sexaginta',
        'septuagesimus' => 'septuaginta',
        'octogesimus'  => 'octoginta',
        'nonagesimus'  => 'nonaginta',
        # Hundreds
        'centesimus'   => 'centum',
        'ducentesimus' => 'ducenti',
        'trecentesimus' => 'trecenti',
        'quadringentesimus' => 'quadringenti',
        'quingentesimus'    => 'quingenti',
        'sescentesimus'     => 'sescenti',
        'septingentesimus'  => 'septingenti',
        'octingentesimus'   => 'octingenti',
        'nongentesimus'     => 'nongenti',
        # Thousands
        'millesimus'   => 'mille',
    );

    # Compound teen ordinals (13-17): two-word ordinal → fused cardinal
    # e.g. "tertius decimus" → "tredecim" (not "tres decem")
    my %compound_teens = (
        'tertius decimus'   => 'tredecim',
        'tertia decima'     => 'tredecim',
        'quartus decimus'   => 'quattuordecim',
        'quarta decima'     => 'quattuordecim',
        'quintus decimus'   => 'quindecim',
        'quinta decima'     => 'quindecim',
        'sextus decimus'    => 'sedecim',
        'sexta decima'      => 'sedecim',
        'septimus decimus'  => 'septendecim',
        'septima decima'    => 'septendecim',
    );
    return $compound_teens{$input} if exists $compound_teens{$input};

    # Compound: "centesimus quartus" → convert each part.
    # In Latin compound ordinals, each component is an ordinal form.
    # However, for thousands like "quinque millesimus", the multiplier
    # ("quinque") is already cardinal — pass it through if not recognized.
    # For compounds ending in a two-word teen ordinal, handle the last two words together.
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;

        # Check if last two words form a compound teen ordinal
        if (@words >= 2) {
            my $last_two = $words[-2] . ' ' . $words[-1];
            if (exists $compound_teens{$last_two}) {
                pop @words; pop @words;
                my @cardinals;
                my $any = 0;
                for my $word (@words) {
                    my $card = ordinal2cardinal($word);
                    if (defined $card) {
                        push @cardinals, $card;
                        $any = 1;
                    } else {
                        push @cardinals, $word;  # pass through cardinal multipliers
                    }
                }
                push @cardinals, $compound_teens{$last_two};
                return join ' ', @cardinals;
            }
        }

        my @cardinals;
        my $any = 0;
        for my $word (@words) {
            my $card = ordinal2cardinal($word);
            if (defined $card) {
                # "mille" after a multiplier must become "milia" (plural)
                if ($card eq 'mille' && @cardinals > 0) {
                    $card = 'milia';
                }
                push @cardinals, $card;
                $any = 1;
            } else {
                push @cardinals, $word;  # pass through cardinal multipliers
            }
        }
        return $any ? join(' ', @cardinals) : undef;
    }

    return $ordinal_to_cardinal{$input} if exists $ordinal_to_cardinal{$input};

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::LAT::Word2Num - Word to number conversion in Latin


=head1 VERSION

version 0.2603300

Lingua::LAT::Word2Num is a module for converting Latin numerals into
numbers. Converts whole numbers from 0 up to 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LAT::Word2Num;

 my $num = Lingua::LAT::Word2Num::w2n( 'septendecim' );

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

Convert Latin text representation to number.
You can specify a numeral from interval [0,999_999].

Handles Latin's subtractive forms (e.g. duodeviginti = 18,
undetriginta = 29) and the additive exception for 98.

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'primus', 'tertius', 'vicesimus')
  =>  str    cardinal text (e.g. 'unus', 'tres', 'viginti')
      undef  if input is not recognised as an ordinal

Convert Latin ordinal text to cardinal text (morphological reversal).
Handles all three genders (-us/-a/-um), subtractive forms
(duodevicesimus, undevicesimus), and compound ordinals.

=item B<lat_numerals> (void)

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
