use strict;
use warnings;
use Test::Base;
use HTTP::DetectUserAgent;
use YAML 0.83;

plan tests =>  (3 * blocks);

filters {
    input    => [qw(chomp)],
    expected => [qw(yaml)],
};

run {
    my $block = shift;
    my $ua = HTTP::DetectUserAgent->new($block->input);
    my $expected = $block->expected;
    is $ua->type, "Crawler";
    is $ua->name, $expected->{name};
    is $ua->vendor, $expected->{vendor};
}

__END__

=== googlebot
--- input
Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)
--- expected
name: "Googlebot"
vendor: "Google"

=== googlebot mobile 1
--- input
DoCoMo/1.0/N505i/c20/TB/W20H10 (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html)
--- expected
name: "Googlebot Mobile"
vendor: "Google"

=== googlebot mobile 2
--- input
DoCoMo/2.0 N905i(c100;TB;W24H16) (compatible; Googlebot-Mobile/2.1; +http://www.google.com/bot.html) 
--- expected
name: "Googlebot Mobile"
vendor: "Google"

=== Yahoo! Slurp
--- input
Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)
--- expected
name: "Yahoo! Slurp"
vendor: "Yahoo"

=== Baiduspider
--- input
Baiduspider+(+http://help.baidu.jp/system/05.html)
--- expected
name: "Baiduspider"
vendor: "Baidu"

=== msnbot
--- input
msnbot/1.1 (+http://search.msn.com/msnbot.htm)
--- expected
name: "msnbot"
vendor: "Microsoft"

=== Twiceler
--- input
Mozilla/5.0 (Twiceler-0.9 http://www.cuill.com/twiceler/robot.html)
--- expected
name: "Twiceler"
vendor: "Cuil"

=== BaiduMobaider 1
--- input
DoCoMo/2.0 P05A(c100;TB;W24H15) (compatible; BaiduMobaider/1.0; +http://www.baidu.jp/spider/)
--- expected
name: "BaiduMobaider"
vendor: "Baidu"

=== BaiduMobaider 2
--- input
DoCoMo/1.0/D506i/c20/TB/W20H10 (compatible; BaiduMobaider/1.0; +http://www.baidu.jp/spider/)
--- expected
name: "BaiduMobaider"
vendor: "Baidu"

=== BaiduMobaider 3
--- input
KDDI-CA3A UP.Browser/6.2.0.13.2 (GUI) MMP/2.0 (compatible; BaiduMobaider/1.0;+http://www.baidu.jp/spider/)
--- expected
name: "BaiduMobaider"
vendor: "Baidu"

=== BaiduMobaider 4
--- input
SoftBank/1.0/912SH/SHJ002/SN001111111111000 Browser/NetFront/3.4 Profile/MIDP-2.0 (compatible; BaiduMobaider/1.0;+http://www.baidu.jp/spider/)
--- expected
name: "BaiduMobaider"
vendor: "Baidu"

=== Tagoobot
--- input
Mozilla/5.0 (compatible; Tagoobot/3.0; +http://www.tagoo.ru)
--- expected
name: "Tagoobot"
vendor: "Tagoo"

=== Sogou web spider
--- input
Sogou web spider/4.0(+http://www.sogou.com/docs/help/webmasters.htm#07)
--- expected
name: "Sogou"
vendor: "Sogou"

=== Daumoa
--- input
Mozilla/5.0 (compatible; MSIE or Firefox mutant; not on Windows server; +http://ws.daum.net/aboutWebSearch.html) Daumoa/2.0
--- expected
name: "Daumoa"
vendor: "Daum"

=== YahooFeedSeeker
--- input
YahooFeedSeeker/1.0 (compatible; Mozilla 4.0; MSIE 5.5; http://my.yahoo.com/s/publishers.html)
--- expected
name: "YahooFeedSeeker"
vendor: "Yahoo"
