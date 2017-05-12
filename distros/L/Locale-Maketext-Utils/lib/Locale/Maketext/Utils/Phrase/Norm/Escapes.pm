package Locale::Maketext::Utils::Phrase::Norm::Escapes;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    # This will handle previously altered characters like " in  the aggregate results
    if ( ${$string_sr} =~ s/(?:\\\[(.*?)\])/[comment,escaped sequence “~[$1~]”]/g ) {    # TODO: make the \[.*?\] regex/logic smarter since it will not work with ~[ but why would we do that right :) - may need to wait for phrase-as-class obj
        $filter->add_violation('Contains escape sequence');
    }

    if ( ${$string_sr} =~ s/(?:\\([^NUuxX]))/[comment,escaped sequence “$1”]/g ) {
        $filter->add_violation('Contains escape sequence');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Detect escaped character sequences.

=head2 Rationale

An escaped character:

=over 4

=item * adds ambiguity

=item * is an indication of in-string-formatting (e.g. \n)

=item * relies on interpolation

The additional layer of complexity could hinder translators and thus makes room for lower quality translations.

Also, among other things, it could make key lookup erroneously fail.

=item * Indicates use of a markup character (e.g. "You are \"awesome\".") which should be done differently (e.g. since that is will break the syntax if used in an HTML tag title attribute).

=back

=head1 possible violations

If you get false positives then that only goes to help highlight how ambiguity adds to the reason to avoid non-bytes strings!

=over 4

=item Contains escape sequence

A sequence of \n will be replaced w/ [comment,escaped sequence “n”], \" [comment,escaped sequence “"”], etc

=back

=head1 possible warnings

None
