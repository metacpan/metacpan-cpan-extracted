#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 2 }

use Lingua::UK::Jcuken;

ok(Lingua::UK::Jcuken::jcu2qwe('õæãª¥­', 'cp866'), ']werty');
ok(Lingua::UK::Jcuken::jcu2qwe('³¿ºéöó'), "s]'qwe");

exit;
