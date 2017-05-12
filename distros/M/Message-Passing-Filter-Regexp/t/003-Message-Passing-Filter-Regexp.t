# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Message-Passing-Filter-Regexp.t'
use lib 'lib';
use strict;
use warnings;
use Data::Dumper;
use JSON;
use Test::More;
use Message::Passing::Output::Test;
BEGIN { use_ok('Message::Passing::Filter::Regexp') }

my $input = {
    '@tags' => [],
    '@message' =>
'127.0.0.1 - - [19/Jan/2012:21:08:54 +0800] "POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1" 200 11435',
    '@timestamp' => '2012-06-19T21:08:54+0800',
    '@fields'    => {},
};

my $exp = {
    '@tags' => [],
    '@message' =>
'127.0.0.1 - - [19/Jan/2012:21:08:54 +0800] "POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1" 200 11435',
    '@timestamp' => '2012-06-19T21:08:54+0800',
    '@fields'    => {
        req   => 'POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1',
        ts    => '19/Jan/2012:21:08:54 +0800',
        bytes => '11435',
    },
};

my $json_exp = {
    '@tags' => [],
    '@message' =>
'127.0.0.1 - - [19/Jan/2012:21:08:54 +0800] "POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1" 200 11435',
    '@timestamp' => '2012-06-19T21:08:54+0800',
    '@fields'    => {
        req   => 'POST /cgi-bin/brum.pl?act=evnt-edit&eventid=24 HTTP/1.1',
        ts    => '19/Jan/2012:21:08:54 +0800',
        bytes => 11435,
    },
};

my $out = Message::Passing::Output::Test->new;
my $in  = Message::Passing::Filter::Regexp->new(
    output_to => $out,
    regexfile => 't/regexfile',
    format    => ':common',
    capture   => [qw( ts req bytes )],
    mutate    => { bytes => 'number' },
);

$in->consume($input);
my ($output) = $out->messages;
is_deeply( $output, $exp, "capture result test" );
is(
    to_json( [ $output->{'@fields'}->{bytes} ] ),
    to_json( [ $json_exp->{'@fields'}->{bytes} ] ),
    "number test"
);

done_testing;
