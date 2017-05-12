#!perl

use strict;
use warnings;
use Directory::Queue;
use Test::More tests => 8;
use File::Temp qw(tempdir);

sub test ($$) {
    my($dq, $type) = @_;

    ok($dq->isa("Directory::Queue"), "inheritance ($type)");
    is(ref($dq), "Directory::Queue::$type", "ref ($type)");
}

our($tmpdir, $dq);

$tmpdir = tempdir(CLEANUP => 1);

$dq = Directory::Queue->new(path => $tmpdir);
test($dq, "Simple");

$dq = Directory::Queue->new(type => "Simple", path => $tmpdir);
test($dq, "Simple");

$dq = Directory::Queue->new(type => "Normal", path => $tmpdir, schema => { string => "string" });
test($dq, "Normal");

$dq = Directory::Queue->new(type => "Null");
test($dq, "Null");
