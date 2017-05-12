use strict;
use warnings;

use Test::More tests => 15;

require_ok('HTML::Laundry');
use HTML::Laundry::Rules;
my $rules = new HTML::Laundry::Rules;

my $l;
$l = HTML::Laundry->new({ notidy => 1 });
is( $l->clean(q{<a href="/foo.html">foo</a>}), q{<a href="/foo.html">foo</a>},
    q{Not providing empty base_uri doesn't rebase URIs});
$l = HTML::Laundry->new({ notidy => 1, base_uri => ''});
is( $l->clean(q{<a href="/foo.html">foo</a>}), q{<a href="/foo.html">foo</a>},
    q{Passing in empty base_uri doesn't rebase URIs});
$l = HTML::Laundry->new({ notidy => 1, base_uri => '/foo/'});
is( $l->clean(q{<a href="/foo.html">foo</a>}), q{<a href="/foo.html">foo</a>},
    q{Passing in relative base_uri doesn't rebase URIs});
$l = HTML::Laundry->new({ notidy => 1, base_uri => q{http://example.com/}});
is( $l->clean(q{<a href="/foo.html">foo</a>}),
    q{<a href="http://example.com/foo.html">foo</a>},
    q{Passing URI with trailing slash rebases URIs (1/2)});
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://example.com/foo.html">foo</a>},
    q{Passing URI with trailing slash rebases URIs (2/2)});
$l = HTML::Laundry->new({ notidy => 1, base_uri => q{http://example.com}});
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://example.com/foo.html">foo</a>},
    q{Passing URI without trailing slash rebases URIs (1/2)});
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://example.com/foo.html">foo</a>},
    q{Passing URI without trailing slash rebases URIs (2/2)});
$l = HTML::Laundry->new({ notidy => 1, base_uri => q{http://example.com:8080/bar/}});
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://example.com:8080/bar/foo.html">foo</a>},
    q{Passing URI with port and directory rebases URIs (1/2)});
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://example.com:8080/bar/foo.html">foo</a>},
    q{Passing URI with port and directory rebases URIs (2/2)});
is( $l->base_uri, q{http://example.com:8080/bar/}, 'base_uri method works as getter');
is( $l->base_uri(q{http://www.example.org}), q{http://www.example.org}, 
    q{base_uri method returns value given when used as setter} );
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="http://www.example.org/foo.html">foo</a>},
    q{base_uri method's new value is picked up for rebasing} );
ok( ! $l->base_uri(''), 'Passing empty string to base_uri returns false...');
is( $l->clean(q{<a href="foo.html">foo</a>}),
    q{<a href="foo.html">foo</a>},
    q{...and unsets base_uri} );
