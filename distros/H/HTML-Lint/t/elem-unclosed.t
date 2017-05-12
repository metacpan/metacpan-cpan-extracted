use warnings;
use strict;
require 't/LintTest.pl';

checkit( [
    [ 'elem-unclosed' => qr/\Q<b> at (6:5) is never closed/i ],
    [ 'elem-unclosed' => qr/\Q<i> at (7:5) is never closed/i ],
], [<DATA>] );
    
__DATA__
<HTML>
    <HEAD> <!-- Checking for elem-unclosed -->
	<TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
	<P><B>This is my paragraph</P>
	<P><I>This is another paragraph</P>
    </BODY>
</HTML>
