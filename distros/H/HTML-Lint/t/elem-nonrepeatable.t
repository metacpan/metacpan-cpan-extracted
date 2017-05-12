use warnings;
use strict;
require 't/LintTest.pl';

checkit( [
    [ 'elem-nonrepeatable' => qr/<title> is not repeatable, but already appeared at \(3:2\)/i ],
], [<DATA>] );
    
__DATA__
<HTML>
    <HEAD>
	<TITLE>Test stuff</TITLE>
	<TITLE>As if one title isn't enough</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
	<P>This is my paragraph</P>
    </BODY>
</HTML>
