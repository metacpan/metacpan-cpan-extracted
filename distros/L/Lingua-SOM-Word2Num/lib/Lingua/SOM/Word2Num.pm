# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::SOM::Word2Num;
# ABSTRACT: Word to number conversion in Somali

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = som_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/\s+/ /g;
    $input =~ s/^\s+|\s+$//g;

    return $parser->numeral($input);
}

# }}}
# {{{ som_numerals              create parser for somali numerals

sub som_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'eber'       {  0 }
                  | /k[oó]w/     {  1 }
                  | /koób/       {  1 }
                  | /l[aá]ba/    {  2 }
                  | /lab[aá]/    {  2 }
                  | /s[aá]ddex/  {  3 }
                  | /[aá]far/    {  4 }
                  | /sh[aá]n/    {  5 }
                  | /l[ií]x/     {  6 }
                  | /toddob[aá]/ {  7 }
                  | /sidd[eé][eé]d/ {  8 }
                  | /saga[aá]l/  {  9 }

      tens:         /laba[aá]tan/    { 20 }
                  | /s[oó]ddon/      { 30 }
                  | /af[aá]rtan/     { 40 }
                  | /k[oó]nton/      { 50 }
                  | /l[ií]xdan/      { 60 }
                  | /toddoba[aá]tan/ { 70 }
                  | /sidde[eé]tan/   { 80 }
                  | /saga[aá]shan/   { 90 }

      deca:         number 'iyo' tens     { $item[1] + $item[3] }
                  | number 'iyo' 'toban'  { $item[1] + 10       }
                  | tens
                  | 'toban'               { 10 }
                  | number

      hecto:        number /boq[oó]l/ 'iyo' deca  { $item[1] * 100 + $item[4] }
                  | number /boq[oó]l/              { $item[1] * 100            }
                  | /boq[oó]l/ 'iyo' deca          { 100 + $item[3]            }
                  | /boq[oó]l/                     { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd /k[uú]n/ 'iyo' hOd     { $item[1] * 1000 + $item[4] }
                | hOd /k[uú]n/               { $item[1] * 1000            }
                | /k[uú]n/ 'iyo' hOd         { 1000 + $item[3]            }
                | /k[uú]n/                   { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /maly[uú]un/ 'iyo' kOhOd  { $item[1] * 1_000_000 + $item[4] }
                | hOd /maly[uú]un/               { $item[1] * 1_000_000 }
                | /maly[uú]un/ 'iyo' kOhOd       { 1_000_000 + $item[3] }
                | /maly[uú]un/                   { 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SOM::Word2Num - Word to number conversion in Somali


=head1 VERSION

version 0.2603300

Lingua::SOM::Word2Num is a module for converting Somali numerals into
numbers. Converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SOM::Word2Num qw(w2n);

 my $num = w2n( 'koób iyo labaátan' );

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

=item B<som_numerals> (void)

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
