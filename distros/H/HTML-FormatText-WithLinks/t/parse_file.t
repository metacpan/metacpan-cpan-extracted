# $Id$

use Test::More tests => 3;
use HTML::FormatText::WithLinks;

my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse_file('t/file.html');

my $correct_text = qq!This is a mail of some sort with a [1]link.



1. http://example.com/


!;

ok($text, 'html formatted');
is($text, $correct_text, 'html correctly formatted');
