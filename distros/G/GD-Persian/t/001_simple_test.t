
use strict;
use warnings;
use Test::More tests => 3;

use utf8;
use GD::Persian;

cmp_ok(GD::Persian::Convert("ب"), 'eq' , 'ب', 'simple char');

cmp_ok(GD::Persian::Convert("بچسبند"), 'eq' , 'ﺪﻨﺒﺴﭽﺑ', 'just one word');


cmp_ok(GD::Persian::Convert("کشتم شپشه شپش کش شش پا را"), 'eq' , 'اﺭ ﺎﭘ ﺶﺷ ﺶﻛ ﺶﭙﺷ ﻪﺸﭙﺷ ﻢﺘﺸﻛ', 'compelex chars and big word');
