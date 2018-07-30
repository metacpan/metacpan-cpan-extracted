#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Path::Tiny;
use Log::Dispatch::FileRotate;

for my $mode (0666, 0644, 0600) {
    my $tempdir = Path::Tiny->tempdir;

    my $dispatcher = Log::Dispatch->new;
    isa_ok $dispatcher, 'Log::Dispatch';

    my $file_logger = Log::Dispatch::FileRotate->new(
        filename    => $tempdir->child('myerrs.log')->stringify,
        permissions => 0666,
        min_level   => 'debug',
        mode        => 'append',
        size        => 20000,
        max         => 5,
        newline     => 1,
        DatePattern => 'YYYY-dd-HH');

    isa_ok $file_logger, 'Log::Dispatch::FileRotate';
    $dispatcher->add($file_logger);

    $dispatcher->log(level => 'info', message => 'Hello world');

    my $permissions = (stat $file_logger->{lf})[2] & 07777;
    cmp_ok $permissions, '==', 0666;
}

done_testing;
