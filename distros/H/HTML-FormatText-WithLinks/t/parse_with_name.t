# $Id$

use Test::More tests => 6;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a link.

!;

ok($text, 'html formatted');
is($text, $correct_text, 'html with name only link correctly formatted');

my $f2 = HTML::FormatText::WithLinks->new( leftmargin => 0,
                                           base       => 'http://example.com' );
ok($f2, 'object created');

$text = $f2->parse($html);

ok($text, 'html formatted');
is($text, $correct_text, 'html with name only link and base set correctly formatted');

sub new_html {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort with a <a name="foo">link</a>.
</p>
</body>
</html>
HTML
}
