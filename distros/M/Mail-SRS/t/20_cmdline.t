use strict;
use warnings;
use blib;

use Test::More tests => 1;

{
	local $^C = 1;
	do "script/srs";
}

ok(1, 'Parsed script!');
