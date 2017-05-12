
use strict;
use Test::More tests => 12;

BEGIN { $^W = 1 }

use HTML::StripScripts;
my $f = HTML::StripScripts->new({ AllowHref => 1 });

my $allow_rel = 0;
mytest( '<a href="script:badness">',  '<a>x</a>',                        'malicious'   );
mytest( '<a href="^%&34lj34">',       '<a>x</a>',                        'garbage'     );
mytest( '<a href="http://foo.com/">', '<a href="http://foo.com/">x</a>', 'absolute'    );
mytest( '<a href="/foo/bar.html">',   '<a>x</a>',                        'full'        );
mytest( '<a href="foo.html">',        '<a>x</a>',                        'relative'    );
mytest( '<a href="../foo.html">',     '<a>x</a>',                        'relative ..' );

$allow_rel = 1;
$f = HTML::StripScripts->new({ AllowHref => 1, AllowRelURL => 1 });
mytest( '<a href="script:badness">',  '<a>x</a>',                        'malicious'   );
mytest( '<a href="^%&34lj34">',       '<a>x</a>',                        'garbage'     );
mytest( '<a href="http://foo.com/">', '<a href="http://foo.com/">x</a>', 'absolute'    );
mytest( '<a href="/foo/bar.html">',   '<a href="/foo/bar.html">x</a>',   'full'        );
mytest( '<a href="foo.html">',        '<a href="foo.html">x</a>',        'relative'    );
mytest( '<a href="../foo.html">',     '<a href="../foo.html">x</a>',     'relative ..' );


sub mytest {
    my ($in, $out, $name) = @_;

    $f->input_start_document;
    $f->input_start($in);
    $f->input_text('x');
    $f->input_end_document;
    is( $f->filtered_document, $out, ($allow_rel ? 'yes' : 'no') . " rel $name" );
}

