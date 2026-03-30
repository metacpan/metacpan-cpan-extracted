# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::SQI::Word2Num;
# ABSTRACT: Word to number conversion in Albanian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = sqi_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s{\A\s+}{}xms;
    $input =~ s{\s+\z}{}xms;

    return $parser->numeral($input);
}

# }}}
# {{{ sqi_numerals              create parser for Albanian numerals

sub sqi_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'njëmbëdhjetë'        { 11 }
                  | 'dymbëdhjetë'         { 12 }
                  | 'trembëdhjetë'        { 13 }
                  | 'katërmbëdhjetë'      { 14 }
                  | 'pesëmbëdhjetë'       { 15 }
                  | 'gjashtëmbëdhjetë'    { 16 }
                  | 'shtatëmbëdhjetë'     { 17 }
                  | 'tetëmbëdhjetë'       { 18 }
                  | 'nëntëmbëdhjetë'      { 19 }
                  | 'zero'                {  0 }
                  | 'një'                 {  1 }
                  | 'dy'                  {  2 }
                  | /tre|tri/             {  3 }
                  | 'katër'               {  4 }
                  | 'pesë'                {  5 }
                  | 'gjashtë'             {  6 }
                  | 'shtatë'              {  7 }
                  | 'tetë'               {  8 }
                  | 'nëntë'               {  9 }
                  | 'dhjetë'              { 10 }

      tens:         'njëzet'              { 20 }
                  | 'tridhjetë'           { 30 }
                  | 'dyzet'               { 40 }
                  | 'pesëdhjetë'          { 50 }
                  | 'gjashtëdhjetë'       { 60 }
                  | 'shtatëdhjetë'        { 70 }
                  | 'tetëdhjetë'          { 80 }
                  | 'nëntëdhjetë'         { 90 }

      deca:         tens 'e' number       { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number 'qind' 'e' deca  { $item[1] * 100 + $item[4] }
                  | number 'qind'            { $item[1] * 100            }
                  | /njëqind/                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'mijë' 'e' hOd     { $item[1] * 1000 + $item[4] }
                | hOd 'mijë'             { $item[1] * 1000            }

      kOhOd:      kilo
                | hOd

      mega:       hOd /milionë?/ 'e' kOhOd { $item[1] * 1_000_000 + $item[4] }
                | hOd /milionë?/           { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::SQI::Word2Num - Word to number conversion in Albanian


=head1 VERSION

version 0.2603300

Lingua::SQI::Word2Num is a module for converting Albanian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::SQI::Word2Num;

 my $num = Lingua::SQI::Word2Num::w2n( 'shtatëmbëdhjetë' );

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
You can specify a numeral from interval [0,999_999_999].

=item B<sqi_numerals> (void)

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
 coding (2026-present):
   PetaMem AI Coding Agents

=head1 COPYRIGHT

Copyright (c) PetaMem, s.r.o. 2004-present

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut

# }}}
