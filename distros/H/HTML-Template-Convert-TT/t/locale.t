use strict;
use lib('t/testlib');
use _Auxiliary;

chdir 'templates';
test 'locale.tmpl', {foo => 'bar'};
