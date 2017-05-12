use Test::More tests => 1;
use HTML::HTML5::Parser;
use HTML::HTML5::ToText;

my $dom = HTML::HTML5::Parser->load_html(IO => \*DATA);
my $str = HTML::HTML5::ToText->with_traits(qw/TextFormatting ShowLinks ShowImages/)->process($dom);
is $str, <<'OUTPUT';
Foo
LINK: <style.css> (stylesheet)


*Hello world <http://enwp.org/Earth>*

_how_are
[IMG:_you]?_
OUTPUT

__DATA__
<!doctype html>
<title>Foo</title>
<link rel=stylesheet href=style.css>
<!-- comment -->
<p><b>Hello <a href="http://enwp.org/Earth">world</a></b></p>
<p><i>how are<br><img src=you.jpeg alt=you>?</i></p>
