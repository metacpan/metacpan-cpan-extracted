use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok('Digest::BLAKE'); }

diag "Testing Digest::BLAKE $Digest::BLAKE::VERSION";
