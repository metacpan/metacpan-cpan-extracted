# $Id$

use Test::More tests => 5;
use HTML::FormatText::WithLinks;

my $f = HTML::FormatText::WithLinks->new( leftmargin => 0 );

ok($f, 'object created');

my $text = $f->parse_file('t/missing.html');

is($text, undef, 'undef returned for missing file');
is($f->error, 't/missing.html not found or not a regular file',
                'correct error message for missing file');

$text = $f->parse_file('.');

is($text, undef, 'undef returned for directory');
is($f->error, '. not found or not a regular file',
                'correct error message for directory');
