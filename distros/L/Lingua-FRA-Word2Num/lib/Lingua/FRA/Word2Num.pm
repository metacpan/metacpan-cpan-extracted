# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::FRA::Word2Num;
# ABSTRACT: Word 2 number conversion in FRA.

# {{{ use block

use 5.16.0;
use utf8;

use base qw(Exporter);

use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603230';
our @EXPORT_OK  = qw(cardinal2num w2n);
my $parser      = fra_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n {
    my $input = shift // return;


    return $parser->numeral($input);
}

# }}}
# {{{ fra_numerals                                create parser for numerals

sub fra_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'zéro'       {  0 }
             |              {    }

       number:  'un'        {  1 }
             |  'deux'      {  2 }
             |  'trois'     {  3 }
             |  'quatre'    {  4 }
             |  'cinq'      {  5 }
             |  'six'       {  6 }
             |  'sept'      {  7 }
             |  'huit'      {  8 }
             |  'neuf'      {  9 }
             |  'dix-sept'  { 17 }
             |  'dix-huit'  { 18 }
             |  'dix-neuf'  { 19 }
             |  'dix'       { 10 }
             |  'onze'      { 11 }
             |  'douze'     { 12 }
             |  'treize'    { 13 }
             |  'quatorze'  { 14 }
             |  'quinze'    { 15 }
             |  'seize'     { 16 }

         tens:  'vingt'             { 20 }
             |  'trente'            { 30 }
             |  'quarante'          { 40 }
             |  'cinquante'         { 50 }
             |  'soixante-dix'      { 70 }
             |  'soixante'          { 60 }
             |  /quatre-vingts?/    { 80 }

         deca:  tens /-?/ number    { $item[1] + $item[3] }
             |  tens 'et' number    { $item[1] + $item[3] }
             |  tens
             |  number

        hecto:  number /cents?/ deca    {  $item[1] * 100 + $item[3] }
             |  number /cents?/         {  $item[1] * 100 }
             |         /cents?/ deca    {  100 + $item[2] }
             |         'cent'           { 100 }

          hOd:  hecto
             |  deca

         kilo:  hOd  /milles?/ hOd  { $item[1] * 1000 + $item[3] }
             |  hOd  /milles?/      { $item[1] * 1000 }
             |       /milles?/ hOd  { 1000 + $item[2] }
             |       'mille'        { 1000 }

        kOhOd:  kilo
             |  hOd

         mega:  kOhOd /millions?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
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

version 0.2603230

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

=item B<fra_numerals> (void)

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

Copyright (c) PetaMem, s.r.o. 2004-present

=cut

# }}}
