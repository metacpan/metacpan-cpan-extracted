#########################

use Test::More tests => 5;
BEGIN { use_ok 'HTML::BBCode'; }

#########################

use strict;

my $p1 = new HTML::BBCode({
    allowed_tags => [ qw( b i u img ) ]
});
my $p2 = new HTML::BBCode({
    allowed_tags => [ qw( b i u ) ]
});
my $text1 = "[img=http://phpbb.com/logo.gif]phpBB logo[/img][b]BBCode[/b] - is a simple [i]markup language[/i] used in [url=http://phpbb.com/]phpBB[/url].";
my $text2 = "[b]BBCode[/b] - is a simple [i]markup language[/i] used in [url=http://phpbb.com/]phpBB[/url].[img=http://phpbb.com/logo.gif]phpBB logo[/img]";

is($p1->parse($text1), '<img alt="" src="http://phpbb.com/logo.gif" /><span style="font-weight:bold">BBCode</span> - is a simple <span style="font-style:italic">markup language</span> used in [url=http://phpbb.com/]phpBB[/url].', '1st parser 1 text');

is($p2->parse($text1), '[img=http://phpbb.com/logo.gif]phpBB logo[/img]<span style="font-weight:bold">BBCode</span> - is a simple <span style="font-style:italic">markup language</span> used in [url=http://phpbb.com/]phpBB[/url].','2nd parser 1 text (patched ;)');

is($p1->parse($text2), '<span style="font-weight:bold">BBCode</span> - is a simple <span style="font-style:italic">markup language</span> used in [url=http://phpbb.com/]phpBB[/url].<img alt="" src="http://phpbb.com/logo.gif" />', '1st parser 2 text'); 


is($p2->parse($text2), '<span style="font-weight:bold">BBCode</span> - is a simple <span style="font-style:italic">markup language</span> used in [url=http://phpbb.com/]phpBB[/url].[img=http://phpbb.com/logo.gif]phpBB logo[/img]', '2nd parser 2 text'); 
