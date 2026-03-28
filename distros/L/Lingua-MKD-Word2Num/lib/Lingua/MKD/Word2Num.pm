# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::MKD::Word2Num;
# ABSTRACT: Word to number conversion in Macedonian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Carp;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603270';
my  $parser  = mkd_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input .= " ";                             # Grant end space before normalizing

    $input =~ s/илјади /илјада /g;            # Thousand variations. Normalize to илјада
    $input =~ s/милиони /милион /g;           # Million variations. Normalize to милион

    return $parser->numeral($input);
}

# }}}
# {{{ mkd_numerals                                 create parser for numerals

sub mkd_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'деветнаесет '    { $return = 19; }                    # try to find a word from 0 to 19
        |     'осумнаесет '     { $return = 18; }
        |     'седумнаесет '    { $return = 17; }
        |     'шестнаесет '     { $return = 16; }
        |     'петнаесет '      { $return = 15; }
        |     'четиринаесет '   { $return = 14; }
        |     'тринаесет '      { $return = 13; }
        |     'дванаесет '       { $return = 12; }
        |     'единаесет '      { $return = 11; }
        |     'десет '           { $return = 10; }
        |     'девет '           { $return = 9; }
        |     'осум '            { $return = 8; }
        |     'седум '           { $return = 7; }
        |     'шест '            { $return = 6; }
        |     'пет '             { $return = 5; }
        |     'четири '          { $return = 4; }
        |     'три '             { $return = 3; }
        |     'две '             { $return = 2; }
        |     'два '             { $return = 2; }
        |     'еден '            { $return = 1; }
        |     'една '            { $return = 1; }
        |     'нула '            { $return = 0; }

      tens:   'дваесет '         { $return = 20; }                    # try to find a word that represents
        |     'триесет '         { $return = 30; }                    # values 20,30,..,90
        |     'четириесет '      { $return = 40; }
        |     'педесет '         { $return = 50; }
        |     'шеесет '          { $return = 60; }
        |     'седумдесет '      { $return = 70; }
        |     'осумдесет '       { $return = 80; }
        |     'деведесет '       { $return = 90; }

     hundreds: 'деветстотини '   { $return = 900; }                   # try to find a word that represents
        |      'осумстотини '    { $return = 800; }                   # values 100,200,..,900
        |      'седумстотини '   { $return = 700; }
        |      'шестстотини '    { $return = 600; }
        |      'петстотини '     { $return = 500; }
        |      'четиристотини '  { $return = 400; }
        |      'триста '         { $return = 300; }
        |      'двесте '         { $return = 200; }
        |      'сто '            { $return = 100; }

      decade: tens 'и ' number                                        # tens и units (e.g. дваесет и три)
              { $return = $item[1] + $item[3]; }
        |     tens                                                    # plain tens (e.g. педесет)
              { $return = $item[1]; }
        |     number                                                  # plain number 0-19
              { $return = $item[1]; }

      century: hundreds 'и ' decade(?)                               # hundreds "и" decade (for remainder < 20 or tens only)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   }
                 }
                 $return ||= undef;
               }
        |      hundreds tens 'и ' number                             # hundreds tens "и" units
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   }
                 }
                 $return ||= undef;
               }
        |      hundreds                                              # plain hundreds (e.g. двесте)
               { $return = $item[1]; }

    millenium: century(?) decade(?) 'илјада ' 'и ' century             # thousand "и" hundred (e.g. илјада и сто)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   } elsif ($_ eq "\x{0438}\x{043b}\x{0458}\x{0430}\x{0434}\x{0430} ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }
        |      century(?) decade(?) 'илјада ' 'и ' decade             # thousand "и" remainder (e.g. илјада и еден)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (!ref $_ && $_ =~ /^\d+$/) {
                     $return += $_;
                   } elsif ($_ eq "\x{0438}\x{043b}\x{0458}\x{0430}\x{0434}\x{0430} ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }
        |      century(?) decade(?) 'илјада ' century(?) decade(?)   # thousand with hundreds remainder
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "\x{0438}\x{043b}\x{0458}\x{0430}\x{0434}\x{0430} ") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return ||= undef;
               }

      million: century(?) decade(?)                                  # try to find words that represents values
              'милион '                                              # from 1.000.000 to 999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "\x{043c}\x{0438}\x{043b}\x{0438}\x{043e}\x{043d} ") {
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

=encoding utf-8

=head1 NAME

Lingua::MKD::Word2Num - Word to number conversion in Macedonian


=head1 VERSION

version 0.2603270

Lingua::MKD::Word2Num is module for converting text containing number
representation in Macedonian back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::MKD::Word2Num;

 my $num = Lingua::MKD::Word2Num::w2n( 'пет' );

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

=item B<mkd_numerals> (void)

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
