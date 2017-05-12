#########################

use Test::More tests => 4;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode');

my $text = "[url=ftp://www.example.com/?a=b&c=d]bug...[/url]";
is($bbc->parse($text), '<a href="ftp://www.example.com/?a=b&amp;c=d">bug...</a>');
$text = "[url=ftp://www.example.com/?a=b;c=damp;blah]what?[/url]";
is($bbc->parse($text), '<a href="ftp://www.example.com/?a=b;c=damp;blah">what?</a>');
