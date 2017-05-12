# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::ZHO::Word2Num;
# ABSTRACT: Word 2 number conversion in ZHO.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use Perl6::Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations

our $VERSION = 0.0682;
my  $parser  = zho_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
    my $input = shift // return;

    $input .= " "; # Grant space at the end

    return $parser->numeral($input);
}

# }}}
# {{{ zho_numerals                                create parser for numerals

sub zho_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million    { return $item[1]; }                        # root parse. go from maximum to minimum value
        |      millenium2 { return $item[1]; }
        |      millenium1 { return $item[1]; }
        |      century    { return $item[1]; }
        |      decade     { return $item[1]; }
        |                 { return undef; }

      number: 'nul ' { $return = 0; }                                 # try to find a word from 0 to 10
        |     'Yi '  { $return = 1; }
        |     'Er '  { $return = 2; }
        |     'San ' { $return = 3; }
        |     'Si '  { $return = 4; }
        |     'Wu '  { $return = 5; }
        |     'Liu ' { $return = 6; }        |     'Qi '  { $return = 7; }
        |     'Ba '  { $return = 8; }
        |     'Jiu ' { $return = 9; }
        |     'Shi ' { $return = 10; }

      tens: 'YiShi '  { $return = 10; }                               # try to find a word that representates
        |   'ErShi '  { $return = 20; }                               # values 20,30,..,90
        |   'SanShi ' { $return = 30; }
        |   'SiShi '  { $return = 40; }
        |   'WuShi '  { $return = 50; }
        |   'LiuShi ' { $return = 60; }
        |   'QiShi '  { $return = 70; }
        |   'BaShi '  { $return = 80; }
        |   'JiuShi ' { $return = 90; }

      hundreds: 'YiBai '  { $return = 100; }                          # try to find a word that representates
        |       'ErBai '  { $return = 200; }                          # values 100,200,..,900
        |       'SanBai ' { $return = 300; }
        |       'SiBai '  { $return = 400; }
        |       'WuBai '  { $return = 500; }
        |       'LiuBai ' { $return = 600; }
        |       'QiBai '  { $return = 700; }
        |       'BaBai '  { $return = 800; }
        |       'JiuBai ' { $return = 900; }

      thousands: 'YiQian '  { $return = 1000; }                       # try to find a word that representates
        |        'ErQian '  { $return = 2000; }                       # values 1000,2000,..,9000
        |        'SanQian ' { $return = 3000; }
        |        'SiQian '  { $return = 4000; }
        |        'WuQian '  { $return = 5000; }
        |        'LiuQian ' { $return = 6000; }
        |        'QiQian '  { $return = 7000; }
        |        'BaQian '  { $return = 8000; }
        |        'JiuQian ' { $return = 9000; }

      tenthousands: 'YiWan '  { $return = 10000; }                    # try to find a word that representates
        |           'ErWan '  { $return = 20000; }                    # values 10000,20000,..,90000
        |           'SanWan ' { $return = 30000; }
        |           'SiWan '  { $return = 40000; }
        |           'WuWan '  { $return = 50000; }
        |           'LiuWan ' { $return = 60000; }
        |           'QiWan '  { $return = 70000; }
        |           'BaWan '  { $return = 80000; }
        |           'JiuWan ' { $return = 90000; }

      decade: tens(?) number(?) number(?)                             # try to find words that represents values
              { $return = 0;                                          # from 0 to 20
                for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                }
              }

      century:  hundreds(?) decade(?)                                 # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                  $return += $$_[0] if (ref $_ && defined $$_[0]);
                 }
               }

    millenium1: thousands(1) century(?)                               # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0] if (ref $_ && defined $$_[0]);
                   }
                 }
               }

    millenium2: tenthousands(1) thousands(?)  century(?) decade(?)    # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0] if (ref $_ && defined $$_[0]);
                   }
                 }
               }

      million: millenium2(?) millenium1(?) century(?) decade(?)       # try to find words that represents values
               ' Wan '                                                # from 1.000.000 to 999.999.999.999
               millenium2(?) millenium1(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "Wan") {
                     $return = ($return>0) ? $return * 100000 : 100000;
                   }
                 }
               }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::ZHO::Word2Num

=head1 VERSION

version 0.0682

text to positive number convertor for Chinese.
Input text must be encoded in utf-8.

=head2 $Rev: 682 $

ISO 639-3 namespace.

=head1 SYNOPSIS

 use Lingua::ZHO::Word2Num;

 my $num = Lingua::ZHO::Word2Num::w2n( 'SiShi Er' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=head1 DESCRIPTION

Word 2 number conversion in ZHO.

Lingua::ZHO::Word2Num is module for converting text containing number
representation in Chinese back into number. Converts whole numbers
from 0 up to 999 999 999 999.

=cut

# }}}
# {{{ Functions reference

=head2 Functions Reference

=over

=item w2n (positional)

Convert text representation to number.

=item zho_numerals

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

Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2003-present

=head2 LICENSE

Artistic license or BSD license.

=cut

# }}}
