use strict;
use lib('t/testlib');
use _Auxiliary;

chdir 'templates';
test 'default.tmpl', {};
test 'default.tmpl', {
			start => 'bar',
			c => 'books',
		};
