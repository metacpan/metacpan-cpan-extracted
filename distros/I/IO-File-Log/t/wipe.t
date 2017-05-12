#!/usr/bin/perl -w

use Test::More tests => 11;

use IO::File;
use IO::File::Log;

my $file = 'wipe.tst';

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

for my $c (1 .. 5) {
    $fh->print($c . "\n");
}

for my $c (1 .. 3) {
    is ($log->getline, $c . "\n", "Read of $c");
}

$fh->close;
unlink $file;
#warn "# file $file unlinked\n";

for my $c (4 .. 5) {
    is ($log->getline, $c . "\n", "Read of $c");
}

$fh = new IO::File ">$file";
die "# Failed to re-create test file" unless $fh;
#warn "# file $file re-created\n";
$fh->autoflush(1);

for my $c (6 .. 9) {
    $fh->print($c . "\n");
}

for my $c (6 .. 9) {
    is ($log->getline, $c . "\n", "Read of $c");
}

$log->close;


