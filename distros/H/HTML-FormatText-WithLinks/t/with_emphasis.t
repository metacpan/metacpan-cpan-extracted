# $Id: 02_basic_parse.t 383 2004-01-12 17:09:27Z struan $

use Test::More tests => 9;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( with_emphasis => 1 );

ok($f, 'object created');

my $text = $f->parse($html);

ok($text, 'html formatted');
is($text, "   This is a mail of _some_ /sort/\n\n   It has _some_ of the /words/ emphasised\n\n", 'html correctly formatted with emphasis');

my $f2 = HTML::FormatText::WithLinks->new( );

ok( $f2, "object created" );

my $text2= $f2->parse( $html );

ok( $text2, "html formatted" );
is( $text2, "   This is a mail of some sort\n\n   It has some of the words emphasised\n\n", 'html correctly formatted without emphasis' ); 

# Test alternate markers
$f = HTML::FormatText::WithLinks->new( with_emphasis => 1, bold_marker => '*', italic_marker => '"' );
ok($f, 'object created');
$text = $f->parse($html);
ok($text, 'html formatted');
is($text, qq[   This is a mail of *some* "sort"\n\n   It has *some* of the "words" emphasised\n\n], 'html correctly formatted with emphasis');

sub new_html {
return <<'HTML';
<html>
<body>
<p>
This is a mail of <b>some</b> <i>sort</i>
</p>

<p>
It has <strong>some</strong> of the <em>words</em> emphasised
</p>
</body>
</html>
HTML
}
