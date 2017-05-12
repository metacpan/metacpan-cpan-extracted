#########################

use Test::More tests => 3;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;
use warnings;

# stripscripts enabled
my $bbc = HTML::BBCode->new();
is($bbc->parse('[color=blue" onmouseover="alert:XSS"]test[/color]'), '<span style="color:blue">test</span>', 'stripscripts enabled');

# stripscripts disabled
$bbc = HTML::BBCode->new({ stripscripts => 0 });
is($bbc->parse('[color=blue" onmouseover="alert:XSS"]test[/color]'), '<span style="color:blue" onmouseover="alert:XSS"">test</span>', 'stripscripts disabled');
