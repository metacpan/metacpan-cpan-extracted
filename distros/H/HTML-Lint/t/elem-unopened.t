use warnings;
use strict;
require 't/LintTest.pl';

checkit( [
    [ 'elem-unopened' => qr/<\/p> with no opening <P>/i ],
], [<DATA>] );

__DATA__
<HTML> <!-- for elem-unopened -->
    <HEAD>
	<TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
	This is my paragraph</P>
    </BODY>
</HTML>
