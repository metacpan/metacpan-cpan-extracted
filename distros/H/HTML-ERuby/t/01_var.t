use strict;
use Test::More tests => 1;

use HTML::ERuby;

my $erb = HTML::ERuby->new;
my $res = $erb->compile(filename => './t/var.rhtml');

like $res, qr/Hello World/;
