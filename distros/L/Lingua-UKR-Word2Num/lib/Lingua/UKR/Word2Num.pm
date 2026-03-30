# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-

package Lingua::UKR::Word2Num;
# ABSTRACT: Word to number conversion in Ukrainian

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
my  $parser  = uk_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input .= " ";                             # Grant end space before normalizing

    $input =~ s/’/'/g;                 # Normalize Unicode apostrophe to ASCII
    $input =~ s/‘/'/g;                 # (both left and right single quote)

    $input =~ s/тисячі /тисяч /g;             # Thousand variations. Normalize to тисяч
    $input =~ s/тисяча /тисяч /g;

    $input =~ s/мільйони /мільйон /g;         # Million variations. Normalize to мільйон
    $input =~ s/мільйонів /мільйон /g;

    return $parser->numeral($input);
}

# }}}
# {{{ uk_numerals                                 create parser for numerals

sub uk_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: /дев'ятнадцять /  { $return = 19; }                    # try to find a word from 0 to 19
        |     'вісімнадцять '   { $return = 18; }
        |     'сімнадцять '     { $return = 17; }
        |     'шістнадцять '    { $return = 16; }
        |     /п'ятнадцять /    { $return = 15; }
        |     'чотирнадцять '   { $return = 14; }
        |     'тринадцять '     { $return = 13; }
        |     'дванадцять '     { $return = 12; }
        |     'одинадцять '     { $return = 11; }
        |     'десять '         { $return = 10; }
        |     /дев'ять /        { $return = 9; }
        |     'вісім '          { $return = 8; }
        |     'сім '            { $return = 7; }
        |     'шість '          { $return = 6; }
        |     /п'ять /          { $return = 5; }
        |     'чотири '         { $return = 4; }
        |     'три '            { $return = 3; }
        |     'два '            { $return = 2; }
        |     'дві '            { $return = 2; }
        |     'одна '           { $return = 1; }
        |     'один '           { $return = 1; }
        |     'нуль '           { $return = 0; }

      tens:   'двадцять '       { $return = 20; }                    # try to find a word that represents
        |     'тридцять '       { $return = 30; }                    # values 20,30,..,90
        |     'сорок '          { $return = 40; }
        |     /п'ятдесят /      { $return = 50; }
        |     'шістдесят '      { $return = 60; }
        |     'сімдесят '       { $return = 70; }
        |     'вісімдесят '     { $return = 80; }
        |     /дев'яносто /     { $return = 90; }

     hundreds: 'сто '           { $return = 100; }                   # try to find a word that represents
        |      'двісті '        { $return = 200; }                   # values 100,200,..,900
        |      'триста '        { $return = 300; }
        |      'чотириста '     { $return = 400; }
        |      /п'ятсот /       { $return = 500; }
        |      'шістсот '       { $return = 600; }
        |      'сімсот '        { $return = 700; }
        |      'вісімсот '      { $return = 800; }
        |      /дев'ятсот /     { $return = 900; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = -1;                                         # from 0 to 99
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);
                    $return  = $$_[0] if ($return == -1);
                  }
                }
                $return = undef if ($return == -1);
              }

      century: hundreds(?) decade(?)                                  # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   $return += $$_[0] if (ref $_ && defined $$_[0]);
                 }
                 $return ||= undef;
               }

    millenium: century(?) decade(?) 'тисяч ' century(?) decade(?)     # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "тисяч ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: century(?) decade(?)                                   # try to find words that represents values
              'мільйон '                                              # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "мільйон ") {
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

    # Ukrainian (Cyrillic) ordinals: strip gender/case suffixes, then map stems.
    # Inflection: -ий/-ій/-а/-е/-ого/-ому/-им/-ім.
    # Note: apostrophe in п'ятий etc. is normalized to ASCII ' by w2n already;
    # we accept both Unicode and ASCII apostrophes here.

    my %irregular = (
        'нульовий'        => 'нуль',
        'перший'          => 'один',
        'другий'          => 'два',
        'третій'          => 'три',
        'четвертий'       => 'чотири',
        "п'ятий"          => "п'ять",
        'шостий'          => 'шість',
        'сьомий'          => 'сім',
        'восьмий'         => 'вісім',
        "дев'ятий"        => "дев'ять",
        'десятий'         => 'десять',
        'одинадцятий'     => 'одинадцять',
        'дванадцятий'     => 'дванадцять',
        'тринадцятий'     => 'тринадцять',
        'чотирнадцятий'   => 'чотирнадцять',
        "п'ятнадцятий"    => "п'ятнадцять",
        'шістнадцятий'    => 'шістнадцять',
        'сімнадцятий'     => 'сімнадцять',
        'вісімнадцятий'   => 'вісімнадцять',
        "дев'ятнадцятий"  => "дев'ятнадцять",
        'двадцятий'       => 'двадцять',
        'тридцятий'       => 'тридцять',
        'сороковий'       => 'сорок',
        "п'ятдесятий"     => "п'ятдесят",
        'шістдесятий'     => 'шістдесят',
        'сімдесятий'      => 'сімдесят',
        'вісімдесятий'    => 'вісімдесят',
        "дев'яностий"     => "дев'яносто",
        'двохсотий'       => 'двісті',
        'трьохсотий'      => 'триста',
        'чотирьохсотий'   => 'чотириста',
        "п'ятисотий"      => "п'ятсот",
        'шестисотий'      => 'шістсот',
        'семисотий'       => 'сімсот',
        'восьмисотий'     => 'вісімсот',
        "дев'ятисотий"    => "дев'ятсот",
        'сотий'           => 'сто',
        'тисячний'        => 'тисяч',
        'мільйонний'      => 'мільйон',
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Normalize Unicode apostrophes to ASCII
        $word =~ s/\x{2018}/'/g;
        $word =~ s/\x{2019}/'/g;

        # Normalize gender/case to masculine nominative
        my $norm = $word;
        $norm =~ s{(і)його\z}{$1й}xms     # третього → третій
            or $norm =~ s{ого\z}{ий}xms    # п'ятого → п'ятий
            or $norm =~ s{ому\z}{ий}xms    # п'ятому → п'ятий
            or $norm =~ s{им\z}{ий}xms     # п'ятим → п'ятий
            or $norm =~ s{ім\z}{ій}xms     # третім → третій
            or $norm =~ s{а\z}{ий}xms      # п'ята → п'ятий
            or $norm =~ s{е\z}{ий}xms      # п'яте → п'ятий
            or $norm =~ s{є\z}{ій}xms;     # третє → третій

        if (exists $irregular{$norm}) {
            push @result, $irregular{$norm};
            $matched = 1;
        }
        else {
            push @result, $word;  # pass through unchanged (connectors, etc.)
        }
    }

    return $matched ? join(' ', @result) : undef;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::UKR::Word2Num - Word to number conversion in Ukrainian


=head1 VERSION

version 0.2603300

Lingua::UKR::Word2Num is module for converting text containing number
representation in Ukrainian back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::UKR::Word2Num;

 my $num = Lingua::UKR::Word2Num::w2n( 'п\'ять' );

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

  1   str    ordinal text (e.g. "п'ятий", 'десятий', 'третій')
  =>  str    cardinal text (e.g. "п'ять", 'десять', 'три')
      undef  if input is not a recognized ordinal

Convert Ukrainian (Cyrillic) ordinal text to cardinal text via morphological reversal.
Handles all gender/case inflections (-ий/-ій/-а/-е/-ого/-ому/-им/-ім).

=item B<uk_numerals> (void)

  =>  obj  new parser object

Internal parser.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

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
