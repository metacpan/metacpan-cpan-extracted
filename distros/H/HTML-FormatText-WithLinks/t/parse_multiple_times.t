# $Id$

use Test::More tests => 5;
use HTML::FormatText::WithLinks;

my $html_link = new_html_link();
my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse($html_link);

my $correct_text = qq!This is a mail of some sort with a [1]link.



1. http://example.com/


!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');

$text = $f->parse($html);

ok($text, 'html formatted');
is($text, "\n\nThis is a mail of some sort\n\n", 
          'html correctly formatted with no left margin');

sub new_html_link {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort with a <a href="http://example.com/">link</a>.
</p>
</body>
</html>
HTML
}

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
