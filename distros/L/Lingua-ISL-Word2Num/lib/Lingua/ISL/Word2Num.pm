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
our $VERSION = '0.2603300';
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
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Icelandic ordinal→cardinal: reverse lookup for irregular forms,
    # suffix stripping for regular/compound forms.

    # Fully irregular 1-12
    my %irregular = (
        'fyrsti'    => 'einn',
        'annar'     => 'tveir',
        'þriðji'    => 'þrír',
        'fjórði'    => 'fjórir',
        'fimmti'    => 'fimm',
        'sjötti'    => 'sex',
        'sjöundi'   => 'sjö',
        'áttundi'   => 'átta',
        'níundi'    => 'níu',
        'tíundi'    => 'tíu',
        'ellefti'   => 'ellefu',
        'tólfti'    => 'tólf',
    );

    # Teens 13-19 (-di suffix on cardinal stem)
    my %teens = (
        'þrettándi'  => 'þrettán',
        'fjórtándi'  => 'fjórtán',
        'fimmtándi'  => 'fimmtán',
        'sextándi'   => 'sextán',
        'sautjándi'  => 'sautján',
        'átjándi'    => 'átján',
        'nítjándi'   => 'nítján',
    );

    # Tens ordinals (-asti suffix)
    my %tens = (
        'tuttugasti'  => 'tuttugu',
        'þrítugasti'  => 'þrjátíu',
        'fertugasti'  => 'fjörutíu',
        'fimmtugasti' => 'fimmtíu',
        'sextugasti'  => 'sextíu',
        'sjötugasti'  => 'sjötíu',
        'áttugasti'   => 'áttatíu',
        'nítugasti'   => 'níutíu',
    );

    # Special large number ordinals
    my %special = (
        'hundraðasti' => 'hundrað',
        'þúsundasti'  => 'þúsund',
    );

    # Exact match: standalone ordinals
    return $irregular{$input} if exists $irregular{$input};
    return $teens{$input}     if exists $teens{$input};
    return $tens{$input}      if exists $tens{$input};
    return $special{$input}   if exists $special{$input};

    # Compound ordinals: split on last " og " boundary, convert the tail recursively.
    # e.g. "tuttugu og fyrsti" → "tuttugu og einn"
    # e.g. "níu hundruð og níutíu og níuasti" → split at last "og" → prefix + converted tail
    if ($input =~ m{\A(.+)\s+og\s+(.+)\z}xms) {
        my ($prefix, $tail_ord) = ($1, $2);
        my $tail_card = ordinal2cardinal($tail_ord) // return;
        return $prefix . ' og ' . $tail_card;
    }

    # Compound ordinals without "og" (e.g. "tvö hundruðasti")
    # Split on space, convert last token, rejoin.
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;
        my $last  = pop @words;
        my $cardinal = ordinal2cardinal($last) // return;
        push @words, $cardinal;
        return join ' ', @words;
    }

    # Fallback: strip common ordinal suffixes
    $input =~ s{asti\z}{}xms   and return $input;
    $input =~ s{undi\z}{ur}xms and return $input;
    $input =~ s{di\z}{}xms     and return $input;
    $input =~ s{ti\z}{}xms     and return $input;

    return;  # not an ordinal
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

version 0.2603300

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

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'þriðji', 'tuttugu og fyrsti', 'fimmtugasti')
  =>  str    cardinal text (e.g. 'þrír', 'tuttugu og einn', 'fimmtíu')
  =>  undef  if input is not a recognized ordinal

Convert Icelandic ordinal text to cardinal text (text-level morphological
transformation, no numbers involved).

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
