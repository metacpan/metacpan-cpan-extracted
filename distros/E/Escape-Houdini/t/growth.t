use strict;
use warnings;

use Test::More; 
use Escape::Houdini qw/ :all /;

eval "use Test::MemoryGrowth; 1" 
    or plan skip_all => 'Test::MemoryGrowth required for tests';

plan tests => 1;

eval q!

no_growth {
    escape_html( "<body>" );
    eval { escape_html( [ 1..4]  ) };
    escape_html( 6 );
    escape_html( '<div class="❤">foo</div>' );

    unescape_html( "&lt;body&gt;" );
    unescape_html( 6 );
    unescape_html( q{&lt;div class=&quot;❤&quot;&gt;foo&lt;&#47;div&gt;} );

    escape_xml( "<foo>" );

    my $url = "http://foo.com/meh";

    escape_url($url);
    escape_uri($url);
    escape_href($url);

    unescape_url('http%3A%2F%2Ffoo.com%2Fmeh');
    unescape_uri($url);

    escape_js( "foo\nbar" );
    unescape_js( 'foo\nbar' );
}

!;
