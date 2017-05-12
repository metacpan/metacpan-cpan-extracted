#!/usr/bin/env perl
#
# Test case for what happens when lockfile cannot be opened
#

use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;
use Test::Warn;
use Fcntl qw(LOCK_EX LOCK_UN);

if ($> == 0) {
    plan skip_all => 'root user is exempt from file RW permissions restrictions';
}

use_ok 'Log::Dispatch';
use_ok 'Log::Dispatch::FileRotate';

my $tempdir = Path::Tiny->tempdir;

my $dispatcher = Log::Dispatch->new;
isa_ok $dispatcher, 'Log::Dispatch';

my $file_logger = Log::Dispatch::FileRotate->new(
    filename    => $tempdir->child('myerrs.log')->stringify,
    min_level   => 'debug',
    mode        => 'append',
    max         => 5,
    newline     => 0,
    DatePattern => 'YYYY-dd-HH');

isa_ok $file_logger, 'Log::Dispatch::FileRotate';

$dispatcher->add($file_logger);

$dispatcher->info('write with successful lock');

my $lockfile = $file_logger->{lf};

# make the lockfile unwriteable
chmod 0, $lockfile;

warning_like {
    $dispatcher->info('Write with unsuccessful lock');
} qr/\d+ Log::Dispatch::FileRotate failed to get lock/;

open my $fh, '<', $tempdir->child('myerrs.log')->stringify or die "can't open logfile: $!";
my $content = do { local $/ = undef; <$fh> };
is $content, 'write with successful lock';

chmod 0644, $lockfile;

done_testing;
