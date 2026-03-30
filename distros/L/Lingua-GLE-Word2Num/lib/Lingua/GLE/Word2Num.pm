# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::GLE::Word2Num;
# ABSTRACT: Word to number conversion in Irish (Gaeilge)

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;

use Parse::RecDescent;
# }}}
# {{{ variable declarations
our $VERSION = '0.2603300';

my $parser = gle_numerals();

# }}}

# {{{ w2n                                         convert text to number
#
sub w2n :Export {
    my $input = shift // return;

    # Normalise whitespace
    $input =~ s/\s+/ /g;
    $input =~ s/^\s+//;
    $input =~ s/\s+$//;

    # Remove optional "is" conjunction (alternative compound form)
    $input =~ s/\bis\b//g;
    $input =~ s/\s+/ /g;
    $input =~ s/^\s+//;
    $input =~ s/\s+$//;

    return 0 if $input eq 'náid';

    return $parser->numeral($input) || undef;
}
# }}}
# {{{ gle_numerals                                 create parser for numerals
#
sub gle_numerals {
    return Parse::RecDescent->new(q{
      numeral: <rulevar: local $number = 0>
      numeral: million   { return $item[1]; }
        |      millenium { return $item[1]; }
        |      century   { return $item[1]; }
        |      decade    { return $item[1]; }
        |                { return undef; }

      number: 'a haon'     { $return = 1; }
        |     'a dó'       { $return = 2; }
        |     'a trí'      { $return = 3; }
        |     'a ceathair' { $return = 4; }
        |     'a cúig'     { $return = 5; }
        |     'a sé'       { $return = 6; }
        |     'a seacht'   { $return = 7; }
        |     'a hocht'    { $return = 8; }
        |     'a naoi'     { $return = 9; }
        |     'a deich'    { $return = 10; }

      teen: 'a dó dhéag'       { $return = 12; }
        |   'a haon déag'      { $return = 11; }
        |   'a trí déag'       { $return = 13; }
        |   'a ceathair déag'  { $return = 14; }
        |   'a cúig déag'      { $return = 15; }
        |   'a sé déag'        { $return = 16; }
        |   'a seacht déag'    { $return = 17; }
        |   'a hocht déag'     { $return = 18; }
        |   'a naoi déag'      { $return = 19; }

      tens: 'fiche'    { $return = 20; }
        |   'tríocha'  { $return = 30; }
        |   'daichead' { $return = 40; }
        |   'caoga'    { $return = 50; }
        |   'seasca'   { $return = 60; }
        |   'seachtó'  { $return = 70; }
        |   'ochtó'    { $return = 80; }
        |   'nócha'    { $return = 90; }

      decade: teen                                          # 11-19 first (longer match)
              { $return = $item[1]; }
        |     tens number(?)                                # 20-99
              { $return = 0;
                $return += $item[1];
                $return += ${$item[2]}[0] if ref $item[2] && defined ${$item[2]}[0];
              }
        |     number                                        # 1-10
              { $return = $item[1]; }

      hundreds: 'céad'         { $return = 100; }

      century: number(?) hundreds decade(?)                 # 100-999
               { $return = 0;
                 my $mult = (ref $item[1] && defined ${$item[1]}[0]) ? ${$item[1]}[0] : 1;
                 $return = $mult * 100;
                 $return += ${$item[3]}[0] if ref $item[3] && defined ${$item[3]}[0];
               }

    millenium: century(?) decade(?) 'míle' century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (defined $_ && $_ eq 'míle') {
                     $return = ($return > 0) ? $return * 1000 : 1000;
                   }
                 }
               }

      million: century(?) decade(?)
               'milliún'
               millenium(?) century(?) decade(?)
               { $return = 0;
                 for (@item) {
                   if (ref $_ && defined $$_[0]) {
                     $return += $$_[0];
                   } elsif (defined $_ && $_ eq 'milliún') {
                     $return = ($return > 0) ? $return * 1000000 : 1000000;
                   }
                 }
               }

    });
}
# }}}

# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 0,
    };
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::GLE::Word2Num - Word to number conversion in Irish (Gaeilge)


=head1 VERSION

version 0.2603300

Lingua::GLE::Word2Num is a module for converting text containing number
representation in Irish (Gaeilge) back into number. Converts whole numbers
from 0 up to 999 999 999.

Input text must be encoded in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::GLE::Word2Num;

 my $num = Lingua::GLE::Word2Num::w2n( 'céad tríocha a trí' );

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
      undef  if the input string is not known

Convert text representation to number.

=item B<gle_numerals> (void)

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
