# For Emacs: -*- mode:cperl; mode:folding; -*-

package Lingua::JPN::Word2Num;
# ABSTRACT: Word 2 number conversion in JPN.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;

use Parse::RecDescent;
# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
our $INFO    = {
    rev  => '$Rev: 682 $',
};

my $parser = ja_numerals();

# }}}

# {{{ w2n                                         convert number to text
#
sub w2n :Export {
    my $input = shift // return;

    $input =~ s/san-byaku/san hyaku/g;    # Spoken language exceptions, that are being corrected
    $input =~ s/ro-p-pyaku/roku hyaku/g;  # to use one unique logic
    $input =~ s/ha-p-pyaku/hachi hyaku/g;
    $input =~ s/san-zen/san sen/g;
    $input =~ s/ha-s-sen/hachi sen/g;
    $input =~ s/hyaku-man/hyman/g;

    $input =~ s/-/ /g;                   # make space an standard for everything

    return $parser->numeral($input);
}
# }}}
# {{{ ja_numerals                                 create parser for numerals
#
sub ja_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: tenmillion   { return $item[1]; }
        |      million      { return $item[1]; }
        |      tenmillenium { return $item[1]; }
        |      millenium    { return $item[1]; }
        |      century      { return $item[1]; }
        |      decade       { return $item[1]; }
        |                   { return undef; }

      number: 'ichi'  { $return = 1; }                                # try to find a word from 1 to 9
        |     'ni'    { $return = 2; }
        |     'san'   { $return = 3; }
        |     'yon'   { $return = 4; }
        |     'go'    { $return = 5; }
        |     'roku'  { $return = 6; }
        |     'nana'  { $return = 7; }
        |     'hachi' { $return = 8; }
        |     'kyu'   { $return = 9; }
        |     'ju'    { $return = 10; }

      decade: number(?) number(?) number(?)                           # try to find words that represents values
              { my @s;                                                # from 0 to 99
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    push(@s,$$_[0]);
                  }
                }

                $return = shift @s;
                $return = $return * $s[0] + $s[1] if (scalar(@s) == 2);
                $return = $return * $s[0] if (scalar(@s) == 1 && $s[0] == 10); # The order of the 10 multiplier
                $return = $return + $s[0] if (scalar(@s) == 1 && $s[0] != 10); # defines sum or multiply
              }

      century: number(?) 'hyaku' decade(?)                            # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "hyaku") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
               }

    millenium: century(?) decade(?) 'sen' century(?) decade(?)        # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 9.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "sen") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
               }

   tenmillenium: millenium(?) century(?) decade(?)                    # try to find words that represents values
               'man'                                                  # from 10.000 to 999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "man") {
                     $return = ($return>0) ? $return * 10000 : 10000;
                   }
                 }
               }

   million: tenmillenium(?) millenium(?) century(?) decade(?)            # try to find words that represents values
            'hyman'                                                      # from  1.000.000 to 999.999.999
            tenmillenium(?) millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "hyman") {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
                   }
                 }
               }

   tenmillion: million(?) tenmillenium(?) millenium(?)                   # try to find words that represents values
               century(?) decade(?)                                      # from 100.000.000 to 999.999.999.999
               'oku'
               million(?) tenmillenium(?) millenium(?)
                century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "oku") {
                     $return = ($return>0) ? $return * 100000000 : 100000000;
                   }
                 }
               }
    });
}
# }}}

1;

__END__

# {{{ POD HEAD

=head1 NAME

Lingua::JPN::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Japanese.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::JPN::Word2Num;

 my $num = Lingua::JPN::Word2Num::w2n( 'sen ni hyaku san ju yon' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in JPN.

Lingua::JPN::Word2Num is module for converting text containing number
representation in Japanese back into number. Converts whole numbers from 0 up
to 999 999 999 999.

=cut

# }}}
# {{{ Functions reference

=pod

=head2 Functions Reference

=over

=item w2n (positional)

  1   string  string to convert
  =>  number  converted number
      undef   if input string is not known

Convert text representation to number.

=item ja_numerals

Internal parser.

=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 EXPORT_OK

w2n

=head1 KNOWN BUGS

None.

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:
   Richard C. Jelinek <info@petamem.com>
 initial coding after specifications by R. Jelinek:
   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
