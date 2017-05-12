#!/usr/bin/perl -w

use Test::More tests => 22;

use IO::File;
use IO::File::Log;

my $file = 'rotate.tst';
my $dest = 'rot2.tst';

				# Insure that the file exists
				# prior to opening the log
my $fh = new IO::File ">$file";
$fh->autoflush(1);
$fh->close;

END {
    unlink $file, $dest;
}

				# Open the log in a quiescent
				# scenario
my $log = new IO::File::Log "$file";

ok(defined $log, 'new()');
is(ref $log, 'IO::File::Log', 'Correct type');

for my $c (1 .. 10) {
    my $fh = new IO::File ">$file";
    $fh->autoflush(1);
    $fh->print($c . "\n");
    $fh->print($c . "\n");
    is ($log->getline, $c . "\n", "Read of $c");
    rename($file, $dest);
    is ($log->getline, $c . "\n", "Read of $c");
    $fh->close;
}

$log->close;
unlink $file, $dest;
