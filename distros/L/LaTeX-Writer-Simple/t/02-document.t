#!/usr/bin/perl

use strict;
use warnings;
use LaTeX::Writer::Simple;
use Test::More tests => 17;

my $foo = document();
like($foo, qr/^\\documentclass\[\]\{article}/, "A document starts with a documentclass command");
like($foo, qr/\\end\{document}\n$/, "A document ends with \\end{document}");
like($foo, qr/\\begin\{document}\n/, "A document includes a \\begin{document}");
like($foo, qr/\\usepackage\{url}\n/, "A document uses package url by default");
like($foo, qr/\\usepackage\{graphicx}\n/, "A document uses package graphicx by default");
like($foo, qr/\\usepackage\[english\]\{babel}\n/, "A document uses English babel");
like($foo, qr/\\usepackage\[utf8\]\{inputenc}\n/, "The document uses UTF8");
like($foo, qr/\\title\{}\n/, "A document doesn't have a title defined");
like($foo, qr/\\date\{\\today}\n/, "A document date is \\today");
like($foo, qr/\\author\{}\n/, "The defaults document author is empty");
like($foo, qr/\\maketitle\n/, "The default document has a maketitle");

$foo = document( { author => "Foo Bar Junior",
                   packages => { url => 0 } } );
unlike($foo, qr/\\usepackage\{url}\n/, "This document does not use package url");
like($foo, qr/\\author\{Foo Bar Junior}\n/, "This author is defined");

$foo = document( { author => [qw/Foo Bar/],
                   documentclass => 'report',
                   options => '12pt'} );
like($foo, qr/^\\documentclass\[12pt\]\{report}/, "A specific documentclass and text size");
like($foo, qr/\\author\{Foo \\and Bar}\n/, "This author is a list");

$foo = document( { documentclass => 'book',
                   maketitle => 0,
                   options => ['12pt','a4paper'] } );
like($foo, qr/^\\documentclass\[12pt,a4paper\]\{book}/, "A list of options");
unlike($foo, qr/\\maketitle\n/, "The default document has a maketitle");