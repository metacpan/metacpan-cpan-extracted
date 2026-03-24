# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::ENG::Word2Num;
# ABSTRACT: Word 2 number conversion in ENG.

# {{{ use block

use 5.16.0;

use Parse::RecDescent;
use Export::Attrs;

# }}}
# {{{ var block
our $VERSION = '0.2603230';

my $parser   = eng_numerals();

# }}}

# {{{ w2n                     convert number to text

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}

# {{{ eng_numerals            create parser for numerals

sub eng_numerals {
    return Parse::RecDescent->new(q{
        <autoaction: { $item[1] } >

        numeral:     mega
                  |  kOhOd
                  | { }

         number:    'twelve'     { 12 }
                  | 'thirteen'   { 13 }
                  | 'fourteen'   { 14 }
                  | 'fifteen'    { 15 }
                  | 'sixteen'    { 16 }
                  | 'seventeen'  { 17 }
                  | 'eighteen'   { 18 }
                  | 'nineteen'   { 19 }
                  | 'zero'       {  0 }
                  | 'one'        {  1 }
                  | 'two'        {  2 }
                  | 'three'      {  3 }
                  | 'four'       {  4 }
                  | 'five'       {  5 }
                  | 'six'        {  6 }
                  | 'seven'      {  7 }
                  | 'eight'      {  8 }
                  | 'nine'       {  9 }
                  | 'ten'        { 10 }
                  | 'eleven'     { 11 }

         tens:      'twenty'     { 20 }
                  | 'thirty'     { 30 }
                  | 'forty'      { 40 }
                  | 'fifty'      { 50 }
                  | 'sixty'      { 60 }
                  | 'seventy'    { 70 }
                  | 'eighty'     { 80 }
                  | 'ninety'     { 90 }

         deca:      tens /(-|\s)?/ number  { $item[1] + $item[3] }
                  | tens
                  | number

        hecto:      number 'hundred' deca  { $item[1] * 100  + $item[3] }
                  | number 'hundred'       { $item[1] * 100 }

          hOd:      hecto
                  | deca

         kilo:      hOd /thousand,?/ hOd   { $item[1] * 1000 + $item[3] }
                  | hOd /thousand,?/       { $item[1] * 1000 }
                  |     /thousand,?/ hOd   { 1000 + $item[2] }
                  |     /thousand,?/       { 1000 }

        kOhOd:      kilo
                  | hOd

         mega:      hOd /millions?,?/ kOhOd   { $item[1] * 1_000_000 + $item[3] }
                  | hOd /millions?,?/         { $item[1] * 1_000_000 }
                  |     'million'     kOhOd   { 1_000_000 + $item[2] }
                  |     'million'             { 1_000_000 }

    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

=head2 Lingua::ENG::Word2Num 

=head1 VERSION

version 0.2603230

Word 2 number conversion in ENG.

Lingua::ENG::Word2Num is module for converting text containing number
representation in czech back into number. Converts whole numbers from 0 up
to 999 999 999.

Text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ENG::Word2Num;

 my $num = Lingua::ENG::Word2Num::w2n( 'nineteen' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str     string to convert
  =>  num     converted number
      undef   if input string is not known

Convert text representation to number.


=item B<eng_numerals> (void)

  =>  obj  new parser object

Internal fuction.

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

   Roman Vasicek <info@petamem.com>

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=cut

# }}}
