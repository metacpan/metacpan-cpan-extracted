# $Id$

use Test::More tests => 6;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a [1]link to a local anchor.



1. #top


!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');

sub new_html {
return <<'HTML';
<html>
<body>
<p>
This is a mail of some sort with a <a href="#top">link to a local anchor</a>.
</p>
</body>
</html>
HTML
}

my $f2 = HTML::FormatText::WithLinks->new( leftmargin => 0, anchor_links => 0 );

ok($f2, 'object created');

my $text2 = $f2->parse($html);

my $correct_text2 = qq!This is a mail of some sort with a link to a local anchor.

!;

ok($text2, 'html formatted');
is($text2, $correct_text2, 'html correctly formatted');
