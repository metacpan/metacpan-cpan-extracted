#########################

use Test::More tests => 2;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode();

my $text = '[color=blue" onmouseover="this.innerHTML = \'XSS\']test[/color]';
is($bbc->parse($text), '<span style="color:blue">test</span>');
