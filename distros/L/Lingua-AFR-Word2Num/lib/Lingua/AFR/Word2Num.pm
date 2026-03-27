# For Emacs: -*- mode:cperl; eval: (folding-mode 1) -*-

package Lingua::AFR::Word2Num;
# ABSTRACT: Word to number conversion in Afrikaans

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Carp;

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ variable declarations
our $VERSION = '0.2603260';

my $parser = afr_numerals();

# }}}

# {{{ w2n                                         convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s/,//g;
    $input =~ s/ //g;

    return $parser->numeral($input);
}
# }}}
# {{{ afr_numerals                                create parser for numerals

sub afr_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:   mega
               | kOhOd
               | 'nul'   { 0 }
               | { }

      number:   'viertien'   { 14 }
              | 'vyftien'    { 15 }
              | 'sestien'    { 16 }
              | 'sewentien'  { 17 }
              | 'agtien'     { 18 }
              | 'negentien'  { 19 }
              | 'een'        { 1  }
              | 'twee'       { 2  }
              | 'drie'       { 3  }
              | 'vier'       { 4  }
              | 'vyf'        { 5  }
              | 'ses'        { 6  }
              | 'sewe'       { 7  }
              | 'agt'        { 8  }
              | 'nege'       { 9  }
              | 'tien'       { 10 }
              | 'elf'        { 11 }
              | 'twaalf'     { 12 }
              | 'dertien'    { 13 }

      tens:     'twintig'  { 20 }
              | 'dertig'   { 30 }
              | 'viertig'  { 40 }
              | 'vyftig'   { 50 }
              | 'sestig'   { 60 }
              | 'sewentig' { 70 }
              | 'tagtig'   { 80 }
              | 'negentig' { 90 }

      deca:
                number 'en' tens   { $item[1] + $item[3] }
              | tens
              | number

      hecto:    number 'honderd' /(en)?/ deca { $item[1] * 100 + $item[4] }
              | number 'honderd'              { $item[1] * 100 }

    hOd:          hecto
                | deca

      kilo:    hOd 'duisend' /(en)?/ hOd   { $item[1] * 1000 + $item[4] }
             | hOd 'duisend'               { $item[1] * 1000 }

    kOhOd:   kilo
           | hOd

      mega:    hOd 'miljoen' /(en)?/ kOhOd { $item[1] * 1_000_000 + $item[4] }
             | hOd 'miljoen'               { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=head1 NAME

Lingua::AFR::Word2Num - Word to number conversion in Afrikaans


=head1 VERSION

version 0.2603260

Lingua::AFR::Word2Num is module for converting text containing number
representation in afrikaans back into number. Converts whole numbers from 0 up
to 999 999 999 999.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::AFR::Word2Num;

 my $num = Lingua::AFR::Word2Num::w2n( 'een honderd, drie en twintig' );

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
  =>  undef  if input string not known

Convert text representation to number.
If the input string is not known, or out of the
interval, undef is returned.

=item B<afr_numerals> (void)

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
