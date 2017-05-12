use Test::Simple 'no_plan';
use lib './lib';
use LEOCHARRE::HTML::Text 'html2txt';
use Smart::Comments '###';

$LEOCHARRE::HTML::Text::DEBUG = 1;

my $txt = html2txt('./t/bbc.html');
ok $txt;

## $txt

unlink './t/out.tmp';

open(FI,'>','./t/out.tmp');
print FI $txt;
close FI;
