#!perl

use strict;
use warnings;

use Test::More;
BEGIN {
  plan skip_all=>'$ENV{ONLINETESTS} not set'
    unless $ENV{ONLINETESTS};
  #plan 'no_plan';
  plan tests=>25;
}
use HTTP::LoadGen::Run;
use Data::Dumper; $Data::Dumper::Useqq=1;

use Coro;

print STDERR <<'EOF';


These tests may fail due to the structure of the internet. Hosts may
become unaccessible or may update to newer software versions.

That said ...

EOF

# http://science.ksc.nasa.gov/
#   apache with http/1.1 but connection: close (no keep-alive)
#
# http://217.86.174.228:8080/axis-cgi/jpg/image.cgi
#   axis webcam: http/1.0
#
# http://foertsch.name/
#   apache http/1.1 with keep-alive

my $rc;

HTTP::LoadGen::Run::dnscache=\my %dns_cache;
my $conncache=HTTP::LoadGen::Run::conncache;

SKIP: {

  skip 'set $ENV{ONLINETESTS}>1 to run tests to domains other than my own', 8
    unless $ENV{ONLINETESTS}>1;

  #########################################################################

  ($rc)=HTTP::LoadGen::Run::run_url
    qw!GET http science.ksc.nasa.gov 80 /!, {keepalive=>KEEPALIVE};

  #warn Dumper $rc->[RC_HEADERS];

  ok exists($dns_cache{'science.ksc.nasa.gov'}),
    'science.ksc.nasa.gov resolved to '.$dns_cache{'science.ksc.nasa.gov'};

  is $rc->[RC_CONNCACHED], 0, 'no kept-alive connection available';
  is_deeply [%$conncache], [], 'conncache still empty';
  is length($rc->[RC_BODY]), $rc->[RC_HEADERS]->{'content-length'}->[0],
    'Body length: '.$rc->[RC_HEADERS]->{'content-length'}->[0];

  #########################################################################

  ($rc)=HTTP::LoadGen::Run::run_url
    qw!GET http 217.86.174.228 8080 /axis-cgi/jpg/image.cgi!, {keepalive=>KEEPALIVE};

  #warn Dumper $rc->[RC_HEADERS];

  ok exists($dns_cache{'217.86.174.228'}),
    '217.86.174.228 resolved to '.$dns_cache{'217.86.174.228'};

  is $rc->[RC_CONNCACHED], 0, 'no kept-alive connection available';
  is_deeply [%$conncache], [], 'conncache still empty';
  is length($rc->[RC_BODY]), $rc->[RC_HEADERS]->{'content-length'}->[0],
    'Body length: '.$rc->[RC_HEADERS]->{'content-length'}->[0];

  #########################################################################
}

($rc)=HTTP::LoadGen::Run::run_url
  qw!GET http foertsch.name 80 /!, {keepalive=>KEEPALIVE};

#warn Dumper $rc->[RC_HEADERS];

ok exists($dns_cache{'foertsch.name'}),
  'foertsch.name resolved to '.$dns_cache{'foertsch.name'};

is $rc->[RC_CONNCACHED], 0, 'no kept-alive connection available';
is 0+keys %$conncache, 1, 'conncache with 1 element';
is length($rc->[RC_BODY]), $rc->[RC_HEADERS]->{'content-length'}->[0],
  'Body length: '.$rc->[RC_HEADERS]->{'content-length'}->[0];

($rc)=HTTP::LoadGen::Run::run_url
  qw!GET http foertsch.name 80 /!, {keepalive=>KEEPALIVE_USE};

is $rc->[RC_CONNCACHED], 1, 'conncache used';
is 0+@{$conncache->{$dns_cache{'foertsch.name'}.' 80'}}, 0,
  'conncache empty again';

($rc)=HTTP::LoadGen::Run::run_url
  qw!GET http foertsch.name 80 /!, {keepalive=>KEEPALIVE_STORE};
($rc)=HTTP::LoadGen::Run::run_url
  qw!GET http foertsch.name 80 /!, {keepalive=>KEEPALIVE_STORE};

is 0+@{$conncache->{$dns_cache{'foertsch.name'}.' 80'}}, 2,
  '2 connections cached for '.$dns_cache{'foertsch.name'}.':80';

($rc)=HTTP::LoadGen::Run::run_url
  qw!GET https www.kabatinte.net 443 /!, {keepalive=>KEEPALIVE_STORE};

is $rc->[RC_STATUS], 303, 'https://www.kabatinte.net/ => 303';
ok length($rc->[RC_STATUSLINE])>0, 'STATUS_LINE';
ok length($rc->[RC_HTTPVERSION])>0, 'HTTPVERSION';
ok $rc->[RC_STARTTIME]>0, 'STARTTIME';
ok $rc->[RC_CONNTIME]>0, 'CONNTIME';
ok $rc->[RC_FIRSTTIME]>0, 'FIRSTTIME';
ok $rc->[RC_HEADERTIME]>0, 'HEADERTIME';
ok $rc->[RC_BODYTIME]>0, 'BODYTIME';
is $rc->[RC_DNSCACHED], 0, 'DNS cache miss';

($rc)=HTTP::LoadGen::Run::run_url qw!GET http www.kabatinte.net 80 /!;

is $rc->[RC_DNSCACHED], 1, 'DNS cache hit';
