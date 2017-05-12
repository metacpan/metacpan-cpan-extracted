use strict;
use warnings;

use Test::More tests => 16; 
use Test::Exception;

use Escape::Houdini qw/ :all /;

is escape_html( "<body>" ) => '&lt;body&gt;';
throws_ok { escape_html( [ 1..4]  ) } qr/\Qescape_html() argument not a string/;
is escape_html( 6 ) => 6;
is escape_html( '<div class="❤">foo</div>' ) => '&lt;div class=&quot;❤&quot;&gt;foo&lt;&#47;div&gt;';

is unescape_html( "&lt;body&gt;" ) => '<body>';
dies_ok { unescape_html( [ 1..4]  ) };
is unescape_html( 6 ) => 6;
is unescape_html( '&lt;div class=&quot;❤&quot;&gt;foo&lt;&#47;div&gt;' ) => '<div class="❤">foo</div>';

is escape_xml( "<foo>" ) => '&lt;foo&gt;';

my $url = "http://foo.com/meh";

is escape_url($url) => 'http%3A%2F%2Ffoo.com%2Fmeh';
is escape_uri($url) => $url;
is escape_href($url) => $url;

is unescape_url('http%3A%2F%2Ffoo.com%2Fmeh') => $url;
is unescape_uri($url) => $url;

is escape_js( "foo\nbar" ) => 'foo\nbar';
is unescape_js( 'foo\nbar' ) => "foo\nbar";

