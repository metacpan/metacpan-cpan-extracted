#!/usr/bin/env perl

use warnings;
use strict;

use Test::More;
use Test::Exception;

use_ok('DateTimeX::Period') or BAIL_OUT;

# Test that DateTime returns something
lives_ok { DateTimeX::Period->from_epoch( epoch => 123456 )}
	'Lives ok on good parameter';

done_testing();
