#!/usr/bin/env perl
#
# Test case for deadlock caused by a $SIG{__WARN__} handler that logs warnings
# through Log::Dispatch::FileRotate.
#
# See https://github.com/mschout/perl-log-dispatch-filerotate/issues/11
#

use utf8;
use strict;
use warnings;
use Test::More 0.88;
use Path::Tiny 0.018;
use Encode qw(decode);
use Test::Warn;

if ($] < 5.008000) {
    # we depend on the "Wide character in print" warning, which was added in 5.8
    plan skip_all => 'This test requires Perl 5.8.0 or later';
}

plan tests => 8;

use Log::Dispatch;
use Log::Dispatch::FileRotate;

my $tempdir = Path::Tiny->tempdir;
my $logfile = $tempdir->child('myerrs.log')->stringify;

my $dispatcher = Log::Dispatch->new;
isa_ok $dispatcher, 'Log::Dispatch';

# we need to make sure we do not turn on utf8 mode here so that we can trigger
# the "Wide character in print" warning.
my $file_logger = Log::Dispatch::FileRotate->new(
    filename    => $logfile,
    min_level   => 'debug',
    mode        => 'append',
    max         => 5,
    newline     => 0,
    DatePattern => 'YYYY-dd-HH');

isa_ok $file_logger, 'Log::Dispatch::FileRotate';

$dispatcher->add($file_logger);

# install __WARN__ handler
$SIG{__WARN__} = sub { $dispatcher->warn(@_) };

$SIG{ALRM} = sub { die "timeout\n" };

my $desc = '__WARN__ deadlock';
eval {
    alarm 10;

    # "warning" in chinese, at least according to google translate.
    $dispatcher->info("1: \x{8b66}\x{544a}");

    alarm 0;
};
if ($@) {
    diag $@ =~ /^timeout/
        ? 'deadlock detected'
        : "error: $@";

    fail $desc;
}
else {
    pass $desc;
}

open my $fh, '<', $logfile or die "cannot open $logfile: $!";

# first line in the file should be the warning
my $line = <$fh>;
like $line, qr/Wide character in print/;

# next line should be the UTF-8 string
$line = <$fh>;
chomp $line;
is decode('UTF-8', $line), "1: \x{8b66}\x{544a}";

# test scenario where we have a different dispatcher instance in the __WARN__
# handler, but logging to the same file.
my $warn_dispatcher = Log::Dispatch->new;
isa_ok $warn_dispatcher, 'Log::Dispatch';

# we need to make sure we do not turn on utf8 mode here so that we can trigger
# the "Wide character in print" warning.
my $warn_logger = Log::Dispatch::FileRotate->new(
    filename    => $logfile,
    min_level   => 'debug',
    mode        => 'append',
    max         => 5,
    newline     => 0,
    DatePattern => 'YYYY-dd-HH');

isa_ok $warn_logger, 'Log::Dispatch::FileRotate';

$warn_dispatcher->add($warn_logger);

$SIG{__WARN__} = sub { $warn_dispatcher->warn(@_) };

eval {
    alarm 10;

    $dispatcher->info("2: \x{8b66}\x{544a}");

    alarm 0;
};
if ($@) {
    diag $@ =~ /^timeout/
        ? 'deadlock detected'
        : "error: $@";

    fail $desc;
}
else {
    pass $desc;
}
