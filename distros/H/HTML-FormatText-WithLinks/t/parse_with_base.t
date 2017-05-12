# $Id$

use Test::More tests => 9;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a [1]link.



1. http://example.com/relative.html


!;

my $override_text = qq!This is a mail of some sort with a [1]link.



1. http://example.net/relative.html


!;


ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');

my $f2 = HTML::FormatText::WithLinks->new( leftmargin => 0,
                                           base => 'http://example.net/'
                                         );

ok($f2, 'object created');

my $text2 = $f2->parse($html);
ok($text2, 'html formatted');
is($text2, $override_text, 'html correctly formatted - config base overrides doc');

my $f3 = HTML::FormatText::WithLinks->new( leftmargin => 0,
                                           base => 'http://example.net/',
                                           doc_overrides_base => 1
                                         );

ok($f3, 'object created');

my $text3 = $f3->parse($html);
ok($text3, 'html formatted');
is($text3, $correct_text, 'html correctly formatted - doc overrides config');

sub new_html {
return <<'HTML';
<html>
<head>
<base href="http://example.com/" />
<body>
<p>
This is a mail of some sort with a <a href="/relative.html">link</a>.
</p>
</body>
</html>
HTML
}
