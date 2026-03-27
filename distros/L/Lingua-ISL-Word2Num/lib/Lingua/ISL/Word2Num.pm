# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::ISL::Word2Num;
# ABSTRACT: Word to number conversion in Icelandic

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603260';
my $parser   = isl_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ isl_numerals              create parser for icelandic numerals

sub isl_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega /\Z/     { $item[1] }
                  | kOhOd /\Z/    { $item[1] }
                  | /núll/i /\Z/   { 0 }
                  | { }

      number:       /þrettán/i    { 13 }
                  | /fjórtán/i    { 14 }
                  | /fimmtán/i          { 15 }
                  | /sextán/i           { 16 }
                  | /sautján/i          { 17 }
                  | /átján/i       { 18 }
                  | /nítján/i      { 19 }
                  | /ellefu/i                 { 11 }
                  | /tólf/i             { 12 }
                  | /tíu/i              { 10 }
                  | /einn?|eitt/i             {  1 }
                  | /tveir|tvö/i        {  2 }
                  | /þrír|þrjú/i  {  3 }
                  | /fjórir|fjögur/i         {  4 }
                  | /fimm/i                   {  5 }
                  | /sex/i                    {  6 }
                  | /sjö/i              {  7 }
                  | /átta/i              {  8 }
                  | /níu/i               {  9 }

      tens:         /tuttugu/i                { 20 }
                  | /þrjátíu/i  { 30 }
                  | /fjörutíu/i       { 40 }
                  | /fimmtíu/i              { 50 }
                  | /sextíu/i               { 60 }
                  | /sjötíu/i         { 70 }
                  | /áttatíu/i         { 80 }
                  | /níutíu/i          { 90 }

      deca:         tens 'og' number           { $item[1] + $item[3] }
                  | number 'og' tens           { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number /hundruð/i 'og' deca  { $item[1] * 100 + $item[4] }
                  | number /hundruð/i deca        { $item[1] * 100 + $item[3] }
                  | /hundrað/i 'og' deca          { 100 + $item[3]            }
                  | /hundrað/i deca               { 100 + $item[2]            }
                  | number /hundruð/i             { $item[1] * 100            }
                  | /hundrað/i                    { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd /þúsund/i 'og' hOd  { $item[1] * 1000 + $item[4] }
                | hOd /þúsund/i hOd         { $item[1] * 1000 + $item[3] }
                | hOd /þúsund/i             { $item[1] * 1000            }
                | /þúsund/i 'og' hOd        { 1000 + $item[3]            }
                | /þúsund/i hOd             { 1000 + $item[2]            }
                | /þúsund/i                  { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /milljón(ir)?/i 'og' kOhOd { $item[1] * 1_000_000 + $item[4] }
                | hOd /milljón(ir)?/i kOhOd       { $item[1] * 1_000_000 + $item[3] }
                | hOd /milljón(ir)?/i             { $item[1] * 1_000_000 }
    });
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::ISL::Word2Num - Word to number conversion in Icelandic


=head1 VERSION

version 0.2603260

Lingua::ISL::Word2Num is module for converting Icelandic numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::ISL::Word2Num;

 my $num = Lingua::ISL::Word2Num::w2n( 'sautján' );

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

=item B<isl_numerals> (void)

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
