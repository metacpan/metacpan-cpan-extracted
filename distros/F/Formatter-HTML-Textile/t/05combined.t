use Test::More tests=>2;
use Formatter::HTML::Textile;

my $source = <<SOURCE;
h1. Some title

start paragraph

another paragraph

* list of things with "urls":http://www.jerakeen.org in
* more things in the list

a http://bare.url.here. and an email\@address.com

SOURCE

my $formatter = Formatter::HTML::Textile->format($source);
my $dest = $formatter->fragment."\n";

my $expected = <<EXPECTED;
<h1>Some title</h1>

<p>start paragraph</p>

<p>another paragraph</p>

<ul>
<li>list of things with <a href="http://www.jerakeen.org">urls</a> in</li>
<li>more things in the list</li>
</ul>

<p>a http://bare.url.here. and an email\@address.com</p>
EXPECTED

is($dest,$expected);

is($formatter->title, "Some title");
