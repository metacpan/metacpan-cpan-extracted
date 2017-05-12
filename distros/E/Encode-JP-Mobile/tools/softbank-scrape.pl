#!/usr/bin/perl
use strict;
use warnings;
use Web::Scraper;
use URI;
use YAML;

my $number = 1;

my $emoji = scraper {
  process '//table[@width="100%" and @cellpadding="2"]//tr/td/font/../..',
      'emoji[]' => scraper {
          # 264-266 are Skymail and 267-270 are J-PHONE chars, removed from their website
          $number += 4 if $number == 267;
          process '//td[2]/font', unicode => 'TEXT';
          process '//td[3]/font', sjis => [ 'TEXT', sub { unpack "H*", shift } ];
          process '//td[1]/img',  image => [ '@src', sub { $_->as_string } ];
          process '//td[1]', number => [ 'TEXT', sub { $number++ } ]; # /td[1] etc. is dummy
      };
  result 'emoji';
};

my @urls = map "http://developers.softbankmobile.co.jp/dp/tool_dl/web/picword_0$_.php", 1..6;

my $res;
foreach my $url (@urls) { push @$res, @{$emoji->scrape(URI->new($url))} };
fill_sjisauto($res);
binmode STDOUT, ":utf8";
print Dump $res;

sub fill_sjisauto {
    my $res = shift;
    my $uni2sjisauto = YAML::LoadFile('dat/softbank-unicode2sjis_auto.yaml');
    for my $row (@$res) { 
        $row->{sjis_auto} = $uni2sjisauto->{$row->{unicode}};
    }
}
