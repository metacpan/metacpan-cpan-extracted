#!perl -T

use Test::More;
use IRC::Formatting::HTML qw/irc_to_html/;

my $empty = "";
my $html = irc_to_html($empty);
ok($html eq "");

my $zero = "0";
$html = irc_to_html($zero);
ok($html eq '<span style="">0</span>');

done_testing();
