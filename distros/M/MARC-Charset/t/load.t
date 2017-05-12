use Test::More tests => 3;
use strict;
use warnings;

use_ok('MARC::Charset');
ok(MARC::Charset->can('marc8_to_utf8'), 'has marc8_to_utf8');
ok((grep /marc8_to_utf8/, @MARC::Charset::EXPORT_OK), 'marc8_to_utf8 exported');


