#!perl -T

use strict;
use warnings;

use Test::More;

use Encoding::FixLatin qw(fix_latin);

my $output = eval {
    fix_latin("Caf\xE9");
};

is($@, '', 'no exception when XS module allowed to load');

is($output, "Caf\x{e9}", 'output is as expected');

my $not = $INC{'Encoding/FixLatin/XS.pm'} ? '' : ' not';

ok(1, "XS module was$not found/loaded");

done_testing();

