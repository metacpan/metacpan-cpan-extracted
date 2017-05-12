# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::FRA::Word2Num;
# ABSTRACT: Word 2 number conversion in FRA.

# {{{ use block

use 5.10.1;

use strict;
use warnings;

use base qw(Exporter);

use Parse::RecDescent;

# }}}
# {{{ variable declarations

our $VERSION = 0.1257;
our $INFO    = {
    rev  => '$Rev: 808 $',
};

our @EXPORT_OK  = qw(cardinal2num w2n);
my $parser      = fr_numerals();

# }}}

# {{{ w2n                                         convert number to text
#
sub w2n {
    my $input = shift // return;

    $input =~ s/quatre-vingt/qvingt/g;   # Grant unique identifiers
    $input =~ s/dix-sept/dis/g;
    $input =~ s/dix-huit/dih/g;
    $input =~ s/dix-neuf/din/g;

    $input =~ s/ et //g;                 # Does not affect the number

    $input =~ s/millions/million/g;      # Million in plural does not affect the number

    $input =~ s/,//g;                    # remove trash
    $input =~ s/-//g;

    return $parser->numeral($input);
}
# }}}
# {{{ fr_numerals                                 create parser for numerals
sub fr_numerals {
    return Parse::RecDescent->new(q{
      numeral: millions  { return $item[1]; }                         # root parse. go from maximum to minimum value
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'zéro'     { $return = 0; }                             # try to find a word from 0 to 19
       |      'un'       { $return = 1; }
       |      'deux'     { $return = 2; }
       |      'trois'    { $return = 3; }
       |      'quatre'   { $return = 4; }
       |      'cinq'     { $return = 5; }
       |      'six'      { $return = 6; }
       |      'sept'     { $return = 7; }
       |      'huit'     { $return = 8; }
       |      'neuf'     { $return = 9; }
       |      'dix'      { $return = 10; }
       |      'onze'     { $return = 11; }
       |      'douze'    { $return = 12; }
       |      'treize'   { $return = 13; }
       |      'quatorze' { $return = 14; }
       |      'quinze'   { $return = 15; }
       |      'seize'    { $return = 16; }
       |      'dis'      { $return = 17; }
       |      'dih'      { $return = 18; }
       |      'din'      { $return = 19; }

      tens:   'vingt'     { $return = 20; }                           # try to find a word that representates
        |     'trente'    { $return = 30; }                           # values 20,30,..,90
        |     'quarante'  { $return = 40; }
        |     'cinquante' { $return = 50; }
        |     'soixante'  { $return = 60; }
        |     'qvingt'    { $return = 80; }

      decade: tens(?) number(?)                                       # try to find words that represents values
              { $return = -1;                                         # from 0 to 99
                for (@item) {
                  if (ref $_ && defined $$_[0]) {
                    $return += $$_[0] if ($return != -1);             # -1 is the non-zero identifier, since
                    $return  = $$_[0] if ($return == -1);             # the result could be zero
                  }
                }
                $return = undef if($return == -1);
              }

      century: number(?) 'cent' decade(?)                             # try to find words that represents values
               { $return = 0;                                         # from 100 to 999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "cent") {
                     $return = ($return>0) ? $return * 100 : 100;
                   }
                 }
                 $return = undef if(!$return);
               }

    millenium: century(?) decade(?) 'mille' century(?) decade(?)      # try to find words that represents values
               { $return = 0;                                         # from 1.000 to 999.999
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "mille") {
                     $return = ($return>0) ? $return * 1000 : 1000;
                   }
                 }
                 $return = undef if(!$return);
               }

      millions: millenium(?) century(?) decade(?)                      # try to find words that represents values
               'million'                                              # from 1.000.000 to 999.999.999.999
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif ($_ eq "million" && $return<1000000 ) {
                     $return = ($return>0) ? $return * 1000000 : 1000000;
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

=head2 Lingua::FRA::Word2Num 

=head1 VERSION

version 0.1257

Word 2 number conversion in FRA.

Lingua::FRA::Word2Num is module for converting text containing number
representation in French back into number. Converts whole numbers from 0 up
to 999 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FRA::Word2Num;

 my $num = Lingua::FRA::Word2Num::w2n( 'cent vingt-trois' );

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

=item B<fr_numerals> (void)

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

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (C) PetaMem, s.r.o. 2004-present

=cut

# }}}
