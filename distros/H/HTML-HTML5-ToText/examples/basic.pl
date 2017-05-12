use lib "../lib";
use lib "lib";

use HTML::HTML5::Parser;
use HTML::HTML5::ToText;

my $dom = HTML::HTML5::Parser->load_html(IO => \*DATA);
print HTML::HTML5::ToText->with_traits(qw/TextFormatting ShowLinks ShowImages/)->process( $dom );

__DATA__
<!doctype html>
<title>Foo</title>
<link rel=stylesheet href=style.css>
<p><b>Hello <a href="http://enwp.org/Earth">world</a></b></p>
<p><i>how are<br><img src=you.jpeg alt=you>?</i></p>
