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

use Log::Dispatch;
use Log::Dispatch::FileRotate;

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

# mock out lock() so it returns failure
no warnings qw(redefine once);
*Log::Dispatch::FileRotate::Mutex::lock = sub { return 0 };

warning_like {
    $dispatcher->info('Write with unsuccessful lock');
} [qr/\d+ Log::Dispatch::FileRotate failed to get lock/,
   qr/\d+ Log::Dispatch::FileRotate not logging/];

open my $fh, '<', $tempdir->child('myerrs.log')->stringify or die "can't open logfile: $!";
my $content = do { local $/ = undef; <$fh> };
is $content, 'write with successful lock';

done_testing;
