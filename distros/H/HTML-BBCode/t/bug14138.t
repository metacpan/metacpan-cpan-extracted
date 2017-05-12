#########################

use Test::More tests => 5;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode', 'default');

my $text = "server has high pings constantly (450ish - 2k) and restarts/crashes are starting to become an everyday thing ;[ ";
is($bbc->parse($text), "server has high pings constantly (450ish - 2k) and restarts/crashes are starting to become an everyday thing ;[ ", "bug text");

$text = "server has [b]high[/b] pings constantly (450ish - 2k) and restarts/crashes are starting to become an everyday thing ;[ ";
is($bbc->parse($text), 'server has <span style="font-weight:bold">high</span> pings constantly (450ish - 2k) and restarts/crashes are starting to become an everyday thing ;[ ', "bug text with BBCode added");


$text = "server ;] has high pings constantly (450ish - 2k) ;[ and restarts/crashes are starting to become an everyday thing ;[ ";
is($bbc->parse($text), "server ;] has high pings constantly (450ish - 2k) ;[ and restarts/crashes are starting to become an everyday thing ;[ ", "bug text extreme");
