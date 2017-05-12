#!/usr/bin/perl -w

use Test::More tests => 22;

use IO::File;
use IO::File::Log;

my $file = 'sgrow.tst';

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
    $fh->print($c . "\n");
    $fh->print($c . "\n");

    my @lines = $log->getlines;
    is(scalar @lines, 3, "Number of lines for $c");
    is_deeply(\@lines, [ "$c\n", "$c\n", "$c\n" ], "Data read for $c");

}

$log->close;


