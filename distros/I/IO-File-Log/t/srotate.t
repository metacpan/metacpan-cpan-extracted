#!/usr/bin/perl -w

use Test::More tests => 4;

use IO::File;
use IO::File::Log;

my $file = 'srotate.tst';
my $dest = 'srot2.tst';

sub _terminate {
    fail("Hung after replacing test file");
    exit 1;
}

sub _alarm {
    rename $file, $dest;

    my $fh = new IO::File ">$file";
    $fh->autoflush(1);
    print $fh "after alarm\n";
    $fh->close;

    $SIG{ALRM} = \&_terminate;
    alarm(10);
}

$SIG{ALRM} = \&_alarm;

				# Insure that the file exists
				# prior to opening the log
my $fh = new IO::File ">$file";
$fh->autoflush(1);
print $fh "before alarm\n";
$fh->close;

END {
    unlink $file, $dest;
}

				# Open the log in a quiescent
				# scenario
my $log = new IO::File::Log "$file";
ok(defined $log, 'new()');
is(ref $log, 'IO::File::Log', 'Correct type');

is($log->getline, "before alarm\n", 'Before slow rotation');

alarm 10;

is($log->getline, "after alarm\n", 'After an alarm');
