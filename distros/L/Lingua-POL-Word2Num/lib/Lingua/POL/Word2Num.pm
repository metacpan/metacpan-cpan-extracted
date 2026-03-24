# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::POL::Word2Num;
# ABSTRACT: Word 2 number conversion in POL.

# {{{ use block

use 5.16.0;
use utf8;

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603230';
my $COPY     = 'Copyright (c) PetaMem, s.r.o. 2003-present';
my $parser   = pol_numerals();

# }}}

# {{{ w2n                                         convert number to text

sub w2n :Export {
  my $input = shift // return;

#  print "INPUT: '$input'\n";
  $input =~ s{\s\z}{}xms;
#  print "INPUT: '$input'\n";

  return $parser->numeral($input);
}

# }}}
# {{{ pol_numerals                                 create parser for numerals

sub pol_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'zero'            {  0 }
             |                   {    }

       number:  'dziewiętnaście' { 19 }
             |  'osiemnaście'    { 18 }
             |  'siedemnaście'   { 17 }
             |  'szesnaście'     { 16 }
             |  'piętnaście'     { 15 }
             |  'czternaście'    { 14 }
             |  'trzynaście'     { 13 }
             |  'dwanaście'      { 12 }
             |  'jedenaście'     { 11 }
             |  'dziesięć'       { 10 }
             |  'dziewięć'       {  9 }
             |  'osiem'          {  8 }
             |  'siedem'         {  7 }
             |  'sześć'          {  6 }
             |  'pięć'           {  5 }
             |  'cztery'         {  4 }
             |  'trzy'           {  3 }
             |  'dwa'            {  2 }
             |  'jeden'          {  1 }

         tens:  'dwadzieścia'      { 20 }
             |  'trzydzieści'      { 30 }
             |  'czterdzieści'     { 40 }
             |  'pięćdziesiąt'     { 50 }
             |  'sześćdziesiąt'    { 60 }
             |  'siedemdziesiąt'   { 70 }
             |  'osiemdziesiąt'    { 80 }
             |  'dziewięćdziesiąt' { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /(sta|set)/ deca  { $item[1] * 100 + $item[3] }
             |  number /(sta|set)/       { $item[1] * 100            }
             |  'dwieście' deca          { 2 * 100 + $item[2]        }
             |  'dwieście'               { 200                       }
             |  'sto' deca               { 100 + $item[2]            }
             |  'sto'                    { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd      /(tysiąc[ae]?|tysięcy)/ hOd   { $item[1] * 1000 + $item[3]       }
             |  hOd      /(tysiąc[ae]?|tysięcy)/       { $item[1] * 1000                  }
             |  number   /(tysiąc[ae]?|tysięcy)/ hOd   { $item[1] * 1000 + $item[3]       }
             |  number   /(tysiąc[ae]?|tysięcy)/       { $item[1] * 1000                  }
             |  'tysiąc' hOd                           { 1000 + $item[2]                  }
             |  'tysiąc'                               { 1000                             }
             |  hOd 'jeden' 'tysiąc' hOd               { ($item[1] + 1) * 1000 + $item[4] }
             |  hOd 'jeden' 'tysiąc'                   { ($item[1] + 1) * 1000            }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }

        megas:  /milion(y|ów)?/
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

=head2 Lingua::POL::Word2Num 

=head1 VERSION

version 0.2603230

Word 2 number conversion in POL.

Lingua::POL::Word2Num is module for converting text containing number
representation in polish back into number. Converts whole numbers from 0 up
to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::POL::Word2Num;

 my $num = Lingua::POL::Word2Num::w2n( 'sto dwadzieścia trzy' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item  B<w2n> (positional)

  1   str    string to convert
  =>  num    converted number
  =>  undef  if input string is not known

Convert text representation to number.


=item B<pol_numerals> (void)

  =>  obj  returns new parser object

Internal parser.


=back

=cut

# }}}
# {{{ POD FOOTER

=pod

=head1 AUTHOR

 coding, maintenance, refactoring, extensions, specifications:

   Vitor Serra Mori <info@petamem.com>

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2003-present

=cut

# }}}
