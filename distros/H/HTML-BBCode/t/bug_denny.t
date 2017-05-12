#########################

use Test::More tests => 4;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $bbc = new HTML::BBCode;
isa_ok($bbc, 'HTML::BBCode', 'default');

my $result = '<span style="font-weight:bold">strong</span>'; 
my $text = "[B]strong[/B]";
is($bbc->parse($text), $result, "ALL UPPER CASE");
$text = "[B]strong[/b]";
is($bbc->parse($text), $result, "MiXeD CaSe");
