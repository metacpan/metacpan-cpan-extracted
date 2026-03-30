# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::LAV::Word2Num;
# ABSTRACT: Word to number conversion in Latvian

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = lav_numerals();

# }}}

# {{{ w2n                          convert text to number

sub w2n :Export {
    my $input = shift // return;

    $input =~ s{\s\z}{}xms;

    return $parser->numeral($input);
}

# }}}
# {{{ lav_numerals                  create parser for Latvian numerals

sub lav_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:  mega
             |  kOhOd
             | 'nulle'            {  0 }
             |                    {    }

       number:  'vienpadsmit'     { 11 }
             |  'divpadsmit'      { 12 }
             |  'trīspadsmit'    { 13 }
             |  'četrpadsmit'    { 14 }
             |  'piecpadsmit'     { 15 }
             |  'sešpadsmit'     { 16 }
             |  'septiņpadsmit'  { 17 }
             |  'astoņpadsmit'   { 18 }
             |  'deviņpadsmit'   { 19 }
             |  'viens'           {  1 }
             |  'divi'            {  2 }
             |  'trīs'           {  3 }
             |  'četri'          {  4 }
             |  'pieci'           {  5 }
             |  'seši'           {  6 }
             |  'septiņi'        {  7 }
             |  'astoņi'         {  8 }
             |  'deviņi'         {  9 }
             |  'desmit'          { 10 }

         tens:  'divdesmit'         { 20 }
             |  'trīsdesmit'       { 30 }
             |  'četrdesmit'       { 40 }
             |  'piecdesmit'        { 50 }
             |  'sešdesmit'        { 60 }
             |  'septiņdesmit'     { 70 }
             |  'astoņdesmit'      { 80 }
             |  'deviņdesmit'      { 90 }

         deca:  tens number    { $item[1] + $item[2] }
             |  tens
             |  number

        hecto:  number /simt(s|i)/ deca  { $item[1] * 100 + $item[3] }
             |  number /simt(s|i)/       { $item[1] * 100            }
             |  /simts/ deca             { 100 + $item[2]            }
             |  /simts/                  { 100                       }

          hOd:  hecto
             |  deca

         kilo:  hOd /tūkstotis|tūkstoši/ hOd  { $item[1] * 1000 + $item[3] }
             |  hOd /tūkstotis|tūkstoši/       { $item[1] * 1000            }

        kOhOd:  kilo
             |  hOd

         mega:  hOd megas kOhOd  { $item[1] * 1_000_000 + $item[3] }
             |  hOd megas        { $item[1] * 1_000_000             }

        megas:  /miljon(s|i)/
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Latvian ordinals are adjectival with -ais (masc) / -ā (fem) endings.
    # Fully suppletive stems for most ordinals.
    # Compounds: space-separated, only last element is ordinal.

    my %ordinal_to_cardinal = (
        'pirmais'     => 'viens',
        'pirmā'       => 'viens',
        'otrais'      => 'divi',
        'otrā'        => 'divi',
        'trešais'     => 'trīs',
        'trešā'       => 'trīs',
        'ceturtais'   => 'četri',
        'ceturtā'     => 'četri',
        'piektais'    => 'pieci',
        'piektā'      => 'pieci',
        'sestais'     => 'seši',
        'sestā'       => 'seši',
        'septītais'   => 'septiņi',
        'septītā'     => 'septiņi',
        'astotais'    => 'astoņi',
        'astotā'      => 'astoņi',
        'devītais'    => 'deviņi',
        'devītā'      => 'deviņi',
        'desmitais'   => 'desmit',
        'desmitā'     => 'desmit',
        # Teens
        'vienpadsmitais'  => 'vienpadsmit',
        'vienpadsmitā'    => 'vienpadsmit',
        'divpadsmitais'   => 'divpadsmit',
        'divpadsmitā'     => 'divpadsmit',
        'trīspadsmitais'  => 'trīspadsmit',
        'trīspadsmitā'    => 'trīspadsmit',
        'četrpadsmitais'  => 'četrpadsmit',
        'četrpadsmitā'    => 'četrpadsmit',
        'piecpadsmitais'  => 'piecpadsmit',
        'piecpadsmitā'    => 'piecpadsmit',
        'sešpadsmitais'   => 'sešpadsmit',
        'sešpadsmitā'     => 'sešpadsmit',
        'septiņpadsmitais' => 'septiņpadsmit',
        'septiņpadsmitā'   => 'septiņpadsmit',
        'astoņpadsmitais'  => 'astoņpadsmit',
        'astoņpadsmitā'    => 'astoņpadsmit',
        'deviņpadsmitais'  => 'deviņpadsmit',
        'deviņpadsmitā'    => 'deviņpadsmit',
    );

    # Hundreds/thousands ordinals with stem changes — handle before generic compound splitter.
    # Standalone: "tūkstošais" → "viens tūkstotis" (parser needs number + tūkstotis)
    # Compound: "divi tūkstošais" → "divi tūkstoši"
    if ($input =~ m{tūkstošai[s]?\z}xms || $input =~ m{tūkstošā\z}xms) {
        return 'viens tūkstotis' if $input eq 'tūkstošais';
        return 'viens tūkstotis' if $input eq 'tūkstošā';
        $input =~ s{tūkstošais\z}{tūkstoši}xms and return $input;
        $input =~ s{tūkstošā\z}{tūkstoši}xms   and return $input;
    }

    # Compound: "divdesmit trešais" → convert last part only
    if ($input =~ m{\s}xms) {
        my @words = split /\s+/, $input;
        my $last  = pop @words;
        my $cardinal = ordinal2cardinal($last) // return;
        push @words, $cardinal;
        return join ' ', @words;
    }

    return $ordinal_to_cardinal{$input} if exists $ordinal_to_cardinal{$input};

    # Hundreds ordinal: simtais → simts (parser expects /simts/)
    $input =~ s{simtais\z}{simts}xms   and return $input;
    $input =~ s{simtā\z}{simts}xms     and return $input;

    # Tens ordinals: strip -ais/-ā from compound tens
    # divdesmitais → divdesmit, etc.
    if ($input =~ s{ais\z}{}xms || $input =~ s{ā\z}{}xms) {
        return $input;
    }

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::LAV::Word2Num - Word to number conversion in Latvian


=head1 VERSION

version 0.2603300

Lingua::LAV::Word2Num is module for converting Latvian numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::LAV::Word2Num;

 my $num = Lingua::LAV::Word2Num::w2n( 'divdesmit trīs' );

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
You can specify a numeral from interval [0, 999_999_999].

=item B<ordinal2cardinal> (positional)

  1   str    ordinal text (e.g. 'pirmais', 'trešais', 'desmitais')
  =>  str    cardinal text (e.g. 'viens', 'trīs', 'desmit')
      undef  if input is not recognised as an ordinal

Convert Latvian ordinal text to cardinal text (morphological reversal).
Handles both masculine (-ais) and feminine (-ā) endings.
Compounds are split on whitespace and the last part is converted.

=item B<lav_numerals> (void)

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
