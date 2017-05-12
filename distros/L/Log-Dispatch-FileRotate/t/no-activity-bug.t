#!/usr/bin/env perl

use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;

plan tests => 7;

use_ok 'Log::Dispatch';
use_ok 'Log::Dispatch::FileRotate';

my $tempdir = Path::Tiny->tempdir;

my $dispatcher = Log::Dispatch->new;
isa_ok $dispatcher, 'Log::Dispatch';

my $count = 0;

my $logger = Log::Dispatch::FileRotate->new(
    filename    => $tempdir->child('test.log')->stringify,
    mode        => 'append',
    max         => 6,
    min_level   => 'info',
    DatePattern => 'yyyy-MM-dd-HH');

isa_ok $logger, 'Log::Dispatch::FileRotate';

$logger->{timer} = sub {
    time + $count * 3600;
};

$dispatcher->add($logger);

# $logger->{debug} = 1;

$dispatcher->log(level => 'info', message => "count=$count");
$count += 10;
for (1..3) {
    $dispatcher->log(level => 'info', message => "count=$count");
}

ok -f $tempdir->child('test.log')->stringify;

ok -f $tempdir->child('test.log.1')->stringify;

# This shouldn't exist
ok ! -f $tempdir->child('test.log.2')->stringify;

