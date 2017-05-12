use strict;
use warnings;

package KSx::Analysis::StripAccents;
use base qw( KinoSearch::Analysis::Analyzer );

our $VERSION = '0.05';

use Encode qw 'encode decode';
use Text::Unaccent 'unac_string_utf16';

sub analyze_batch {
    my ( $self, $batch ) = @_;

    # lc and unaccent all of the terms, one by one
    while ( my $token = $batch->next ) {
        # I have to use UTF-16BE, since, although it’s not documented,
        # Text::Unaccent only supports big-endian. And I have to encode it,
        # since it doesn’t support Perl’s Unicode strings. (And it’ll con-
        # vert it to UTF-16 behind the scenes anyway, if I don’t.)
        $token->set_text(
            lc uc decode 'utf-16be', unac_string_utf16
                encode 'UTF-16BE', $token->get_text );
        # We have an ‘lc uc’ there, since some letters won’t be normalised
        # properly without it; e.g., ‘Σσς’ should be normalised to three
        # instances of the same character (‘σσσ’ as opposed to ‘σσς’).
    }

    $batch->reset;
    return $batch;
}

*transform = *analyze_batch;

1;

__END__

=head1 NAME

KSx::Analysis::StripAccents - Remove accents and fold to lowercase

=head1 VERSION

0.05 (beta)

=head1 SYNOPSIS

    my $stripper = KSx::Analysis::StripAccents->new;

    my $polyanalyzer = KinoSearch::Analysis::PolyAnalyzer->new(
        analyzers => [ $tokenizer, $stripper, $stemmer ],
    );

=head1 DESCRIPTION

This analyser strips accents from its input, removes accents, and converts
it to lowercase. It may end up changing the length of a token, so make sure
that this analyser is not used before a tokenizer.

=head1 CONSTRUCTOR

=head2 new

Construct a new accent-stripping analyser.

=head1 PREREQUISITES

This module requires perl and the following modules, which you can get from
the CPAN:

L<Text::Unaccent>

L<KinoSearch> 0.2 or later

=head1 AUTHOR & COPYRIGHT

Copyright (C) Father Chrysostomos

This program is free software; you may redistribute or modify it (or both)
under the same terms as perl.

=head1 SEE ALSO

L<KinoSearch::Analysis::Analyzer> (the base class)

L<KinoSearch::Analysis::LCNormalizer> (which this module was based on, and
is intended as a drop-in replacement for)

L<KinoSearch::Analysis::CaseFolder> (what LCNormalizer has been renamed in
the dev branch of KinoSearch)

L<KinoSearch>

=cut
