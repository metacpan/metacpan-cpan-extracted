#!perl

use Test::More tests => 8;

use strict;
use warnings;

use JSPL;

my $rt = JSPL::Runtime->new();
my $cx = $rt->create_context();

is_deeply([$cx->get_options], ['xml'], "XML on by default");
is($cx->has_options("strict"), 0, "Off");
is($cx->{StrictEnable}, 0 , "The same");
$cx->toggle_options("strict");
$cx->{XMLEnable} = 0;
is_deeply([$cx->get_options], [qw(strict)], "Now ON");
is($cx->has_options("strict"), 1, "On");
is($cx->{StrictEnable}, 1, "The same");
{
    local $cx->{StrictEnable} = 0;
    is($cx->has_options("strict"), 0, "Reflected");
}
is($cx->has_options("strict"), 1, "Localization works");
