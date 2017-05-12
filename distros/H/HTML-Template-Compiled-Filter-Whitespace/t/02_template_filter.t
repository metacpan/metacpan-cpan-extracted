#!perl -T

use strict;
use warnings;

use HTML::Template::Compiled 0.84;
use Test::More tests => 3;
use Test::Differences;
use Test::NoWarnings;

BEGIN {
    use_ok
        'HTML::Template::Compiled::Filter::Whitespace',
        'get_whitespace_filter';
}

my $htc = HTML::Template::Compiled->new(
    tagstyle  => [ qw( -classic -comment +asp ) ],
    filter    => get_whitespace_filter,
    scalarref => \<<'EOT');
<html>

</html>
EOT

my $clean_html = <<'EOT';
<html>
</html>
EOT

$htc->param;
eq_or_diff
    $htc->output,
    $clean_html,
    'filtered';
