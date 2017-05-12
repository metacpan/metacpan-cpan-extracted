#!perl

use strict;
use warnings;
use Directory::Queue;
use Directory::Queue::Normal;
use Directory::Queue::Set;
use Directory::Queue::Simple;
use Test::More tests => 11;
use File::Temp qw(tempdir);

our($tmpdir, $dq1, $dq2, $elt1, $elt2, $dqs, $dq, $elt, @list);

$tmpdir = tempdir(CLEANUP => 1);
#diag("Using temporary directory $tmpdir");

$dq1 = Directory::Queue::Normal->new(path => "$tmpdir/1", "schema" => { string => "string" });
$dq2 = Directory::Queue::Simple->new(path => "$tmpdir/2");
isnt($dq1->path(), $dq2->path(), "path");
isnt($dq1->id(), $dq2->id(), "id");
is($dq1->id(), $dq1->copy()->id(), "copy");

$elt1 = $dq1->add(string => "test dq1.1");
$elt2 = $dq2->add("test dq2.1");
$dq1->add(string => "test dq1.2");
$dq2->add("test dq2.2");

$dqs = Directory::Queue::Set->new();
is($dqs->count(), 0, "empty");

$dqs = Directory::Queue::Set->new($dq1, $dq2);
$dqs->remove($dq1);
is($dqs->count(), 2, "half");
$dqs->add($dq1);
is($dqs->count(), 4, "count");

for (($dq, $elt) = $dqs->first(); $dq; ($dq, $elt) = $dqs->next()) {
    push(@list, $elt);
}
is(scalar(@list), 4, "iter");

@list = grep($_ eq $elt1 || $_ eq $elt2, @list);
if (substr($elt1, -14) lt substr($elt2, -14)) {
    like(" @list ", qr/ $elt1 $elt2 /, "order");
} else {
    like(" @list ", qr/ $elt2 $elt1 /, "order");
}

($dq, $elt) = $dqs->first();
$dq->lock($elt) and $dq->remove($elt);

($dq, $elt) = $dqs->next();
$dq->lock($elt) and $dq->remove($elt);

($dq, $elt) = $dqs->next();
$dq->lock($elt) and $dq->remove($elt);

($dq, $elt) = $dqs->next();
# last one

if ($dq1->id() eq $dq->id()) {
    is($dq1->count(), 1, "count 1");
    is($dq2->count(), 0, "count 2");
} elsif ($dq2->id() eq $dq->id()) {
    is($dq1->count(), 0, "count 1");
    is($dq2->count(), 1, "count 2");
} else {
    # error
    is($dq1->count(), "?", "count 1");
    is($dq2->count(), "?", "count 2");
}

($dq, $elt) = $dqs->next();
ok(!defined($dq), "end");
