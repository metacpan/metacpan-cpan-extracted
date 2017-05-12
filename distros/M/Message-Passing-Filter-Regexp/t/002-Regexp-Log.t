#!/usr/bin/perl
use lib 'lib';
use Data::Dumper;
use Test::More;
BEGIN{ use_ok( 'Message::Passing::Filter::Regexp::Log' ); }

my $line = '127.0.0.1 - - [19/Jan/2005:21:42:43 +0000] "POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1" 200 11435';

my $filter = Message::Passing::Filter::Regexp::Log->new(
    regexfile => 't/regexfile',
    format => ':common',
    capture => [ qw( ts req ) ],
);
isa_ok( $filter, Message::Passing::Filter::Regexp::Log );

my @fields = $filter->capture;
is_deeply( \@fields, [qw(ts req)], "capture fields test");

my $re = $filter->regexp;
is( $re, '(?^:^(?:\S+) (?:.*?) (?:.*?) (?:\[(\d{2}\\/\w{3}\\/\d{4}(?::\d{2}){3} [-+]\d{4})\]) (?:\"(.*?)\") (?:\d+) (?:-|\d+)$)', "compiled regex test");

my %data;
@data{@fields} = $line =~ /$re/;
is_deeply( \%data, {
    req => 'POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1',
    ts  => '19/Jan/2005:21:42:43 +0000',
}, "regexp data match test");

done_testing();
