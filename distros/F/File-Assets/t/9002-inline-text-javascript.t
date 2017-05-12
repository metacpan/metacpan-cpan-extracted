#!perl -w

use strict;

use Test::More qw/no_plan/;
use t::Test;
my $assets = t::Test->assets;
my $scratch = t::Test->scratch;

ok($assets->include("css/apple.css"));
ok($assets->include(<<_END_));
<script type="text/javascript">
1 + 1;
</script>
_END_

compare($assets->export, qw(
    http://example.com/static/css/apple.css
), [ js => <<_END_ ]),

1 + 1;
_END_
