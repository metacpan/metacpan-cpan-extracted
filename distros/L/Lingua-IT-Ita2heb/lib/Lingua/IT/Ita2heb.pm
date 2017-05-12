package Lingua::IT::Ita2heb;

use 5.010;

use strict;
use warnings;
use utf8;
use charnames ':full';

use Readonly;

use List::MoreUtils ();

use Lingua::IT::Ita2heb::LettersSeq::IT::ToHeb;

our $VERSION = '0.01';

sub ita_to_heb {
    my ($ita, %option) = @_;

    my @ita_letters = split qr//xms, lc $ita;

    my $seq = Lingua::IT::Ita2heb::LettersSeq::IT::ToHeb->new(
        {
            ita_letters => \@ita_letters,
            %option,
        }
    );

    # Recursion on punctuation marks.
    #<<<
    foreach my $punctuation (
        [ qr/[ ]/xms,   q{ }, ],         # space
        [ qr{-}xms,     $seq->maqaf, ],  # hyphen
        [ qr{'}xms,     q{'}, ])         # apostrophe
    {
        my ($re, $replacement) = @{$punctuation};
        if ($ita =~ $re) {
            return join $replacement, map { ita_to_heb($_) } split $re, $ita;
        }
    }
    #>>>

    $seq->main_loop;

    return $seq->total_text;
}

sub closed_syllable {
    my ($letters_ref, $letter_index) = @_;

    my $seq = Lingua::IT::Ita2heb::LettersSeq::IT::ToHeb->new(
        {
            ita_letters => $letters_ref,
            idx         => $letter_index,
        },
    );

    return $seq->closed_syllable();
}

1;    # End of Lingua::IT::Ita2heb

__END__

=head1 NAME

Lingua::IT::Ita2heb - transliterate Italian words into vocalized Hebrew.

=head1 DESCRIPTION

Transliterate words in Italian into vocalized Hebrew.

=head1 VERSION

Version 0.01

=head1 SYNOPSIS

    use Lingua::IT::Ita2heb;

    my $hebrew_word = Lingua::IT::Ita2heb::ita_to_heb('Castelmezzano');

=head1 SUBROUTINES/METHODS

=head2 ita_to_heb

Given an Italian word, returns a vocalized Hebrew string.

Additional options:

=over

=item * disable_rafe

By default, the rafe sign will be added to the initial petter pe
if it represents an [f] sound. If you don't want it, run it like this:

    my $hebrew_word = Lingua::IT::Ita2heb::ita_to_heb('Firenze', disable_rafe => 1);

=item * disable_dagesh

By default, dagesh will be used wherever possible to
represent consonant gemination. If you don't want it, run it like this:

    my $hebrew_word = Lingua::IT::Ita2heb::ita_to_heb('Palazzo', disable_dagesh => 1);

=item * ascii_geresh

By default, Unicode HEBREW PUNCTUATION GERESH is used to indicate
the sounds of ci and gi. If you want to use the ASCII apostrophe, run it like this:

    my $hebrew_word = Lingua::IT::Ita2heb::ita_to_heb('Cicerone', ascii_geresh => 1);

=item * ascii_maqaf

By default, Unicode HEBREW PUNCTUATION MAQAF is used to indicate
the hyphen. This is the true Hebrew hyphen at the top of the line.
If you prefer to use the ASCII hyphen (minus), run it like this:

    my $hebrew_word = Lingua::IT::Ita2heb::ita_to_heb('Emilia-Romagna', ascii_maqaf => 1);

=back

=head2 closed_syllable

Checks that the vowel is in a closed syllable.

Arguments: a reference to a list of characters and
the index of the vowel to check.

=head1 DIAGNOSTICS

=over

=item * Unknown letter LETTER in the source

The LETTER doesn't look like a part of the Italian orthography.

=back

=head1 BUGS AND LIMITATIONS

This program has several known limitations because Italian pronunciation is
sometimes unpredictable and because of the quirks of Hebrew spelling. Do
not assume that transliterations that this program makes are correct
and always check a reliable dictionary to be sure. Look out especially for
the following cases:

=over

=item * Words with of z

The letter z is assumed to have the sound of [dz] in the beginning of
the word and [ts] elsewhere. This is right most of the time, but there are
also many words where it is wrong.

=item * Words with ia, ie, io, iu

The letter i is assumed to be a semi-vowel before a vowel most of
the time, but there are also many words where it is wrong.

=item * Words with accented vowels

This program treats all accented vowels equally. Accents are usually
relevant only for indicating stress, which is hardly ever marked in Hebrew,
but in some words they may affect pronunciation.

=item * Segol is always used for the sound of e

One day this program may become more clever one day and use tsere and segol
in a way that is closer to standard Hebrew vocalization. Until then... well,
very few people will notice anyway :)

=back

Please report any words that this program transliterates incorrectly
as well as any other bugs or feature requests as issues at
L<https://github.com/amire80/ita2heb>.

=head1 DEPENDENCIES

=over

=item * Readonly.pm.

=item * List::MoreUtils

=back

=head1 CONFIGURATION AND ENVIRONMENT

Nothing special.

=head1 INCOMPATIBILITIES

This program doesn't work with Perl earlier than 5.10 and with non-Unicode strings.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::IT::Ita2heb

You can also look for information at:

=over

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Lingua-IT-Ita2heb>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-IT-Ita2heb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-IT-Ita2heb>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-IT-Ita2heb/>

=back

=head1 ACKNOWLEDGEMENTS

I thank all my Italian and Hebrew teachers.

I thank Shlomi Fish for important technical support
and refactoring.

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Amir E. Aharoni.

This program is free software; you can redistribute it and
modify it under the terms of either:

=over

=item * the GNU General Public License version 3 as published
by the Free Software Foundation.

=item * or the Artistic License version 2.0.

=back

See http://dev.perl.org/licenses/ for more information.

=head1 AUTHOR

Amir E. Aharoni, C<< <amir.aharoni at mail.huji.ac.il> >>

=cut
