# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::SWE::Word2Num;
# ABSTRACT: Word to number conversion in Swedish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603270';
my $parser = sv_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ sv_numerals                                 create parser for numerals

sub sv_numerals {
    return Parse::RecDescent->new(q{

      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |      number    { return $item[1]; }
        |                { return undef; }

      number: 'nitton'  { $return = 19; }                             # try to find a word from 0 to 19
        |     'arton'   { $return = 18; }
        |     'sjutton' { $return = 17; }
        |     'sexton'  { $return = 16; }
        |     'femton'  { $return = 15; }
        |     'fjorton' { $return = 14; }
        |     'tretton' { $return = 13; }
        |     'tolv'    { $return = 12; }
        |     'elva'    { $return = 11; }
        |     'tio'     { $return = 10; }
        |     'nio'     { $return = 9; }
        |     'åtta'    { $return = 8; }
        |     'sju'     { $return = 7; }
        |     'sex'     { $return = 6; }
        |     'fem'     { $return = 5; }
        |     'fyra'    { $return = 4; }
        |     'tre'     { $return = 3; }
        |     'två'     { $return = 2; }
        |     'ett'     { $return = 1; }
        |     'noll'    { $return = 0; }

      tens:   'tjugo'   { $return = 20; }                             # try to find a word that represents
        |     'trettio' { $return = 30; }                             # values 20,30,..,90
        |     'fyrtio'  { $return = 40; }
        |     'femtio'  { $return = 50; }
        |     'sextio'  { $return = 60; }
        |     'sjutio'  { $return = 70; }
        |     'åttio'   { $return = 80; }
        |     'nittio'  { $return = 90; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
                $return = undef if(!$return);
              }
      century: number(?) 'hundra' decade(?)                           # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq 'hundra') {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
                 $return = undef if(!$return);
               }
    millenium: century(?) decade(?) 'tusen' century(?) decade(?)      # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "tusen") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return = undef if(!$return);
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'miljoner'                                             # from 1.000.000 to 999.999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq 'miljoner') {
                     $return = $return ? $return * 1000000 : 1000000;
                   }
                 }
                 $return = undef if(!$return);
               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::SWE::Word2Num - Word to number conversion in Swedish


=head1 VERSION

version 0.2603270

Lingua::SWE::Word2Num is module for converting text containing number
representation in svedish back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SWE::Word2Num;

 my $num = Lingua::SWE::Word2Num::w2n( 'fyrtiotve' );

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
  =>  undef  if input string is not known

Convert text representation to number.

=item B<sv_numerals> (void)

  =>  obj  new parser object

Internal parser.

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

Copyright (c) PetaMem, s.r.o. 2003-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
