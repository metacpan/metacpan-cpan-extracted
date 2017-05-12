use warnings;
use strict;

require 't/LintTest.pl';

my @files = get_paragraphed_files();

checkit( [
    [ 'elem-unopened' => qr/<\/p> with no opening <P>/i ],

    [ 'elem-unclosed' => qr/<b> at \(6:5\) is never closed/i ],
    [ 'elem-unclosed' => qr/<i> at \(7:5\) is never closed/i ],

    [ 'elem-unopened' => qr/<\/b> with no opening <B>/i ],
], @files );

__DATA__
<HTML> <!-- for elem-unopened -->
    <HEAD>
	<TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
	This is my paragraph</P>
    </BODY>
</HTML>

<HTML>
    <HEAD> <!-- Checking for elem-unclosed -->
	<TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
	<P><B>This is my paragraph</P>
	<P><I>This is another paragraph</P>
    </BODY>
</HTML>

<!-- based on doc-tag-required -->
<HTML>
    <HEAD>
	<TITLE>Test stuff</TITLE>
    </HEAD>
    <BODY BGCOLOR="white">
        </B>Gratuitous unnecessary closing tag that does NOT match to the opening [B] above.
	<P>This is my paragraph</P>
    </BODY>
</HTML>
