use strict;
use warnings;

use Test::More 0.88;
use Path::Tiny;
use Log::Dispatch;
use Log::Dispatch::File::Stamped;

my $dispatcher = Log::Dispatch->new;
ok($dispatcher, 'we have a generic logger');

my $tempdir = Path::Tiny->tempdir;
my ($hour,$mday,$mon,$year) = (localtime)[2..5];
my $file = $tempdir->child(sprintf("logfile-%04d%02d%02d.txt", $year+1900, $mon+1, $mday));

my %params = (
    name        => 'file',
    min_level   => 'debug',
    permissions => 0600,
    filename  => $tempdir->child('logfile.txt')->stringify,
);
my $stamped = Log::Dispatch::File::Stamped->new(%params);
ok($stamped, 'we have a timestamped logger');

$dispatcher->add($stamped);
$dispatcher->log( level => 'info', message => 'foo' );
ok(-e $file, 'the log file exists');

SKIP: {
    skip("different file permission semantics on $^O", 1)
        if $^O eq 'amigaos' || $^O eq 'os2' || $^O eq 'NetWare'
            || $^O eq 'MSWin32' || $^O eq 'dos'
            || $^O eq 'cygwin' || $^O eq 'MacOS';

    is((stat($file))[2] & 07777, 0600, 'permissions are correct');
}

done_testing;
