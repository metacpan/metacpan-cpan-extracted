#!perl -T

use Test::More;
use IRC::Formatting::HTML qw/irc_to_html/;

my $bold = "\002Bold";
my $html = irc_to_html($bold);
ok($html eq '<span style="font-weight: bold;">Bold</span>');

my $boldinverse = "\002\026Boldinverse\002\026";
$html = irc_to_html($boldinverse);
is ($html, '<span style="color: #fff;background-color: #000;font-weight: bold;">Boldinverse</span>');

my $inverse = "\026Inverse";
$html = irc_to_html($inverse);
ok($html eq '<span style="color: #fff;background-color: #000;">Inverse</span>');

my $italic = "\026Italic";
$html = irc_to_html($italic, invert => "italic");
is $html, '<span style="font-style: italic;">Italic</span>';

my $underline = "\037Underline";
$html = irc_to_html($underline);
ok($html eq '<span style="text-decoration: underline;">Underline</span>');

my $color = "\0033,4Color";
$html = irc_to_html($color);
ok($html eq '<span style="color: #080;background-color: #f00;">Color</span>');

my $italiccolor = "\026\0033,4Color";
$html = irc_to_html($italiccolor, invert => "italic");
is $html, '<span style="font-style: italic;color: #080;background-color: #f00;">Color</span>';


my $everything = "$bold$inverse$underline$color";
$html = irc_to_html($everything);
ok($html eq '<span style="font-weight: bold;">Bold</span><span style="color: #fff;background-color: #000;font-weight: bold;">Inverse</span><span style="color: #fff;background-color: #000;font-weight: bold;text-decoration: underline;">Underline</span><span style="color: #f00;background-color: #080;font-weight: bold;text-decoration: underline;">Color</span>');

my $everything_lines = join "\n", ($bold, $inverse, $underline, $color);
$html = irc_to_html($everything_lines);
ok($html eq join "\n",
('<span style="font-weight: bold;">Bold</span>',
 '<span style="color: #fff;background-color: #000;">Inverse</span>',
 '<span style="text-decoration: underline;">Underline</span>',
 '<span style="color: #080;background-color: #f00;">Color</span>'));

$html = irc_to_html($everything_lines, classes => 1);
ok($html eq join "\n",
('<span class="bold">Bold</span>',
 '<span class="fg-fff bg-000">Inverse</span>',
 '<span class="ul">Underline</span>',
 '<span class="fg-080 bg-f00">Color</span>'));

done_testing();
