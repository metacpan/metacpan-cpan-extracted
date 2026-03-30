# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::DAN::Word2Num;
# ABSTRACT: Word to number conversion in Danish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = dan_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ dan_numerals              create parser for danish numerals

sub dan_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega /\Z/     { $item[1] }
                  | kOhOd /\Z/  { $item[1] }
                  | 'nul' /\Z/  { 0 }
                  | { }

      number:       'tretten'   { 13 }
                  | 'fjorten'   { 14 }
                  | 'femten'    { 15 }
                  | 'seksten'   { 16 }
                  | 'sytten'    { 17 }
                  | 'atten'     { 18 }
                  | 'nitten'    { 19 }
                  | 'elleve'    { 11 }
                  | 'tolv'      { 12 }
                  | 'ti'        { 10 }
                  | /e[nt]/     {  1 }
                  | 'to'        {  2 }
                  | 'tre'       {  3 }
                  | 'fire'      {  4 }
                  | 'fem'       {  5 }
                  | 'seks'      {  6 }
                  | 'syv'       {  7 }
                  | 'otte'      {  8 }
                  | 'ni'        {  9 }

      tens:         'tyve'      { 20 }
                  | 'tredive'   { 30 }
                  | 'fyrre'     { 40 }
                  | 'halvtreds' { 50 }
                  | 'tres'      { 60 }
                  | 'halvfjerds' { 70 }
                  | 'firs'      { 80 }
                  | 'halvfems'  { 90 }

      deca:         number 'og' tens   { $item[1] + $item[3] }
                  | tens
                  | number

      hecto:        number /hundrede?/ deca    { $item[1] * 100 + $item[3] }
                  | /hundrede?/ deca            { 100 + $item[2]            }
                  | number /hundrede?/          { $item[1] * 100            }
                  | /hundrede?/                 { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tusind' hOd    { $item[1] * 1000 + $item[3] }
                | hOd 'tusind'        { $item[1] * 1000            }
                | 'tusind' hOd        { 1000 + $item[2]            }
                | 'tusind'            { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /million(er)?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /million(er)?/       { $item[1] * 1_000_000 }
    });
}

