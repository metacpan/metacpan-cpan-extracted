use strict;
use Test::More tests => 3;

use HTML::ERuby;

my $erb = HTML::ERuby->new;
my $res = $erb->compile(filename => './t/loop.rhtml');

like $res, qr/foo<BR>/;
like $res, qr/bar<BR>/;
like $res, qr/baz<BR>/;
