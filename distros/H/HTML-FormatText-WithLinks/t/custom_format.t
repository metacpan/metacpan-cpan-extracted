# $Id$

use Test::More tests => 9;
use HTML::FormatText::WithLinks;

my $html = new_html();
my $f = HTML::FormatText::WithLinks->new( leftmargin => 0, 
            before_link => "[%n] ",
            footnote => "[%n] %l");

ok($f, 'object created');

my $text = $f->parse($html);

my $correct_text = qq!This is a mail of some sort with a [1] link.



[1] http://example.com/


!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');

$f = HTML::FormatText::WithLinks->new( leftmargin => 0, 
            before_link => "[%n] ",
            footnote    =>  '');

$text = $f->parse($html);

$correct_text = qq!This is a mail of some sort with a [1] link.

!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted with no footnotes');

$correct_text = qq!This is a mail of some sort with a link[1].



1. http://example.com/


!;

$f = HTML::FormatText::WithLinks->new( leftmargin => 0, 
            before_link => "",
            after_link => "[%n]");

$text = $f->parse($html);

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted with after_link');

$correct_text = qq!This is a mail of some sort with a [0]link.



0. http://example.com/


!;

$f = HTML::FormatText::WithLinks->new( leftmargin => 0, 
            link_num_generator => sub { shift(); } );

$text = $f->parse($html);

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted with link_num_generator');

sub new_html {
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
