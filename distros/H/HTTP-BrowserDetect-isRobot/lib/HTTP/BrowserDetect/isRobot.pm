package HTTP::BrowserDetect::isRobot;
{
    $HTTP::BrowserDetect::isRobot::VERSION = '0.06';
}

# ABSTRACT: test if the user-agent is a robot or not

use strict;
use warnings;
use base 'Exporter';
use vars qw/@EXPORT_OK/;

@EXPORT_OK = qw/is_robot is_site_robot is_program_robot/;

sub is_robot {
    my ($agent) = @_;

    return 1 if is_site_robot($agent);
    return 1 if is_program_robot($agent);

    return;
}

sub is_site_robot {
    my ($agent) = @_;

    return 1
      if $agent =~
/Googlebot|Baiduspider|Yahoo! Slurp|Bingbot|MSNbot|altavista|lycos|infoseek|webcrawler|lecodechecker|Ask Jeeves|facebookexternalhit|adsbot-google|ia_archive|FatBot|Xenu Link Sleuth|BlitzBOT|btbot|CatchBot|Charlotte|Discobot|FAST-WebCrawler|FurlBot|Gaisbot|iaskspider|Mediapartners-Google|Seekbot|SEOChat|SeznamBot|Sitebot|sogou spider|Sosospider|TweetedTimes|YahooSeeker|YandexBot|Yeti|YodaoBot|YoudaoBot|ZyBorg|Twitterbot|AhrefsBot|TweetedTimes Bot|TweetmemeBot|bitlybot|ShowyouBot|UnwindFetchor|MetaURI API|PaperLiBot|LinkedInBot|AddThis\.com robot|FriendFeedBot|MnoGoSearch|sistrix|MJ12bot|EZooms|UnisterBot|SiteExplorer|Exabot|Infohelfer|AcoonBot|Pixray-Seeker|emefgebot|Snipebot|Dataprovider Site Explorer|iBusiness Shopcrawler|pmoz\.info|Toplistbot|findlinks|netEstate NE Crawler|Crawler for Netopian|msnbot|webalta|suchen\.de|depspid|gigabot|3GSE bot|IRLbot|cuil\.com|Gigameme\.bot|BotOnParade|Crawly|infometrics-bot|Kaloogabot|Speedy Spider|iCcrawler|WebDataCentreBot|LinkWalker|Tagoobot|searchme\.com|Jyxobot|Purebot|Yanga WorldSearch|MSRBOT|VEDENSBOT|Fastsearch|Twiceler|Linguee Bot|ScoutJet/i;
    return 1 if $agent =~ /^silk/i;

    return;
}

sub is_program_robot {
    my ($agent) = @_;

    return 1
      if $agent =~
      /libwww-perl|PycURL|EventMachine HttpClient|Apache-HttpClient/;
    return 1 if $agent =~ m{Python-(\w+)/}i;
    return 1 if $agent =~ m{^Java/};
    return 1 if $agent eq 'Ruby';

    return;
}

1;

__END__

=pod

=head1 NAME

HTTP::BrowserDetect::isRobot - test if the user-agent is a robot or not

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    use HTTP::BrowserDetect::isRobot 'is_robot';

    if ( is_robot('Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)') ) {
        print "Yes\n";
    }

=head1 DESCRIPTION

extends L<HTTP::BrowserDetect> with more robot detection.

inspired by L<Plack::Middleware::BotDetector>

=head1 METHODS

=head2 is_robot

take User-Agent as the only argument. return 1 if yes.

== is_site_robot || is_program_robot

the regexp is quite incomplete. patches welcome.

=head2 is_site_robot

take User-Agent as the only argument. return 1 if yes.

check if it's from any website like Google or Bing.

    use HTTP::BrowserDetect::isRobot 'is_site_robot';

    if ( is_site_robot('Mozilla/5.0 (compatible; Baiduspider/2.0; +http://www.baidu.com/search/spider.html)') ) {
        print "Yes\n";
    }

=head2 is_program_robot

take User-Agent as the only argument. return 1 if yes.

check if it's from any library of programming languages, like LWP or WWW::Mechanize or others.

    use HTTP::BrowserDetect::isRobot 'is_program_robot';

    if ( is_program_robot('libwww-perl/5.833') ) {
        print "Yes\n";
    }

=head1 AUTHOR

Fayland Lam <fayland@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Fayland Lam.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
