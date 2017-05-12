#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 1 }

use Lingua::RU::Jcuken;

ok(Lingua::RU::Jcuken::jcu2qwe('йцукен'), 'qwerty');

exit;
