# $Id$

use Test::More tests => 3;
use HTML::FormatText::WithLinks;

my $f = HTML::FormatText::WithLinks->new();

ok($f, 'object created');

my $text = $f->parse();

is($text, undef, 'return undef if no html passed in');

$f = HTML::FormatText::WithLinks->new(
                    leftmargin => 0);

$text = $f->parse('');

is($text, '', 'return empty string if empty string passed in');

