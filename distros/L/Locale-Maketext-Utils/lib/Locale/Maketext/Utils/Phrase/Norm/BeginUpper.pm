package Locale::Maketext::Utils::Phrase::Norm::BeginUpper;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    my $string_sr = $filter->get_string_sr();

    if ( ${$string_sr} !~ m/\A(?:[A-Z]|(?:\[[^\]]+)|(?: …)|“)/ ) {

        # ${$string_sr} = "[comment,beginning needs to be upper case ?]" . ${$string_sr};
        $filter->add_warning('Does not start with an uppercase letter, ellipsis preceded by space, or bracket notation.');
    }

    # TODO (phrase obj?) If it starts w/ bracket notation will it be appropriately begun when rendered?

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

We want to make sure phrases begin correctly and consistently.

=head2 Rationale

Correct beginning case makes the meaning clearer to end users.

Clearer meaning makes it easier to make a good translation.

Consistent beginning case makes it easier for developers to work with.

Consistent beginning case is a sign of higher quality product.

Incorrect beginning case could be a sign that partial phrases are in use or an error has been made.

=head1 possible violations

None

=head1 possible warnings

=over 4

=item Does not start with an uppercase letter, ellipsis preceded by space, opening curly quote, or bracket notation.

Problem should be self explanatory.

If it is legit you could address this by adding a [comment] or [asis] to the beginning for clarity and to make it harder to use as a partial phrase.

   [comment,lc because …]lowercase this must be for some reason.

   [asis,brian d foy] is really cool!

=back
