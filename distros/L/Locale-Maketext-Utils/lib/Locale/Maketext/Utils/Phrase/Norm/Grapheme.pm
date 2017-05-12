package Locale::Maketext::Utils::Phrase::Norm::Grapheme;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} =~ s/((?:\\x[0-9a-fA-F]{2})+)/[comment,grapheme “$1”]/ ) {
        $filter->add_violation('Contains grapheme notation');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Graphemes are not very human readable and require interpolation, we can avoid both issues by not using them!

=head2 Rationale

This helps give consistency, clarity, and simplicity.

If we parse a string and find 'Commencing compilation \xe2\x80\xa6' then we have to interpolate that string into 'Commencing compilation …' before we can look it up to see if it exists in a hash.

Graphemes also add a layer of complexity that hinders translators and thus makes room for lower quality translations.

Developers have it slightly better in that they’ll recognize it but it still requires effort to figure out what it is exactly and to determine what sequence they need for a given character.

You can simply use the character itself or a bracket notation method for the handful of markup related or visually special characters

=head1 possible violations

If you get false positives then that only goes to help highlight how ambiguity adds to the reason to avoid non-bytes strings!

=over 4

=item Contains grapheme notation

A sequence of \xe2\x98\xba\xe2\x80\xa6 will be replaced w/ [comment,grapheme “\xe2\x98\xba\xe2\x80\xa6”]

=back

=head1 possible warnings

None

=head1 Entire filter only runs under extra filter

See L<Locale::Maketext::Utils::Phrase::Norm/extra filters> for more details.
