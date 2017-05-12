# check core module: lib

use strict;
use warnings;

use Test::More tests => 14;

#=== Dependencies
use Konstrukt::Settings;
#use Konstrukt::Debug;

#Lib
use Konstrukt::Lib;
is($Konstrukt::Lib->init(), 1, "init");


is($Konstrukt::Lib->crlf2br("a\nb\r\nc\rd"), "a<br />\nb<br />\nc<br />\nd", "crlf2br");
is($Konstrukt::Lib->html_escape("some <tag> here & \"<there>\""), "some &lt;tag&gt; here &amp; &quot;&lt;there&gt;&quot;", "html_escape");
is($Konstrukt::Lib->html_paragraphify("some\ntest\n\ntext\nmight go\nhere"), "<p>some</p>\n<p>test</p>\n<p>text</p>\n<p>might go</p>\n<p>here</p>\n", "html_paragraphify");
is($Konstrukt::Lib->html_unescape("some &lt;tag&gt; here &amp; &quot;&lt;there&gt;&quot;"), "some <tag> here & \"<there>\"", "html_unescape");
my $pw1 = $Konstrukt::Lib->random_password(8);
my $pw2 = $Konstrukt::Lib->random_password(8);
is(length($pw1), 8, "random_password: length");
isnt($pw1, $pw2, "random_password: different pws");
my $badchars = "\001\011\013\014\016\037\041\052\057\074\077\133\136\140\173\377";
is($Konstrukt::Lib->sh_escape($badchars), "", "sh_escape");
use Time::Zone;
my $time = 1138845845;
my $diff = sprintf("%+03d", tz_local_offset($time) / 3600);
is($Konstrukt::Lib->date_w3c(qw/2006 1 2 3 4 5/), "2006-01-02T03:04:05$diff:00", "date_w3c");
is($Konstrukt::Lib->date_rfc822(qw/2006 1 2 3 4 5/), "Mon, 02 Jan 2006 03:04:05 ${diff}00", "date_w3c");
$time = 1149382921;
$diff = sprintf("%+03d", tz_local_offset($time) / 3600);
is($Konstrukt::Lib->date_w3c(qw/2006 5 4 3 2 1/), "2006-05-04T03:02:01$diff:00", "date_w3c");
is($Konstrukt::Lib->date_rfc822(qw/2006 5 4 3 2 1/), "Thu, 04 May 2006 03:02:01 ${diff}00", "date_rfc822");
is($Konstrukt::Lib->xml_escape("some <tag> here & \"<there>\""), "some &lt;tag&gt; here &amp; &quot;&lt;there&gt;&quot;", "xml_escape");
is($Konstrukt::Lib->xml_escape("some special characters: !@#$%^&*()", 1), "some&#032;special&#032;characters&#058;&#032;&#033;&#064;&#035;0&#094;&#038;&#042;&#040;&#041;", "xml_escape: escape all");

#TODO: test get_dir_size?
#TODO: test mail?

exit;
