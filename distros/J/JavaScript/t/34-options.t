#!perl

use Test::More tests => 4;

use strict;
use warnings;

use JavaScript;

my $rt = JavaScript::Runtime->new();
my $cx = $rt->create_context();

is_deeply([$cx->get_options], []);

is($cx->has_options("strict"), 0);
$cx->toggle_options("strict");
is_deeply([$cx->get_options], [qw(strict)]);
is($cx->has_options("strict"), 1);
