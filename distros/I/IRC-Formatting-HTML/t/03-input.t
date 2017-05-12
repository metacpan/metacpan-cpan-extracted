#!perl -T

use Test::More;
use IRC::Formatting::HTML qw/html_to_irc/;
use IRC::Formatting::HTML::Common;

my $nohtml = "No html here";
my $irc = html_to_irc($nohtml);
is($irc, $nohtml);

my $newline = "first line<div>second line</div>";
$irc = html_to_irc($newline);
is ($irc, "first line\nsecond line");

my $bold = "<b>Bold</b>notbold";
$irc = html_to_irc($bold);
is($irc, $BOLD."Bold".$BOLD."notbold");

my $bolditalic = "<b><i>Hjalp</i></b>";
$irc = html_to_irc($bolditalic);
is($irc, $BOLD.$INVERSE."Hjalp".$INVERSE.$BOLD);

my $inverse = "<i>Inverse</i>";
$irc = html_to_irc($inverse);
is($irc, $INVERSE."Inverse".$INVERSE);

my $underline = "<u>Underline</u>";
$irc = html_to_irc($underline);
is($irc, $UNDERLINE."Underline".$UNDERLINE);

my $combo = "<b>Combo <i>formatting</i></b>";
$irc = html_to_irc($combo);
is($irc, $BOLD."Combo ".$INVERSE."formatting".$INVERSE.$BOLD);

my $everything = "<b><i><u>Everything</u></i></b>";
$irc = html_to_irc($everything);
is($irc, $BOLD.$INVERSE.$UNDERLINE."Everything".$UNDERLINE.$INVERSE.$BOLD);

my $nbsp = "&nbsp;<b>some text</b>";
$irc = html_to_irc($nbsp);
is($irc, " ".$BOLD."some text".$BOLD);

my $colored = "<span style='color:#ddd'>some <span style='color:#fff'>text</span></span> heh";
$irc = html_to_irc($colored);
is($irc, $COLOR."15some ".$COLOR."00text".$COLOR."15$COLOR heh");

my $big_color = '<span class="Apple-style-span" style="color: rgb(51, 51, 51); font-family: Arial, Helvetica, sans-serif; font-size: 14px; line-height: 16px; white-space: normal; font-weight: bold; "><span class="ars-features" style="color: rgb(248, 84, 1); background-image: url(http://static.arstechnica.com//public/v6/styles/light/images/sidebar/misc-icons-sprite.png); background-attachment: initial; background-origin: initial; background-clip: initial; background-color: initial; padding-left: 16px; background-position: 0px -298px; background-repeat: no-repeat no-repeat; ">Ars Technica Features:</span>Browse our latest in-depth, full-length stories.</span>';
$irc = html_to_irc($big_color);
is $irc, $COLOR."01".$BOLD.$COLOR."07Ars Technica Features:".$COLOR."01Browse our latest in-depth, full-length stories.$BOLD$COLOR";

my $h2_newline = "<h2>Headline</h2>\n<p>what the what</p>";
$irc = html_to_irc($h2_newline);
is $irc, $BOLD."Headline".$BOLD."\nwhat the what";

my $fonttag = '<FONT COLOR="#FF0000">t</FONT><FONT COLOR="#FFff00">e</FONT><FONT COLOR="#00ff00">s</FONT><FONT COLOR="#00ffff">t</FONT>';
$irc = html_to_irc($fonttag);
is $irc, $COLOR."04t".$COLOR.$COLOR."08e".$COLOR.$COLOR."09s".$COLOR.$COLOR."11t".$COLOR;

my $false_char = "0 hello";
$irc = html_to_irc($false_char);
is ($irc, "0 hello");

my $bgcolor = '<span style="background-color: rgb(255, 246, 169);">started following</span>';
$irc = html_to_irc($bgcolor);
is $irc, $COLOR."01,15started following".$COLOR;

my $fg_bg_color = '<span style="color: #fff"><span style="background-color: rgb(255, 246, 169);">started following</span></span>';
$irc = html_to_irc($fg_bg_color);
is $irc, $COLOR."00".$COLOR."00,15started following".$COLOR."00".$COLOR;


done_testing();
