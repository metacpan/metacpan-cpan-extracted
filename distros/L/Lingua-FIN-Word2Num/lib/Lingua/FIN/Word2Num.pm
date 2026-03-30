# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8 -*-
package Lingua::FIN::Word2Num;
# ABSTRACT: Word to number conversion in Finnish

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use Export::Attrs;
use Parse::RecDescent;

# }}}
# {{{ var block
our $VERSION = '0.2603300';
my $parser   = fin_numerals();

# }}}

# {{{ w2n                       convert text to number

sub w2n :Export {
    my $input = shift // return;

    return $parser->numeral($input);
}

# }}}
# {{{ fin_numerals              create parser for finnish numerals

sub fin_numerals {
    return Parse::RecDescent->new(q{
      <autoaction: { $item[1] } >

      numeral:      mega
                  | kOhOd
                  | { }

      number:       'yksitoista'          { 11 }
                  | 'kaksitoista'         { 12 }
                  | 'kolmetoista'         { 13 }
                  | 'neljätoista'        { 14 }
                  | 'viisitoista'         { 15 }
                  | 'kuusitoista'         { 16 }
                  | 'seitsemäntoista'   { 17 }
                  | 'kahdeksantoista'     { 18 }
                  | 'yhdeksäntoista'    { 19 }
                  | 'kymmenen'            { 10 }
                  | 'nolla'               {  0 }
                  | 'yksi'                {  1 }
                  | 'kaksi'               {  2 }
                  | 'kolme'               {  3 }
                  | 'neljä'              {  4 }
                  | 'viisi'               {  5 }
                  | 'kuusi'               {  6 }
                  | 'seitsemän'         {  7 }
                  | 'kahdeksan'           {  8 }
                  | 'yhdeksän'          {  9 }

      tens:         'kaksikymmentä'      { 20 }
                  | 'kolmekymmentä'      { 30 }
                  | 'neljäkymmentä'    { 40 }
                  | 'viisikymmentä'      { 50 }
                  | 'kuusikymmentä'      { 60 }
                  | 'seitsemänkymmentä' { 70 }
                  | 'kahdeksankymmentä'  { 80 }
                  | 'yhdeksänkymmentä'  { 90 }

      deca:         tens number           { $item[1] + $item[2] }
                  | tens
                  | number

      hecto:        number 'sataa' deca   { $item[1] * 100 + $item[3] }
                  | number 'sataa'        { $item[1] * 100            }
                  | 'sata' deca           { 100 + $item[2]            }
                  | 'sata'                { 100                       }

      hOd:        hecto
                | deca

      kilo:       hOd 'tuhatta' hOd      { $item[1] * 1000 + $item[3] }
                | hOd 'tuhatta'          { $item[1] * 1000            }
                | 'tuhat' hOd            { 1000 + $item[2]            }
                | 'tuhat'                { 1000                       }

      kOhOd:      kilo
                | hOd

      mega:       hOd /miljoona[a]?/ kOhOd { $item[1] * 1_000_000 + $item[3] }
                | hOd /miljoona[a]?/       { $item[1] * 1_000_000 }
                | 'miljoona' kOhOd         { 1_000_000 + $item[2] }
                | 'miljoona'               { 1_000_000             }
    });
}

# }}}

# {{{ ordinal2cardinal          convert ordinal text to cardinal text

