use Test::More 'no_plan';
use HTML::FormatText::WithLinks;

my $html = simple_example();
my $f = HTML::FormatText::WithLinks->new(
    leftmargin          => 0,
    skip_linked_urls    => 1,
    before_link         => '',
    after_link          => ' (%l)',
    footnote            => ''
);

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a bunch of linked URLs.

http://example.com/

and another https://example.com/

ftp now ftp://example.com

not the same but not this (http://example.com/)

or this http://example.com (http://example.com/foo)

!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');


sub simple_example {
return <<'HTML';
<html>
<body>
<p>This is a mail of some sort with a bunch of linked URLs.</p>
<p><a href="http://example.com/">http://example.com/</a></p>
<p>and another <a href="https://example.com/">https://example.com/</a></p>
<p>ftp now <a href="ftp://example.com">ftp://example.com</a></p>
<p>not the same <a href="http://example.com/">but not this</a></p>
<p>or this <a href="http://example.com/foo">http://example.com</a></p>
</body>
</html>
HTML
}

