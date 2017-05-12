#!/usr/bin/env perl -w

use strict;
use Test;

BEGIN { plan tests => 3 }

use Lingua::UK::Jcuken;

ok(Lingua::UK::Jcuken::qwe2jcu('qwerty', 'cp866'), 'йцукен');
ok(Lingua::UK::Jcuken::qwe2jcu('gfhjkm', 'cp866'), 'пароль');
ok(Lingua::UK::Jcuken::qwe2jcu('йцукен', 'cp866'), 'йцукен');

exit;
