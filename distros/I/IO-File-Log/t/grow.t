#!/usr/bin/perl -w

use Test::More tests => 23;

use IO::File;
use IO::File::Log;

my $file = 'grow.tst';

my $fh = new IO::File ">$file";

END { 
    $fh->close;
    unlink $file;
}

die "# Failed to create test file" unless $fh;

$fh->autoflush(1);

my $log = new IO::File::Log "$file";

ok(defined $log, 'new()');
is(ref $log, 'IO::File::Log', 'Correct type');

for my $c (1 .. 10) {
    $fh->print($c . "\n");
    is ($log->getline, $c . "\n", "Read of $c");
}

is($log->seek(0, 0), 1, "Seek to begining of log");

for my $c (1 .. 10) {
    is ($log->getline, $c . "\n", "2nd Read of $c");
}

$log->close;


