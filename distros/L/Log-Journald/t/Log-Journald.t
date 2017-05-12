# Basically just tests this imports fine. Needs improvement.

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Log::Journald') };
