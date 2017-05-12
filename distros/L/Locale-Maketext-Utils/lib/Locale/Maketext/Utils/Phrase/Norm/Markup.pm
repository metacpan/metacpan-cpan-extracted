package Locale::Maketext::Utils::Phrase::Norm::Markup;

use strict;
use warnings;

sub normalize_maketext_string {
    my ($filter) = @_;

    # & is handled more in depth in it's own module
    if ( $filter->get_orig_str() =~ m/[<>"']/ ) {

        # normalize <>"' to [output,ENT]

        # this filter could be smarter like ampersand’s 'Prefer [output,amp] over …' and 'Prefer chr(38) over …'

        my $string_sr = $filter->get_string_sr();

        if ( ${$string_sr} =~ s/'/[output,apos]/g ) {
            $filter->add_warning('consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)');
        }
        if ( ${$string_sr} =~ s/"/[output,quot]/g ) {
            $filter->add_warning('consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)');
        }
        ${$string_sr} =~ s/>/[output,gt]/g;
        ${$string_sr} =~ s/</[output,lt]/g;

        $filter->add_violation('Contains markup related characters');
    }

    return $filter->return_value;
}

1;

__END__

=encoding utf-8

=head1 Normalization

Turn markup related characters into bracket notation.

=head2 Rationale

Allowing markup characters in the phrase is problematic for a number of reasons, including:

=over 4

=item * Markup only makes sense in one context.

=item * Their presence could unpredictably break markup or other syntax.

=item * Translators are likely to unwittingly change/break markup unless you take extra precautions (e.g. more <ph> handling of text/html ctype in XLIFF, yikes!).

=item * Markup could also make the translatable part harder for them to translate.

=item * Allowing markup encourages using your phrase as a template/branding/theming system which is a really terrible idea.

=item * if we don’t use them, even in chr() it is less problem prone since bracket notation allows to do things correctly in each context

=back

So we detect and modify them.

=head1 IF YOU USE THIS FILTER ALSO USE …

… THIS FILTER L<Locale::Maketext::Utils::Phrase::Norm::Ampersand>.

This is not enforced anywhere since we want to assume the coder knows what they are doing.

=head1 possible violations

=over 4

=item Contains markup related characters

Turns <>'" into appropriate bracket notation.

& is handled in its own driver.

=back

=head1 possible warnings

=over 4

=item consider if, instead of using straight double quotes, using “” is the right thing here (i.e. instead of bracket notation)

This is issued when " is encountered.

=item consider if, instead of using a straight apostrophe, using ‘’ for single quoting and ’ for an apostrophe is the right thing here (i.e. instead of bracket notation)

This is issued when ' is encountered.

=back
