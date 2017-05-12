#!/usr/bin/env perl
use common::sense;
use open qw(:locale);

use Coro;
#use Coro::LWP;
{
    package LWP::Protocol::Net::Curl;
    use Coro::Select qw(select);
    use LWP::Protocol::Net::Curl verbose => 0;
    $LWP::Protocol::Net::Curl::use_select = 1;
}
use WWW::Mechanize;

my @pids = map {
    async {
        my $url = shift;

        my $mech = WWW::Mechanize->new;
        $mech->agent_alias(q(Linux Mozilla));
        $mech->get($url);

        printf qq(%-20s\t%s\n), $url, $mech->title;
    } $_
} qw {
    http://google.com
    http://facebook.com
    http://youtube.com
    http://yahoo.com
    http://baidu.com
    http://wikipedia.org
    http://live.com
    http://twitter.com
    http://qq.com
    http://amazon.com
    http://blogspot.com
    http://linkedin.com
    http://google.co.in
    http://taobao.com
    http://yahoo.co.jp
    http://sina.com.cn
    http://msn.com
    http://wordpress.com
    http://google.de
    http://google.com.hk
};

$_->join for @pids;
