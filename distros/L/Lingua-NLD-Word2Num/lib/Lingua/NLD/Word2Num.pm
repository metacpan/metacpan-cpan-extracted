# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::NLD::Word2Num;
# ABSTRACT: Word to number conversion in Dutch

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603270';
my  $parser  = nld_numerals();

# }}}
# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input = lc $input;
    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}

# }}}
# {{{ nld_numerals                                 create parser for numerals

sub nld_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'negentien'  { $return = 19; }                          # try to find a word from 0 to 19
        |     'achtien'    { $return = 18; }
        |     'zeventien'  { $return = 17; }
        |     'zestien'    { $return = 16; }
        |     'vijftien'   { $return = 15; }
        |     'veertien'   { $return = 14; }
        |     'dertien'    { $return = 13; }
        |     'twaalf'     { $return = 12; }
        |     'elf'        { $return = 11; }
        |     'tien'       { $return = 10; }
        |     'negen'      { $return = 9; }
        |     'acht'       { $return = 8; }
        |     'zeven'      { $return = 7; }
        |     'zes'        { $return = 6; }
        |     'vijf'       { $return = 5; }
        |     'vier'       { $return = 4; }
        |     'drie'       { $return = 3; }
        |     'twee'       { $return = 2; }
        |     /(een|één)/        { $return = 1; }
        |     'nul'        { $return = 0; }

      tens:   'twintig'  { $return = 20; }                            # try to find a word that represents
        |     'dertig'   { $return = 30; }                            # values 20,30,..,90
        |     'veertig'  { $return = 40; }
        |     'vijftig'  { $return = 50; }
        |     'zestig'   { $return = 60; }
        |     'zeventig' { $return = 70; }
        |     'tachtig'  { $return = 80; }
        |     'negentig' { $return = 90; }

      decade: number(?) 'en' tens(?) number(?)                        # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }
        |     tens(?) number(?)
              { $return = -1;
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);
                    $return  = $$_[0] if ($return == -1);
                  }
                }
                $return = undef if ($return == -1);
              }

      century: number(?) 'honderd' decade(?)                          # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "honderd") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
                 $return ||= undef;
               }

    millenium: century(?) decade(?) 'duizend' century(?) decade(?)    # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "duizend") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'miljoen'                                              # from 1.000.000 to 999.999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "miljoen") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
                 $return ||= undef;
               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::NLD::Word2Num - Word to number conversion in Dutch


=head1 VERSION

version 0.2603270

Lingua::NLD::Word2Num is module for converting text containing number
representation in Dutch back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::NLD::Word2Num;

 my $num = Lingua::NLD::Word2Num::w2n( 'dertien' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to be converted
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.

=item B<nld_numerals> (void)

  =>  obj  new parser object

Internal pareser.

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

Copyright (c) PetaMem, s.r.o. 2003-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
