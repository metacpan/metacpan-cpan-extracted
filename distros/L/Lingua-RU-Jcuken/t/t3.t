#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 3 }

use Lingua::RU::Jcuken;

ok(Lingua::RU::Jcuken::qwe2jcu('qwerty', 'cp866'), 'йцукен');
ok(Lingua::RU::Jcuken::qwe2jcu('gfhjkm', 'cp866'), 'пароль');
ok(Lingua::RU::Jcuken::qwe2jcu('йцукен', 'cp866'), 'йцукен');

exit;
