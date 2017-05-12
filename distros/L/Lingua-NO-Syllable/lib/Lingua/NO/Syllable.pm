package Lingua::NO::Syllable;
use strict;
use warnings;
use utf8;
use feature 'unicode_strings';

require Exporter;

use Unicode::Normalize;

our @ISA    = qw/ Exporter /;
our @EXPORT = qw/ syllable syllables /;

our @VOWELS = qw( a e i o u y æ ø å );

=encoding utf-8

=head1 NAME

Lingua::NO::Syllable - Count the number of syllables in Norwegian words.

=head1 VERSION

Version 0.06.

=cut

our $VERSION = '0.06';

=head1 SYNOPSIS

    use Lingua::NO::Syllable;

    my $count = syllables( 'Tyrannosaurus' ); # 5, because:
                                              # Tyr-ann-o-sau-rus

=head1 DESCRIPTION

C<Lingua::NO::Syllable::syllables($word)> estimates the number of syllables in
the C<$word> passed to it. It's an estimate, because the algorithm is quick
and dirty, non-alpha characters aren't considered etc. Don't expect this
module to give you a 100% correct answer.

As the Norwegian and the Danish languages are quite similar, at least written,
this module might work for the Danish language as well.

=cut

sub syllable {
    return syllables( @_ );
}

sub syllables {
    my $word = shift // '';

    # Remove surrounding spaces.
    $word =~ s/^\s+//;
    $word =~ s/\s+$//;

    # If the word is one character long, consider it to contain only one
    # syllable.
    return 1 if ( length($word) == 1 );

    # Lowercase the word.
    $word = lc( $word );

    # Normalize the word, i.e. convert accented characters to their normalized
    # representation.
    $word = NFD( $word );

    # Create an array of the word's characters.
    my @chars = split( //, $word );

    # The basic rule is that the number of syllables in a word equals the
    # number of vowels.
    my $syllables = 0;

    foreach my $vowel ( @VOWELS ) {
        foreach my $char ( @chars ) {
            if ( $vowel eq $char ) {
                $syllables++;
            }
        }
    }

    # Certain vowel combinations doesn't classify as "syllable separator".
    foreach ( qw(ai au ay ei eu ey oi ou oy øi øu øy æi æu æy åi åu åy) ) {
        my $occurences = $word =~ m/$_/g;
        $syllables -= $occurences;
    }

    # Return
    return $syllables;
}

1;

=head1 ACCENTED CHARACTERS

Accented characters, like é, à etc., are normalized (using L<Unicode::Normalize>)
before the number of syllables are counted.

=head1 SEE ALSO

=over 4

=item * L<Lingua::EN::Syllable>

=back

=head1 AUTHOR

Tore Aursand, C<< <toreau at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at L<https://rt.cpan.org/Dist/Display.html?Name=Lingua-NO-Syllable>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::NO::Syllable

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Lingua-NO-Syllable>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Lingua-NO-Syllable>

=item * Search CPAN

L<http://search.cpan.org/dist/Lingua-NO-Syllable/>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2015-2016 Tore Aursand.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
