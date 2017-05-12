package Lingua::LO::NLP;
use strict;
use warnings;
use 5.012000;
use utf8;
use feature 'unicode_strings';
use version 0.77; our $VERSION = version->declare('v0.2.0');
use Lingua::LO::NLP::Syllabify;
use Lingua::LO::NLP::Analyze;
use Lingua::LO::NLP::Romanize;

=encoding utf8

=head1 NAME

Lingua::LO::NLP - Various Lao text processing functions

=head1 SYNOPSIS

    use utf8;
    use 5.10.1;
    use open qw/ :std :encoding(UTF-8) /;
    use Lingua::LO::NLP;
    use Data::Dumper;

    my $lao = Lingua::LO::NLP->new;

    my @syllables = $lao->split_to_syllables("ສະບາຍດີ"); # qw( ສະ ບາຍ ດີ )
    print Dumper(\@syllables);

    for my $syl (@syllables) {
        my $analysis = $lao->analyze_syllable($syl);
        printf "%s: %s\n", $analysis->syllable, $analysis->tone;
        # ສະ: TONE_HIGH_STOP
        # ບາຍ: TONE_LOW
        # ດີ: TONE_LOW
    }

    say $lao->romanize("ສະບາຍດີ", variant => 'PCGN', hyphen => "\N{HYPHEN}");  # sa‐bay‐di
    say $lao->romanize("ສະບາຍດີ", variant => 'IPA');                           # sa baːj diː

=head1 DESCRIPTION

This module provides various functions for processing Lao text. Currently it can

=over 4

=item

split Lao text (usually written without blanks between words) into syllables

=item

analyze syllables with regards to core and end consonants, vowels, tone and
other properties

=item

romanize Lao text according to the PCGN standard or to IPA (experimental)

=back

These functions are basically just shortcuts to the functionality of some
specialized modules: L<Lingua::LO::NLP::Syllabify>,
L<Lingua::LO::NLP::Analyze> and L<Lingua::LO::NLP::Romanize>. If
you need only one of them, you can shave off a little overhead by using those
directly.

=head1 METHODS

=head2 new

    new(option => value, ...)

The object constructor currently does nothing; there are no options. However,
it is likely that there will be in future versions, therefore it is highly
recommended to call methods as object methods so your code won't break when I
introduce them.

=cut
sub new {
    my $class = shift;
    my %opts = @_;
    return bless \%opts, $class;
}

=head2 split_to_syllables

    my @syllables = $object->split_to_syllables($text, %options );

Split Lao text into its syllables using a regexp modelled after PHISSAMAY,
DALALOY and DURRANI: I<Syllabification of Lao Script for Line Breaking>. Takes
as its only mandatory parameter a character string to split and optionally a
number of named options; see L<Lingua::LO::NLP::Syllabify/new> for those.
Returns a list of syllables.

=cut
sub split_to_syllables {
    shift;  # discard $self for now
    return Lingua::LO::NLP::Syllabify->new(@_)->get_syllables;
}

=head2 analyze_syllable

    my $classified = $object->analyze_syllable($syllable, %options);

Returns a L<Lingua::LO::NLP::Analyze> object that allows you to query
various syllable properties such as core consonant, tone mark, vowel length and
tone. See there for details.

=cut
sub analyze_syllable {
    shift;  # discard $self for now
    return Lingua::LO::NLP::Analyze->new(@_);
}

=head2 romanize

    $object->romanize($lao, %options);

Returns a romanized version of the text passed in as C<$lao>. See
L<Lingua::LO::NLP::Romanize/new> for options. If you don't pass in I<any>
options, the default is C<variant =E<gt> 'PCGN'>.

=cut
sub romanize {
    my (undef, $lao, %options) = @_;
    $options{variant} //= 'PCGN';
    return Lingua::LO::NLP::Romanize->new(%options)->romanize( $lao );
}

=head1 SEE ALSO

L<Lingua::LO::Romanize> is the module that inspired this one. It has some
issues with ambiguous syllable boundaries as in "ໃນວົງ" though.

=head1 AUTHOR

Matthias Bethke, E<lt>matthias@towiski.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 by Matthias Bethke

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself, either Perl version 5.14.2 or, at your option,
any later version of Perl 5 you may have available. Significant portions of the
code are (C) PostgreSQL Global Development Group and The Regents of the
University of California. All modified versions must retain the file COPYRIGHT
included in the distribution.

=cut

1;
