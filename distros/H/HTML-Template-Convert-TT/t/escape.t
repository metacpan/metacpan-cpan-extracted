use strict;
use lib('t/testlib');
use _Auxiliary;

chdir 'templates';
test 'escape.tmpl', {
			STUFF => '<>"\''
		};
test 'urlescape.tmpl', { STUFF => '<>"; %FA' };
test 'js.tmpl', { msg => qq{"He said 'Hello'.\n\r"} };
test 'default_escape.tmpl', { STUFF => q{Joined with space} };
