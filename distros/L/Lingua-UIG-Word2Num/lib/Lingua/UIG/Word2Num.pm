# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::UIG::Word2Num;
# ABSTRACT: Word to number conversion in Uyghur

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = uig_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/\s+/ /g;
    $input =~ s/^\s+|\s+$//g;

    return $parser->numeral($input);
}

# }}}
# {{{ uig_numerals              create parser for uyghur numerals

sub uig_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       /نۆل/      {  0 }
                  | /بىر/      {  1 }
                  | /ئىككى/    {  2 }
                  | /ئۈچ/      {  3 }
                  | /تۆت/      {  4 }
                  | /بەش/      {  5 }
                  | /ئالتە/    {  6 }
                  | /يەتتە/    {  7 }
                  | /سەككىز/   {  8 }
                  | /توققۇز/   {  9 }

      tens:         /ئون/      { 10 }
                  | /يىگىرمە/  { 20 }
                  | /ئوتتۇز/   { 30 }
                  | /قىرىق/    { 40 }
                  | /ئەللىك/   { 50 }
                  | /ئاتمىش/   { 60 }
                  | /يەتمىش/   { 70 }
                  | /سەكسەن/   { 80 }
                  | /توقسان/   { 90 }

      deca:         tens number          { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number /يۈز/ deca    { $item[1] * 100 + $item[3] }
                  | number /يۈز/         { $item[1] * 100            }
                  | /يۈز/ deca           { 100 + $item[2]            }
                  | /يۈز/               { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd /مىڭ/ hOd    { $item[1] * 1000 + $item[3] }
                | hOd /مىڭ/        { $item[1] * 1000            }
                | /مىڭ/ hOd        { 1000 + $item[2]            }
                | /مىڭ/            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /مىليون/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /مىليون/       { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::UIG::Word2Num - Word to number conversion in Uyghur


=head1 VERSION

version 0.2603300

Lingua::UIG::Word2Num is a module for converting Uyghur numerals (Arabic
script) into numbers. Converts whole numbers from 0 up to 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::UIG::Word2Num qw(w2n);

 my $num = w2n( 'يۈز يىگىرمە ئۈچ' );

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

=item B<uig_numerals> (void)

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
