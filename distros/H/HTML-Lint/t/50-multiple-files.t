#!perl

use warnings;
use strict;

use lib 't/';
use Util;

my @files = _get_paragraphed_files();

checkit( [
    [ 'elem-unopened' => qr/<\/p> with no opening <P>/i ],

    [ 'elem-unclosed' => qr/\Q<b> at (6:12) is never closed/i ],
    [ 'elem-unclosed' => qr/\Q<i> at (7:12) is never closed/i ],

    [ 'elem-unopened' => qr/<\/b> with no opening <B>/i ],
], @files );

# Read in a set of sets of lines, where each "file" is separated by a
# blank line in <DATA>
sub _get_paragraphed_files {
    local $/ = '';

    my @sets;

    while ( my $paragraph = <DATA> ) {
        my @lines = split /\n/, $paragraph;
        @lines = map { "$_\n" } @lines;
        push( @sets, [@lines] );
    }

    return @sets;
}


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
