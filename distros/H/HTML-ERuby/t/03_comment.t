use strict;
use Test::More tests => 2;

use HTML::ERuby;

my $erb = HTML::ERuby->new;
my $res = $erb->compile(filename => './t/comment.rhtml');

unlike $res, qr/Hello/;
like $res, qr/<% foo %>/;

