# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::YID::Word2Num;
# ABSTRACT: Word to number conversion in Yiddish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = yid_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ yid_numerals              create parser for yiddish numerals

sub yid_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       /דרײַצן/          { 13 }
                  | /פערצן/           { 14 }
                  | /פופצן/           { 15 }
                  | /זעכצן/           { 16 }
                  | /זיבעצן/          { 17 }
                  | /אַכצן/           { 18 }
                  | /נײַנצן/          { 19 }
                  | /נול/             {  0 }
                  | /אײנס?/          {  1 }
                  | /צװײ/            {  2 }
                  | /דרײַ/            {  3 }
                  | /פֿיר/            {  4 }
                  | /פֿינף/           {  5 }
                  | /זעקס/            {  6 }
                  | /זיבן/            {  7 }
                  | /אכט/             {  8 }
                  | /נײַן/            {  9 }
                  | /צען/             { 10 }
                  | /עלף/             { 11 }
                  | /צוועלף/          { 12 }

      tens:         /צוואַנציק/       { 20 }
                  | /דרײַסיק/         { 30 }
                  | /פערציק/          { 40 }
                  | /פופציק/          { 50 }
                  | /זעכציק/          { 60 }
                  | /זיבעציק/         { 70 }
                  | /אַכציק/          { 80 }
                  | /נײַנציק/         { 90 }

      deca:         /און/ deca                  { $item[2]            }
                  | number /און/ tens            { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number /הונדערט/ deca       { $item[1] * 100 + $item[3] }
                  | number /הונדערט/            { $item[1] * 100            }
                  | /הונדערט/                   { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd /טויזנט/ hOd             { $item[1] * 1000 + $item[3] }
                | hOd /טויזנט/                 { $item[1] * 1000            }

      kOhOd:      kilo
                | hOd

      mega:       hOd /מיליאָן/ kOhOd           { $item[1] * 1_000_000 + $item[3] }
                | hOd /מיליאָן/                 { $item[1] * 1_000_000 }
    });
}

# }}}
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Inverse of Yiddish ordinal morphology: restore cardinal from ordinal text.
    # Parser expects: אײנס (1), צװײ (2), דרײַ (3), זיבן (7), אכט (8)

    # Irregulars (standalone or as final element of compound)
    $input =~ s{ערשטער\z}{אײנס}xms     and return $input;
    $input =~ s{צווייטער\z}{צװײ}xms    and return $input;
    $input =~ s{דריטער\z}{דרײַ}xms      and return $input;
    $input =~ s{זעקסטער\z}{זעקס}xms    and return $input;  # 6th: stem 's' consumed by -סטער
    $input =~ s{זיבעטער\z}{זיבן}xms    and return $input;
    $input =~ s{אַכטער\z}{אכט}xms      and return $input;

    # Teens: ordinal stem differs from parser expectation
    $input =~ s{פֿירצנטער\z}{פערצן}xms  and return $input;  # 14th: פֿירצן→פערצן for parser
    $input =~ s{דרײַצנטער\z}{דרײַצן}xms and return $input;  # 13th
    $input =~ s{פֿינפצנטער\z}{פופצן}xms and return $input;  # 15th: פֿינפצן→פופצן for parser
    $input =~ s{זעכצנטער\z}{זעכצן}xms  and return $input;  # 16th
    $input =~ s{זיבעצנטער\z}{זיבעצן}xms and return $input; # 17th
    $input =~ s{אכטצנטער\z}{אַכצן}xms  and return $input;  # 18th: אכטצן→אַכצן for parser
    $input =~ s{נײַנצנטער\z}{נײַנצן}xms and return $input;  # 19th

    # Regular: strip סטער (20+)
    $input =~ s{סטער\z}{}xms           and return $input;

    # Regular: strip טער (4-19)
    $input =~ s{טער\z}{}xms            and return $input;

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::YID::Word2Num - Word to number conversion in Yiddish

=head1 VERSION

version 0.2603300

Lingua::YID::Word2Num is a module for converting Yiddish numerals (Hebrew
script) into numbers. Converts whole numbers from 0 up to 999 999 999.
Input is expected to be in UTF-8.

Orthography follows the YIVO standard (Yidisher Visnshaftlekher Institut).

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::YID::Word2Num;

 my $num = Lingua::YID::Word2Num::w2n( 'זיבעצן' );
 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (Yiddish, Hebrew script)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (Hebrew script, e.g. 'דריטער', 'צוואַנציקסטער')
  =>  str    cardinal text (e.g. 'דרײַ', 'צוואַנציק')
      undef  if input is not recognised as an ordinal

Convert Yiddish ordinal text to cardinal text (morphological reversal).

=item B<yid_numerals> (void)

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
