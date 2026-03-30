# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::HEB::Word2Num;
# ABSTRACT: Word to number conversion in Hebrew

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = heb_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ heb_numerals              create parser for hebrew numerals

sub heb_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       /אחד עשר/     { 11 }
                  | /שנים עשר/    { 12 }
                  | /שלושה עשר/   { 13 }
                  | /ארבעה עשר/   { 14 }
                  | /חמישה עשר/   { 15 }
                  | /שישה עשר/    { 16 }
                  | /שבעה עשר/    { 17 }
                  | /שמונה עשר/   { 18 }
                  | /תשעה עשר/    { 19 }
                  | /אפס/         {  0 }
                  | /אחד/         {  1 }
                  | /שניים/        {  2 }
                  | /שלושה/        {  3 }
                  | /ארבעה/        {  4 }
                  | /חמישה/        {  5 }
                  | /שישה/         {  6 }
                  | /שבעה/         {  7 }
                  | /שמונה/        {  8 }
                  | /תשעה/         {  9 }
                  | /עשרה/         { 10 }

      tens:         /עשרים/        { 20 }
                  | /שלושים/       { 30 }
                  | /ארבעים/       { 40 }
                  | /חמישים/       { 50 }
                  | /שישים/        { 60 }
                  | /שבעים/        { 70 }
                  | /שמונים/       { 80 }
                  | /תשעים/        { 90 }

      deca:         tens /ו/ number   { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        /מאתיים/ deca            { 200 + $item[2]            }
                  | /מאתיים/                  { 200                       }
                  | /שלוש מאות/ deca          { 300 + $item[2]            }
                  | /שלוש מאות/               { 300                       }
                  | /ארבע מאות/ deca          { 400 + $item[2]            }
                  | /ארבע מאות/               { 400                       }
                  | /חמש מאות/ deca           { 500 + $item[2]            }
                  | /חמש מאות/                { 500                       }
                  | /שש מאות/ deca            { 600 + $item[2]            }
                  | /שש מאות/                 { 600                       }
                  | /שבע מאות/ deca           { 700 + $item[2]            }
                  | /שבע מאות/                { 700                       }
                  | /שמונה מאות/ deca         { 800 + $item[2]            }
                  | /שמונה מאות/              { 800                       }
                  | /תשע מאות/ deca           { 900 + $item[2]            }
                  | /תשע מאות/                { 900                       }
                  | /מאה/ deca                { 100 + $item[2]            }
                  | /מאה/                     { 100                       }

      hOd:        hecto
                | deca

      kilo:       /אלפיים/ hOd              { 2000 + $item[2]           }
                | /אלפיים/                   { 2000                      }
                | /שלושת אלפים/ hOd          { 3000 + $item[2]           }
                | /שלושת אלפים/              { 3000                      }
                | /ארבעת אלפים/ hOd          { 4000 + $item[2]           }
                | /ארבעת אלפים/              { 4000                      }
                | /חמשת אלפים/ hOd           { 5000 + $item[2]           }
                | /חמשת אלפים/               { 5000                      }
                | /ששת אלפים/ hOd            { 6000 + $item[2]           }
                | /ששת אלפים/                { 6000                      }
                | /שבעת אלפים/ hOd           { 7000 + $item[2]           }
                | /שבעת אלפים/               { 7000                      }
                | /שמונת אלפים/ hOd          { 8000 + $item[2]           }
                | /שמונת אלפים/              { 8000                      }
                | /תשעת אלפים/ hOd           { 9000 + $item[2]           }
                | /תשעת אלפים/               { 9000                      }
                | hOd /אלף/ hOd             { $item[1] * 1000 + $item[3] }
                | hOd /אלף/                 { $item[1] * 1000            }
                | /אלף/ hOd                 { 1000 + $item[2]            }
                | /אלף/                     { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /מיליון/ kOhOd        { $item[1] * 1_000_000 + $item[3] }
                | hOd /מיליון/              { $item[1] * 1_000_000            }
                | /מיליון/ kOhOd            { 1_000_000 + $item[2]            }
                | /מיליון/                  { 1_000_000                       }
    });
}

# }}}
# {{{ ordinal2cardinal                              convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Hebrew ordinal specials (1-10) → cardinal forms expected by w2n parser.
    # The parser uses masculine construct forms (אחד, שניים, שלושה, etc.)
    state $specials = {
        'ראשון'  => 'אחד',        # 1st  → אחד   (parser: 1)
        'שני'    => 'שניים',       # 2nd  → שניים  (parser: 2)
        'שלישי'  => 'שלושה',       # 3rd  → שלושה  (parser: 3)
        'רביעי'  => 'ארבעה',       # 4th  → ארבעה  (parser: 4)
        'חמישי'  => 'חמישה',       # 5th  → חמישה  (parser: 5)
        'שישי'   => 'שישה',        # 6th  → שישה   (parser: 6)
        'שביעי'  => 'שבעה',        # 7th  → שבעה   (parser: 7)
        'שמיני'  => 'שמונה',       # 8th  → שמונה  (parser: 8)
        'תשיעי'  => 'תשעה',        # 9th  → תשעה   (parser: 9)
        'עשירי'  => 'עשרה',        # 10th → עשרה   (parser: 10)
    };

    return $specials->{$input} if exists $specials->{$input};

    # For 11+, ordinals ARE the cardinal form — return unchanged.
    return $input;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::HEB::Word2Num - Word to number conversion in Hebrew


=head1 VERSION

version 0.2603300

Lingua::HEB::Word2Num is module for converting Hebrew numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::HEB::Word2Num;

 my $num = Lingua::HEB::Word2Num::w2n( 'עשרים ושלושה' );

 print defined($num) ? $num : "sorry, can't convert this text into number.";

=cut

# }}}
# {{{ Functions Reference

=pod

=head1 Functions Reference

=over 2

=item B<w2n> (positional)

  1   str    string to convert (UTF-8 Hebrew)
  =>  num    converted number
      undef  if input string is not known

Convert text representation to number.
You can specify a numeral from interval [0,999_999_999].

=item B<heb_numerals> (void)

  =>  obj  new parser object

Internal parser.


=item B<ordinal2cardinal> (positional)

  1   str    ordinal text
  =>  str    cardinal text
      undef  if input is not recognised as an ordinal

Convert ordinal text to cardinal text (morphological reversal).

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
