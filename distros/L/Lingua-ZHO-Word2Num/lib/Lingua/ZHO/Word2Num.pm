# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::ZHO::Word2Num;
# ABSTRACT: Word to number conversion in Chinese

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603260';
my  $parser  = zho_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    return 0 if ($input =~ m{\b(nul|ling)\b}xmsi || $input =~ m{\A零\z}xms);

    $input .= " "; # Grant space at the end

    return $parser->numeral($input) || undef;
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
        |     'Liu ' { $return = 6; }
        |     'Qi '  { $return = 7; }
        |     'Ba '  { $return = 8; }
        |     'Jiu ' { $return = 9; }
        |     'Shi ' { $return = 10; }
        |     /零/  { $return = 0; }
        |     /一/  { $return = 1; }
        |     /二/  { $return = 2; }
        |     /三/  { $return = 3; }
        |     /四/  { $return = 4; }
        |     /五/  { $return = 5; }
        |     /六/  { $return = 6; }
        |     /七/  { $return = 7; }
        |     /八/  { $return = 8; }
        |     /九/  { $return = 9; }
        |     /十/  { $return = 10; }

      tens: 'YiShi '  { $return = 10; }                               # try to find a word that represents
        |   'ErShi '  { $return = 20; }                               # values 20,30,..,90
        |   'SanShi ' { $return = 30; }
        |   'SiShi '  { $return = 40; }
        |   'WuShi '  { $return = 50; }
        |   'LiuShi ' { $return = 60; }
        |   'QiShi '  { $return = 70; }
        |   'BaShi '  { $return = 80; }
        |   'JiuShi ' { $return = 90; }
        |   /一十/ { $return = 10; }
        |   /二十/ { $return = 20; }
        |   /三十/ { $return = 30; }
        |   /四十/ { $return = 40; }
        |   /五十/ { $return = 50; }
        |   /六十/ { $return = 60; }
        |   /七十/ { $return = 70; }
        |   /八十/ { $return = 80; }
        |   /九十/ { $return = 90; }

      hundreds: 'YiBai '  { $return = 100; }                          # try to find a word that represents
        |       'ErBai '  { $return = 200; }                          # values 100,200,..,900
        |       'SanBai ' { $return = 300; }
        |       'SiBai '  { $return = 400; }
        |       'WuBai '  { $return = 500; }
        |       'LiuBai ' { $return = 600; }
        |       'QiBai '  { $return = 700; }
        |       'BaBai '  { $return = 800; }
        |       'JiuBai ' { $return = 900; }
        |       /一百/ { $return = 100; }
        |       /二百/ { $return = 200; }
        |       /三百/ { $return = 300; }
        |       /四百/ { $return = 400; }
        |       /五百/ { $return = 500; }
        |       /六百/ { $return = 600; }
        |       /七百/ { $return = 700; }
        |       /八百/ { $return = 800; }
        |       /九百/ { $return = 900; }

      thousands: 'YiQian '  { $return = 1000; }                       # try to find a word that represents
        |        'ErQian '  { $return = 2000; }                       # values 1000,2000,..,9000
        |        'SanQian ' { $return = 3000; }
        |        'SiQian '  { $return = 4000; }
        |        'WuQian '  { $return = 5000; }
        |        'LiuQian ' { $return = 6000; }
        |        'QiQian '  { $return = 7000; }
        |        'BaQian '  { $return = 8000; }
        |        'JiuQian ' { $return = 9000; }
        |        /一千/ { $return = 1000; }
        |        /二千/ { $return = 2000; }
        |        /三千/ { $return = 3000; }
        |        /四千/ { $return = 4000; }
        |        /五千/ { $return = 5000; }
        |        /六千/ { $return = 6000; }
        |        /七千/ { $return = 7000; }
        |        /八千/ { $return = 8000; }
        |        /九千/ { $return = 9000; }

      tenthousands: 'YiWan '  { $return = 10000; }                    # try to find a word that represents
        |           'ErWan '  { $return = 20000; }                    # values 10000,20000,..,90000
        |           'SanWan ' { $return = 30000; }
        |           'SiWan '  { $return = 40000; }
        |           'WuWan '  { $return = 50000; }
        |           'LiuWan ' { $return = 60000; }
        |           'QiWan '  { $return = 70000; }
        |           'BaWan '  { $return = 80000; }
        |           'JiuWan ' { $return = 90000; }
        |           /一萬/ { $return = 10000; }
        |           /二萬/ { $return = 20000; }
        |           /三萬/ { $return = 30000; }
        |           /四萬/ { $return = 40000; }
        |           /五萬/ { $return = 50000; }
        |           /六萬/ { $return = 60000; }
        |           /七萬/ { $return = 70000; }
        |           /八萬/ { $return = 80000; }
        |           /九萬/ { $return = 90000; }

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
               wanmark                                                # from 1.000.000 to 999.999.999.999
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

      wanmark: ' Wan ' { $return = "Wan"; }
        |      /萬/ { $return = "Wan"; }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::ZHO::Word2Num - Word to number conversion in Chinese


=head1 VERSION

version 0.2603260

Lingua::ZHO::Word2Num is module for converting text containing number
representation in Chinese back into number. Converts whole numbers
from 0 up to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ZHO::Word2Num;

 my $num = Lingua::ZHO::Word2Num::w2n( 'SiShi Er' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str  string to convert
  =>  num  converted number

Convert text representation to number.

=item B<zho_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2003-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