sub ordinal2cardinal :Export {
    my $input = shift // return;

    # Finnish ordinals: suppletive 1st/2nd, regular -s suffix for 3+.
    # Compounds: cardinal prefix + ordinal tail.
    # Order of matching matters: hundreds before tens to avoid
    # false matches on prefixed forms.

    my %irregular = (
        'ensimmäinen' => 'yksi',
        'toinen'       => 'kaksi',
    );

    return $irregular{$input} if exists $irregular{$input};

    # Ordinal stem → cardinal mappings for units
    my %ord_stem_to_cardinal = (
        'yhde'       => 'yksi',
        'kahde'      => 'kaksi',
        'kolma'      => 'kolme',
        'neljä'      => 'neljä',
        'viide'      => 'viisi',
        'kuude'      => 'kuusi',
        'seitsemä'   => 'seitsemän',
        'kahdeksa'   => 'kahdeksan',
        'yhdeksä'    => 'yhdeksän',
    );

    # Ordinal hundreds prefix → cardinal hundreds prefix
    # "toinensadas" (200th) → "kaksi", "kolmassadas" → "kolme", etc.
    # The stem before "sadas" is the ordinal form of the multiplier.
    my %ord_hundreds_pfx = (
        'toinen'     => 'kaksi',     # 200th uses suppletive "toinen"
        'kolmas'     => 'kolme',
        'neljäs'     => 'neljä',
        'viides'     => 'viisi',
        'kuudes'     => 'kuusi',
        'seitsemäs'  => 'seitsemän',
        'kahdeksas'  => 'kahdeksan',
        'yhdeksäs'   => 'yhdeksän',
    );

    # === HUNDREDS: check before tens to avoid false prefix matches ===

    # Round hundreds ordinal: "sadas" (100th), "toinensadas" (200th), etc.
    if ($input eq 'sadas') {
        return 'sata';
    }
    if ($input =~ m{\A (.+) sadas \z}xms) {
        my $pfx = $1;
        my $card_pfx = $ord_hundreds_pfx{$pfx};
        return $card_pfx . 'sataa' if defined $card_pfx;
    }

    # Compound 100+rest: "sata" + ordinal(rest) → "sata" + cardinal(rest)
    if ($input =~ m{\A sata (?<rest>.+) \z}xms) {
        my $rest = $+{rest};
        my $cardinal = ordinal2cardinal($rest);
        return defined $cardinal ? 'sata' . $cardinal : undef;
    }

    # Compound N*100+rest: cardinal(N) + "sata" + ordinal(rest)
    # Cardinal form uses "sataa" for N≥2: "kaksisataayksi" (201)
    for my $stem (sort { length($b) <=> length($a) } keys %ord_stem_to_cardinal) {
        my $card = $ord_stem_to_cardinal{$stem};
        if ($input =~ m{\A \Q$card\E sata (?<rest>.+) \z}xms) {
            my $rest = $+{rest};
            my $cardinal = ordinal2cardinal($rest);
            return defined $cardinal ? $card . 'sataa' . $cardinal : undef;
        }
    }

    # === TENS ===

    # Standalone "kymmenes" → "kymmenen" (10th)
    return 'kymmenen' if $input eq 'kymmenes';

    # Compound tens + ones: "kahdeskymmenesviides" (25th)
    if ($input =~ m{\A (?<tpfx>.+?) s? kymmenes (?<rest>.+) \z}xms) {
        my $tens_stem = $+{tpfx};
        my $rest      = $+{rest};
        my $tens_cardinal = $ord_stem_to_cardinal{$tens_stem} // return;
        my $tens_word = $tens_cardinal . 'kymmentä';
        my $ones_cardinal = ordinal2cardinal($rest) // return;
        return $tens_word . $ones_cardinal;
    }

    # Round tens ordinal: "kahdeskymmenes" (20th)
    if ($input =~ m{\A (?<tpfx>.+?) s? kymmenes \z}xms) {
        my $tens_stem = $+{tpfx};
        my $tens_cardinal = $ord_stem_to_cardinal{$tens_stem} // return;
        return $tens_cardinal . 'kymmentä';
    }

    # === TEENS ===

    if ($input =~ m{\A (?<stem>.+) stoista \z}xms) {
        my $stem = $+{stem};
        return $ord_stem_to_cardinal{$stem} . 'toista'
            if exists $ord_stem_to_cardinal{$stem};
    }
    if ($input =~ m{\A (?<stem>.+?) s toista \z}xms) {
        my $stem = $+{stem};
        return $ord_stem_to_cardinal{$stem} . 'toista'
            if exists $ord_stem_to_cardinal{$stem};
    }
    if ($input =~ m{\A (?<stem>.+?) toista \z}xms) {
        my $stem = $+{stem};
        $stem =~ s{s\z}{}xms;
        return $ord_stem_to_cardinal{$stem} . 'toista'
            if exists $ord_stem_to_cardinal{$stem};
    }

    # === REGULAR: strip -s suffix and map stem ===
    if ($input =~ s{s\z}{}xms) {
        return $ord_stem_to_cardinal{$input} if exists $ord_stem_to_cardinal{$input};
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

Lingua::FIN::Word2Num - Word to number conversion in Finnish


=head1 VERSION

version 0.2603300

Lingua::FIN::Word2Num is module for converting Finnish numerals into
numbers. Converts whole numbers from 0 up to 999 999 999. Input is
expected to be in UTF-8.

=cut

# }}}
# {{{ SYNOPSIS

=pod

=head1 SYNOPSIS

 use Lingua::FIN::Word2Num;

 my $num = Lingua::FIN::Word2Num::w2n( 'seitsemäntoista' );

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

  1   str    ordinal text (e.g. 'ensimmäinen', 'kolmas', 'kymmenes')
  =>  str    cardinal text (e.g. 'yksi', 'kolme', 'kymmenen')
      undef  if input is not recognised as an ordinal

Convert Finnish ordinal text to cardinal text (morphological reversal).
Handles suppletive forms (ensimmäinen, toinen), regular -s ordinals,
and compound forms with teens (-toista) and tens (-kymmentä).

=item B<fin_numerals> (void)

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