# }}}
# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Danish ordinal→cardinal: reverse lookup for irregular forms,
    # suffix stripping for regular/compound forms.

    # Fully irregular 1-12
    my %irregular = (
        'første'   => 'en',
        'anden'    => 'to',
        'tredje'   => 'tre',
        'fjerde'   => 'fire',
        'femte'    => 'fem',
        'sjette'   => 'seks',
        'syvende'  => 'syv',
        'ottende'  => 'otte',
        'niende'   => 'ni',
        'tiende'   => 'ti',
        'ellevte'  => 'elleve',
        'tolvte'   => 'tolv',
    );

    # Teens 13-19 (-de/-ende suffix on cardinal stem)
    my %teens = (
        'trettende'  => 'tretten',
        'fjortende'  => 'fjorten',
        'femtende'   => 'femten',
        'sekstende'  => 'seksten',
        'syttende'   => 'sytten',
        'attende'    => 'atten',
        'nittende'   => 'nitten',
    );

    # Tens ordinals — values must match what the w2n parser expects
    my %tens = (
        'tyvende'                => 'tyve',
        'tredivte'               => 'tredive',
        'fyrretyvende'           => 'fyrre',
        'halvtredsindstyvende'   => 'halvtreds',
        'tresindstyvende'        => 'tres',
        'halvfjerdsindstyvende'  => 'halvfjerds',
        'firsindstyvende'        => 'firs',
        'halvfemsindstyvende'    => 'halvfems',
    );

    # Exact match: standalone ordinals
    return $irregular{$input} if exists $irregular{$input};
    return $teens{$input}     if exists $teens{$input};
    return $tens{$input}      if exists $tens{$input};

    # Round hundreds/thousands (split fused forms for the parser)
    my %higher = (
        'hundredede'       => 'et hundrede',
        'ethundredede'     => 'et hundrede',
        'tohundredede'     => 'to hundrede',
        'trehundredede'    => 'tre hundrede',
        'firehundredede'   => 'fire hundrede',
        'femhundredede'    => 'fem hundrede',
        'sekshundredede'   => 'seks hundrede',
        'syvhundredede'    => 'syv hundrede',
        'ottehundredede'   => 'otte hundrede',
        'nihundredede'     => 'ni hundrede',
        'ethundrede'       => 'et hundrede',
        'tohundrede'       => 'to hundrede',
        'trehundrede'      => 'tre hundrede',
        'firehundrede'     => 'fire hundrede',
        'femhundrede'      => 'fem hundrede',
        'sekshundrede'     => 'seks hundrede',
        'syvhundrede'      => 'syv hundrede',
        'ottehundrede'     => 'otte hundrede',
        'nihundrede'       => 'ni hundrede',
        'tusindende'       => 'tusind',
        'tusinde'          => 'tusind',
        'entusinde'        => 'et tusind',
        'entusind'         => 'et tusind',
        'totusinde'        => 'to tusind',
        'totusind'         => 'to tusind',
        'tretusinde'       => 'tre tusind',
        'tretusind'        => 'tre tusind',
        'firetusinde'      => 'fire tusind',
        'firetusind'       => 'fire tusind',
        'femtusinde'       => 'fem tusind',
        'femtusind'        => 'fem tusind',
        'sekstusinde'      => 'seks tusind',
        'sekstusind'       => 'seks tusind',
        'syvtusinde'       => 'syv tusind',
        'syvtusind'        => 'syv tusind',
        'ottetusinde'      => 'otte tusind',
        'ottetusind'       => 'otte tusind',
        'nitusinde'        => 'ni tusind',
        'nitusind'         => 'ni tusind',
        'millionte'        => 'en million',
    );
    return $higher{$input} if exists $higher{$input};

    # Fused higher-order compounds: e.g. "entusindførste" → "et tusind" + "første" → "en"
    # Try matching each higher key as a prefix, then convert the remainder.
    for my $hkey (sort { length $b <=> length $a } keys %higher) {
        if ($input =~ m{\A\Q$hkey\E(.+)\z}xms) {
            my $remainder = $1;
            my $tail = ordinal2cardinal($remainder);
            if (defined $tail) {
                return $higher{$hkey} . ' ' . $tail;
            }
        }
    }

    # Danish compounds 21-99: unit + "og" + tens ordinal
    # e.g. "enogtyvende" → "en" + "og" + "tyvende" → "en" + "og" + "tyve" = "enogtyve"
    # Also: unit ordinal + "og" + tens cardinal: "tredjeogtyve" (rare, but handle)
    # Primary pattern: cardinal unit + "og" + ordinal tens
    for my $ord (sort { length $b <=> length $a } keys %tens) {
        if ($input =~ m{\A(.+)og\Q$ord\E\z}xms) {
            my $unit_part = $1;
            return $unit_part . 'og' . $tens{$ord};
        }
    }

    # Compound with ordinal unit at end (unit is ordinal, tens is cardinal)
    # e.g. "tyveførste" → "tyve" + "første" → "tyve" not standard Danish,
    # but handle for robustness
    for my $ord (sort { length $b <=> length $a } keys %irregular) {
        if ($input =~ m{\A(.+)og\Q$ord\E\z}xms) {
            my $prefix = $1;
            return $prefix . 'og' . $irregular{$ord};
        }
    }

    # Hundreds ordinal: "hundrede" as standalone → "hundrede" (already cardinal)
    # Strip trailing -nde/-te for generic fallback
    $input =~ s{indstyvende\z}{indstyve}xms and return $input;
    $input =~ s{ende\z}{e}xms               and return $input;
    $input =~ s{nde\z}{}xms                 and return $input;
    $input =~ s{te\z}{}xms                  and return $input;

    return;  # not an ordinal
}

# }}}

1;

__END__

# {{{ POD HEAD

=pod

=encoding utf-8

=head1 NAME

Lingua::DAN::Word2Num - Word to number conversion in Danish


=head1 VERSION

version 0.2603300

Lingua::DAN::Word2Num is module for converting danish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::DAN::Word2Num;

 my $num = Lingua::DAN::Word2Num::w2n( 'sytten' );

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

  1   str    ordinal text (e.g. 'tredje', 'enogtyvende', 'femtende')
  =>  str    cardinal text (e.g. 'tre', 'enogtyve', 'femten')
  =>  undef  if input is not a recognized ordinal

Convert Danish ordinal text to cardinal text (text-level morphological
transformation, no numbers involved).

=item B<dan_numerals> (void)

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
