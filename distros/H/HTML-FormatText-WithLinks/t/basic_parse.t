# $Id$

use Test::More tests => 5;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new();

ok($f, 'object created');

my $text = $f->parse($html);

ok($text, 'html formatted');
is($text, "   This is a mail of some sort\n\n", 'html correctly formatted');

$f = HTML::FormatText::WithLinks->new(
                    leftmargin => 0);

$text = $f->parse($html);

ok($text, 'html formatted');
is($text, "This is a mail of some sort\n\n", 
          'html correctly formatted with no left margin');


sub new_html {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort
</p>
</body>
</html>
HTML
}
