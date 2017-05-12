#!perl -T

use strict;
use warnings;
use Test::Simple tests => 8;

use lib '../lib';
use Log::Rolling;

my $testfile = './testrollingdebug.txt';
my $log = Log::Rolling->new();
ok((not $log), 'new() returns undef if no file provided.');

$log = undef;

$log = Log::Rolling->new($testfile);
ok(($log and ref($log)), 'new() returns an object when given a filename.');

ok(($log->max_size(7) == 7), 'max_size() set value correctly.');

ok(($log->entry('one','two','three','four','five')), 'entry() accepted log entries.');

ok(($log->commit), 'commit() wrote entries to file.');

ok((not $log->roll), 'roll() successfully avoided being called directly.');

ok(($log->pid(1)), 'pid() successfully turned on.');

$log->entry('one','two','three','four','five');
$log->commit;
open(FILE,"<$testfile");
my @sizearr = <FILE>;
close(FILE);
unlink($testfile);
ok((scalar(@sizearr) == 7), 'log file limited properly during rolling.');

exit;
