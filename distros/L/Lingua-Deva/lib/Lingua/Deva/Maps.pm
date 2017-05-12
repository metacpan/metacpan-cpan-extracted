package Lingua::Deva::Maps;

use v5.12.1;
use strict;
use warnings;
use utf8;
use charnames ':full';

use Lingua::Deva::Maps::IAST;

=encoding UTF-8

=head1 NAME

Lingua::Deva::Maps - Default maps setup for Lingua::Deva

=cut

use Exporter;
use parent 'Exporter';
our @EXPORT_OK = qw( %Consonants %Vowels %Diacritics %Finals
                     $Inherent $Virama $Avagraha );

=head1 SYNOPSIS

    use Lingua::Deva::Maps::IAST;     # or
    use Lingua::Deva::Maps::ISO15919; # or
    use Lingua::Deva::Maps::HK;       # or
    use Lingua::Deva::Maps::ITRANS;

    my $d = Lingua::Deva->new(map => 'HK');
    say $d->to_deva('gaNezaH'); # prints 'गणेशः'

=head1 DESCRIPTION

This module defines the default transliteration mappings for L<Lingua::Deva>
and is intended for internal use.

It does, however, provide the namespace for the ready-made transliteration
schemes,

=over 4

=item C<Lingua::Deva::Maps::IAST>

International Alphabet of Sanskrit Transliteration (I<kṛṣṇa>),

=item C<Lingua::Deva::Maps::ISO15919>

Simplified ISO 15919 (I<kr̥ṣṇa>),

=item C<Lingua::Deva::Maps::HK>

Harvard-Kyoto (I<kRSNa>), and

=item C<Lingua::Deva::Maps::ITRANS>

ITRANS (I<kRRiShNa>).

=back

Users can also furnish their own transliteration schemes, but these must
follow the layout of the existing schemes which is described in the following.

Every transliteration scheme provides four hashes, C<%Consonants>, C<%Vowels>,
C<%Diacritics> (diacritic vowel signs), and C<%Finals> (I<anusvāra>,
I<candrabindu>, I<visarga>).  The L<Lingua::Deva> module relies on this
subdivision for its parsing and aksarization process.

Inside these hashes the keys are Latin script tokens and the values are the
corresponding Devanagari characters:

    "bh" => "\N{DEVANAGARI LETTER BHA}" # in %Consonants

The hash keys ("tokens") must be in canonically decomposed form
(L<NFD|Unicode::Normalize>).  For example a key "ç" ("c" with cedilla) needs
to be entered as C<"c\x{0327}">, ie. a "c" with combining cedilla.  If the
transliteration scheme is case-insensitive, the keys must be lowercase.

In addition to the required four hash maps, a boolean variable C<$CASE> may be
present.  If it is, it specifies whether case distinctions by default do have
significance (S<I<A> ≠ I<a>>) or not (S<I<A> = I<a>>) in the scheme.

The default mappings of a L<Lingua::Deva> object can be completely customized
through the optional constructor arguments

=over 4

=item *

L<C|Lingua::Deva/new>, L<V|Lingua::Deva/new>, L<D|Lingua::Deva/new>,
L<F|Lingua::Deva/new>, Latin to Devanagari maps,

=item *

L<DC|Lingua::Deva/new>, L<DV|Lingua::Deva/new>, L<DD|Lingua::Deva/new>,
L<DF|Lingua::Deva/new>, Devanagari to Latin maps, and

=item *

L<casesensitive|Lingua::Deva/new>, case-sensitivity.

=back

The first eight of these serve to override the default transliteration
mappings (or the one passed through the L<map|Lingua::Deva/new> option).  It
is easiest to start by copying and modifying one of the existing maps.

    # Include the relevant module
    use Lingua::Deva::Maps::IAST;

    # Copy map, modify, then pass to the constructor
    my %c = %Lingua::Deva::Maps::IAST::Consonants;
    $c{"c\x{0327}"} = delete $c{"s\x{0301}"};
    my $d = Lingua::Deva->new( C => \%c );

It is the user's responsibility to make reasonable customizations; eg. the
vowels (C<V>) and diacritics (C<D>) maps normally need to be customized in
unison.

Aside from all this, C<Lingua::Deva::Maps> also defines the global variables

=over 4

=item C<$Inherent>

the inherent vowel I<a>,

=item C<$Virama>

I<virāma> ( ्), and

=item C<$Avagraha>

I<avagraha> (ऽ),

=back

which are unlikely to need configurability.

=cut

# Setup default maps
*Consonants   = \%Lingua::Deva::Maps::IAST::Consonants;
*Vowels       = \%Lingua::Deva::Maps::IAST::Vowels;
*Diacritics   = \%Lingua::Deva::Maps::IAST::Diacritics;
*Finals       = \%Lingua::Deva::Maps::IAST::Finals;

# Global variables
our $Inherent = "a";
our $Virama   = "\N{DEVANAGARI SIGN VIRAMA}";
our $Avagraha = "\N{DEVANAGARI SIGN AVAGRAHA}";

1;
