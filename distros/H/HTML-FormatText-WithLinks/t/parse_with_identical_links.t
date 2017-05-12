# $Id: 03_parse_with_links.t 383 2004-01-12 17:09:27Z struan $

use Test::More tests => 9;
use HTML::FormatText::WithLinks;

my $html = simple_example();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0, unique_links => 1 );

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a [1]link and yet another [1]link.



1. http://example.com/


!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');

$html = complex_example();

$correct_text = qq!This is a mail of some sort with a [1]link and another [2]link and yet
another [1]link.



1. http://example.com/
2. http://example.net


!;

# recreate as otherwise output is a bit unpredictable
$f = HTML::FormatText::WithLinks->new( leftmargin => 0, unique_links => 1 );
$text = $f->parse($html);
ok($text, 'more complex html formatted');
is($text, $correct_text, 'more complex html correctly formatted');

$correct_text = qq!This is a mail of some sort with a link[1] and another link[2] and yet
another link[1].



1. http://example.com/
2. http://example.net


!;

# recreate as otherwise output is a bit unpredictable
$f = HTML::FormatText::WithLinks->new( leftmargin => 0, unique_links => 1, before_link => '', after_link => '[%n]' );
$text = $f->parse($html);
ok($text, 'after_link html formatted');
is($text, $correct_text, 'after_link html correctly formatted');



$f = HTML::FormatText::WithLinks->new( leftmargin => 0 );
$correct_text = qq!This is a mail of some sort with a [1]link and another [2]link and yet
another [3]link.



1. http://example.com/
2. http://example.net
3. http://example.com/


!;

$text = $f->parse($html);
ok($text, 'more complex html with non unique links formatted');
is($text, $correct_text, 'more complex html with non unique links correctly formatted');

sub simple_example {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort with a <a href="http://example.com/">link</a> and yet another <a href="http://example.com/">link</a>.
</p>
</body>
</html>
HTML
}

sub complex_example {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort with a <a href="http://example.com/">link</a> and another <a href="http://example.net">link</a> and yet another <a href="http://example.com/">link</a>.
</p>
</body>
</html>
HTML
}
