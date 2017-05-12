#!/usr/bin/env perl
use 5.010;
use strict;
use warnings;

use Data::Printer;
use Digest::MD5 qw(md5_hex);
use HTML::Entities;
use LWP::UserAgent::Determined;

use lib 'lib';
use Decaptcha::TextCaptcha;

my $key = shift or die 'missing api key';

my $ua = LWP::UserAgent::Determined->new(
    agent   => 'Mozilla 5.0',
    timeout => 15,
);
$ua->codes_to_determinate()->{404} = 1;
$ua->timing('2,5,10');

my $url = "http://api.textcaptcha.com/$key";
while (1) {
    my $res = $ua->get($url);
    next unless $res->is_success;
    my $content = $res->decoded_content;

    my ($q) = $content =~ m[<question>(.*?)</question>];
    decode_entities($q);
    my $a = decaptcha($q) // '';
    my $md5 = md5_hex $a;

    my @a = $content =~ m[<answer>(.*?)</answer>]g;
    my $ok = grep { $md5 eq $_ } @a;

    say $q, ' : ', $a, ' : ', $ok ? 'ok' : 'NOK';
    do { say "  $_" for @a } unless $ok;
}
continue { sleep 1 + int rand 3 }
