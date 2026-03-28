# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::KOR::Word2Num;
# ABSTRACT: Word to number conversion in Korean

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603270';
my  $parser  = kor_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    # zero
    return 0 if ($input =~ m{\b(yeong)\b}xmsi || $input =~ m{\A영\z}xms);

    $input .= " "; # Grant space at the end

    return $parser->numeral($input) || undef;
}

# }}}
# {{{ kor_numerals                                create parser for numerals

sub kor_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: eok        { return $item[1]; }                        # root parse. go from maximum to minimum value
        |      man        { return $item[1]; }
        |      millenium2 { return $item[1]; }
        |      millenium1 { return $item[1]; }
        |      century    { return $item[1]; }
        |      decade     { return $item[1]; }
        |                 { return undef; }

      number: 'yeong ' { $return = 0; }                               # try to find a word from 0 to 9
        |     'il '    { $return = 1; }
        |     'sam '   { $return = 3; }
        |     'sa '    { $return = 4; }
        |     'o '     { $return = 5; }
        |     'yuk '   { $return = 6; }
        |     'chil '  { $return = 7; }
        |     'pal '   { $return = 8; }
        |     'gu '    { $return = 9; }
        |     'i '     { $return = 2; }
        |     /영/  { $return = 0; }
        |     /일/  { $return = 1; }
        |     /이/  { $return = 2; }
        |     /삼/  { $return = 3; }
        |     /사/  { $return = 4; }
        |     /오/  { $return = 5; }
        |     /육/  { $return = 6; }
        |     /칠/  { $return = 7; }
        |     /팔/  { $return = 8; }
        |     /구/  { $return = 9; }

      tens: 'ilsip '   { $return = 10; }                              # try to find a word that represents
        |   'isip '    { $return = 20; }                               # values 10,20,..,90
        |   'samsip '  { $return = 30; }
        |   'sasip '   { $return = 40; }
        |   'osip '    { $return = 50; }
        |   'yuksip '  { $return = 60; }
        |   'chilsip ' { $return = 70; }
        |   'palsip '  { $return = 80; }
        |   'gusip '   { $return = 90; }
        |   'sip '     { $return = 10; }
        |   /일십/ { $return = 10; }
        |   /이십/ { $return = 20; }
        |   /삼십/ { $return = 30; }
        |   /사십/ { $return = 40; }
        |   /오십/ { $return = 50; }
        |   /육십/ { $return = 60; }
        |   /칠십/ { $return = 70; }
        |   /팔십/ { $return = 80; }
        |   /구십/ { $return = 90; }
        |   /십/         { $return = 10; }

      hundreds: 'ilbaek '   { $return = 100; }                        # try to find a word that represents
        |       'ibaek '    { $return = 200; }                        # values 100,200,..,900
        |       'sambaek '  { $return = 300; }
        |       'sabaek '   { $return = 400; }
        |       'obaek '    { $return = 500; }
        |       'yukbaek '  { $return = 600; }
        |       'chilbaek ' { $return = 700; }
        |       'palbaek '  { $return = 800; }
        |       'gubaek '   { $return = 900; }
        |       'baek '     { $return = 100; }
        |       /일백/ { $return = 100; }
        |       /이백/ { $return = 200; }
        |       /삼백/ { $return = 300; }
        |       /사백/ { $return = 400; }
        |       /오백/ { $return = 500; }
        |       /육백/ { $return = 600; }
        |       /칠백/ { $return = 700; }
        |       /팔백/ { $return = 800; }
        |       /구백/ { $return = 900; }
        |       /백/         { $return = 100; }

      thousands: 'ilcheon '   { $return = 1000; }                     # try to find a word that represents
        |        'icheon '    { $return = 2000; }                     # values 1000,2000,..,9000
        |        'samcheon '  { $return = 3000; }
        |        'sacheon '   { $return = 4000; }
        |        'ocheon '    { $return = 5000; }
        |        'yukcheon '  { $return = 6000; }
        |        'chilcheon ' { $return = 7000; }
        |        'palcheon '  { $return = 8000; }
        |        'gucheon '   { $return = 9000; }
        |        'cheon '     { $return = 1000; }
        |        /일천/ { $return = 1000; }
        |        /이천/ { $return = 2000; }
        |        /삼천/ { $return = 3000; }
        |        /사천/ { $return = 4000; }
        |        /오천/ { $return = 5000; }
        |        /육천/ { $return = 6000; }
        |        /칠천/ { $return = 7000; }
        |        /팔천/ { $return = 8000; }
        |        /구천/ { $return = 9000; }
        |        /천/         { $return = 1000; }

      tenthousands: 'ilman '   { $return = 10000; }                   # try to find a word that represents
        |           'iman '    { $return = 20000; }                   # values 10000,20000,..,90000
        |           'samman '  { $return = 30000; }
        |           'saman '   { $return = 40000; }
        |           'oman '    { $return = 50000; }
        |           'yukman '  { $return = 60000; }
        |           'chilman ' { $return = 70000; }
        |           'palman '  { $return = 80000; }
        |           'guman '   { $return = 90000; }
        |           'man '     { $return = 10000; }
        |           /일만/ { $return = 10000; }
        |           /이만/ { $return = 20000; }
        |           /삼만/ { $return = 30000; }
        |           /사만/ { $return = 40000; }
        |           /오만/ { $return = 50000; }
        |           /육만/ { $return = 60000; }
        |           /칠만/ { $return = 70000; }
        |           /팔만/ { $return = 80000; }
        |           /구만/ { $return = 90000; }
        |           /만/         { $return = 10000; }

      decade: tens(?) number(?) number(?)                             # try to find words that represents values
              { $return = 0;                                          # from 0 to 99
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
               { $return = 0;                                         # from 1.000 to 9.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0] if (ref $_ && defined $$_[0]);
                   }
                 }
               }

    millenium2: tenthousands(1) thousands(?) century(?) decade(?)     # try to find words that represents values
               { $return = 0;                                         # from 10.000 to 99.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0] if (ref $_ && defined $$_[0]);
                   }
                 }
               }

      man:     millenium1(?) century(?) decade(?)                     # N만K = N * 10_000 + K where N is 1..9999
               manmark                                                # handles values from 10_000 to 99_999_999
               millenium1(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (defined $_ && $_ eq "Man") {
                     $return = ($return>0) ? $return * 10000 : 10000;
                   }
                 }
               }

      manmark: 'man ' { $return = "Man"; }
        |      /만/   { $return = "Man"; }

      eok:     millenium1(?) century(?) decade(?)                     # try to find words that represents values
               eokmark                                                # from 100.000.000 to 999.999.999.999
               man(?) millenium1(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (defined $_ && $_ eq "Eok") {
                     $return = ($return>0) ? $return * 100000000 : 100000000;
                   }
                 }
               }

      eokmark: 'eok ' { $return = "Eok"; }
        |      /억/ { $return = "Eok"; }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::KOR::Word2Num - Word to number conversion in Korean


=head1 VERSION

version 0.2603270

Lingua::KOR::Word2Num is module for converting text containing number
representation in Korean (Sino-Korean system) back into number.
Converts whole numbers from 0 up to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::KOR::Word2Num;

 my $num = Lingua::KOR::Word2Num::w2n( '사십이' );
 # $num == 42

 my $num2 = Lingua::KOR::Word2Num::w2n( 'sasip i' );
 # $num2 == 42

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

=item B<kor_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2002-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
