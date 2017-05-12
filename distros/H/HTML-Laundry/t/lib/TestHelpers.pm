package TestHelpers;

use strict;
use warnings;

use HTML::TreeBuilder;
use Test::Differences 'eq_or_diff_text';

# This is a minimal clone of Test::Differences::HTML
# which has failing tests because Test::Differences has changed the output
# in version 0.63 (see RT#100514)
sub eq_or_diff_html {
    my ($raw, $expected, $label) = @_;

    return eq_or_diff_text(_normalise_html($raw), _normalise_html($expected), $label);
}

sub _normalise_html {
    my ($dirty_html) = @_;

    # Normalise the HTML by parsing it
    my $tree      = HTML::TreeBuilder->new_from_content($dirty_html);
    my $clean_html = $tree->as_HTML;

    $tree = $tree->delete; # don't assume we have TreeBuilder 5

    return $clean_html;
}

1;
