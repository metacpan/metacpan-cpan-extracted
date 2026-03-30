# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::SRP::Word2Num;
# ABSTRACT: Word to number conversion in Serbian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = srp_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ srp_numerals                 create parser for numerals

sub srp_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'нула'          {  0 }
             |                 {    }

       number:  'једанаест'    { 11 }
             |  'дванаест'     { 12 }
             |  'тринаест'     { 13 }
             |  'четрнаест'    { 14 }
             |  'петнаест'     { 15 }
             |  'шеснаест'     { 16 }
             |  'седамнаест'   { 17 }
             |  'осамнаест'    { 18 }
             |  'деветнаест'   { 19 }
             |  'један'        {  1 }
             |  'једна'        {  1 }
             |  'две'          {  2 }
             |  'два'          {  2 }
             |  'три'          {  3 }
             |  'четири'       {  4 }
             |  'пет'          {  5 }
             |  'шест'         {  6 }
             |  'седам'        {  7 }
             |  'осам'         {  8 }
             |  'девет'        {  9 }
             |  'десет'        { 10 }

         tens:  'двадесет'     { 20 }
             |  'тридесет'     { 30 }
             |  'четрдесет'    { 40 }
             |  'педесет'      { 50 }
             |  'шездесет'     { 60 }
             |  'седамдесет'   { 70 }
             |  'осамдесет'    { 80 }
             |  'деведесет'    { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /сто/  deca     { $item[1] * 100 + $item[3] }
             |  number /сто/           { $item[1] * 100            }
             |  'двеста' deca          { 200 + $item[2]            }
             |  'двеста'               { 200                       }
             |  'триста' deca          { 300 + $item[2]            }
             |  'триста'               { 300                       }
             |  'четиристо' deca  { 400 + $item[2]            }
             |  'четиристо'       { 400                       }
             |  'петсто' deca          { 500 + $item[2]            }
             |  'петсто'               { 500                       }
             |  'шестсто' deca    { 600 + $item[2]            }
             |  'шестсто'         { 600                       }
             |  'седамсто' deca        { 700 + $item[2]            }
             |  'седамсто'             { 700                       }
             |  'осамсто' deca         { 800 + $item[2]            }
             |  'осамсто'              { 800                       }
             |  'деветсто' deca        { 900 + $item[2]            }
             |  'деветсто'             { 900                       }
             |  'сто' deca             { 100 + $item[2]            }
             |  'сто'                  { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd /хиљад[ае]?/ hOd   { $item[1] * 1000 + $item[3]       }
             |  hOd /хиљад[ае]?/        { $item[1] * 1000                  }
             |  number /хиљад[ае]?/ hOd { $item[1] * 1000 + $item[3]       }
             |  number /хиљад[ае]?/     { $item[1] * 1000                  }
             |  /хиљада/ hOd            { 1000 + $item[2]                  }
             |  /хиљада/                { 1000                             }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd             { $item[1] * 1_000_000 + $item[3]       }
             |  hOd megas                   { $item[1] * 1_000_000                  }
             |  'један' 'милион' kOhOd     { 1_000_000 + $item[3]                  }
             |  'један' 'милион'           { 1_000_000                              }
             |  'милион' kOhOd             { 1_000_000 + $item[2]                  }
             |  'милион'                   { 1_000_000                              }

        megas:  'милиона'
             |  'милион'
    });
}

# }}}
# {{{ ordinal2cardinal             convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Serbian (Cyrillic) ordinals: strip gender/case suffixes, then map stems.
    # Inflection: -и/-а/-о/-ог(а)/-ом(у)/-им (masc/fem/neut/oblique).

    my %irregular = (
        'нулти'       => 'нула',
        'први'        => 'један',
        'други'       => 'два',
        'трећи'       => 'три',
        'четврти'     => 'четири',
        'пети'        => 'пет',
        'шести'       => 'шест',
        'седми'       => 'седам',
        'осми'        => 'осам',
        'девети'      => 'девет',
        'десети'      => 'десет',
        'једанаести'  => 'једанаест',
        'дванаести'   => 'дванаест',
        'тринаести'   => 'тринаест',
        'четрнаести'  => 'четрнаест',
        'петнаести'   => 'петнаест',
        'шеснаести'   => 'шеснаест',
        'седамнаести' => 'седамнаест',
        'осамнаести'  => 'осамнаест',
        'деветнаести' => 'деветнаест',
        'двадесети'   => 'двадесет',
        'тридесети'   => 'тридесет',
        'четрдесети'  => 'четрдесет',
        'педесети'    => 'педесет',
        'шездесети'   => 'шездесет',
        'седамдесети' => 'седамдесет',
        'осамдесети'  => 'осамдесет',
        'деведесети'  => 'деведесет',
        'двестоти'    => 'двеста',
        'тристоти'    => 'триста',
        'четиристоти' => 'четиристо',
        'петстоти'    => 'петсто',
        'шестстоти'   => 'шестсто',
        'седамстоти'  => 'седамсто',
        'осамстоти'   => 'осамсто',
        'деветстоти'  => 'деветсто',
        'стоти'       => 'сто',
        'хиљадити'    => 'хиљада',
        'милионти'    => 'милион',
    );

    # Compound ordinals: ALL components are ordinal forms.
    # Normalize each word individually, then look up in the mapping.
    my @words = split /\s+/, $input;
    my @result;
    my $matched = 0;

    for my $word (@words) {
        # Strip gender/case suffixes to masculine nominative (-и)
        my $norm = $word;
        $norm =~ s{ога\z}{и}xms
            or $norm =~ s{ог\z}{и}xms
            or $norm =~ s{ому\z}{и}xms
            or $norm =~ s{ом\z}{и}xms
            or $norm =~ s{им\z}{и}xms
            or $norm =~ s{а\z}{и}xms      # fem: прва → први
            or $norm =~ s{о\z}{и}xms;     # neut: прво → први

        if (exists $irregular{$norm}) {
            push @result, $irregular{$norm};
            $matched = 1;
        }
        else {
            push @result, $word;  # pass through unchanged (connectors, etc.)
        }
    }

    return $matched ? join(' ', @result) : undef;
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SRP::Word2Num - Word to number conversion in Serbian


=head1 VERSION

version 0.2603300

Lingua::SRP::Word2Num is module for converting Serbian numerals (Cyrillic script)
into numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SRP::Word2Num;

 my $num = Lingua::SRP::Word2Num::w2n( 'двадесет' );

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

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'пети', 'десети', 'трећи')
  =>  str    cardinal text (e.g. 'пет', 'десет', 'три')
      undef  if input is not a recognized ordinal

Convert Serbian (Cyrillic) ordinal text to cardinal text via morphological reversal.
Handles all gender/case inflections.

=item B<srp_numerals> (void)

  =>  obj  object of the parser

Internal parser.

=back

=cut

# }}}
# {{{ EXPORTED FUNCTIONS

=pod

=head1 EXPORT_OK

=over 2

=item w2n

=item ordinal2cardinal

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
