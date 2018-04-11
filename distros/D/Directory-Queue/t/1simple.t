#!perl

use strict;
use warnings;
use Directory::Queue::Simple qw();
use File::Temp qw(tempdir);
use No::Worries::Dir qw(dir_read);
use Test::More tests => 22;

our($tmpdir, $dq, $elt, @list, $time, $tmp);

$tmpdir = tempdir(CLEANUP => 1);

@list = dir_read($tmpdir);
is(scalar(@list), 0, "empty directory");

$dq = Directory::Queue::Simple->new(path => $tmpdir);
is(scalar(@list), 0, "empty queue");

$elt = $dq->add("hello world");
@list = dir_read($tmpdir);
is(scalar(@list), 1, "queue one element (1)");
like($list[0], qr/^[0-9a-f]{8}$/, "queue one element (2)");
@list = dir_read("$tmpdir/$list[0]");
is(scalar(@list), 1, "queue one element (3)");
like($list[0], qr/^[0-9a-f]{14}$/, "queue one element (4)");
is($dq->count(), 1, "queue one element (5)");

$elt = $dq->first();
ok($dq->lock($elt), "lock");
$tmp = $dq->get($elt);
is($tmp, "hello world", "get");
$tmp = $dq->get_ref($elt);
is(${$tmp}, "hello world", "get_ref");
ok($dq->unlock($elt), "unlock");

foreach (1 .. 12) {
    $elt = $dq->add($_);
}
is($dq->count(), 13, "count (1)");

$elt = $dq->first();
ok($elt, "first");
$elt = $dq->next();
ok($elt, "next");

ok($dq->lock($elt), "lock");
eval { $dq->remove($elt) };
is($@, "", "remove (1)");
is($dq->count(), 12, "count (2)");

$elt = $dq->next();
eval { $dq->remove($elt) };
ok($@, "remove (2)");

for ($elt = $dq->first(); $elt; $elt = $dq->next()) {
    $dq->lock($elt) and $dq->remove($elt);
}
is($dq->count(), 0, "count (3)");

$elt = $dq->add("dummy");
$tmp = "$tmpdir/$elt.tmp";
rename("$tmpdir/$elt", $tmp) or die("cannot rename($tmpdir/$elt, $tmp): $!\n");
is($dq->count(), 0, "count (4)");
$time = time() - 1000;
utime($time, $time, $tmp) or die("cannot utime($time, $time, $tmp): $!\n");
$tmp = 0;
{
    local $SIG{__WARN__} = sub { $tmp++ if $_[0] =~ /removing too old/ };
    $dq->purge(maxtemp => 5);
}
is($tmp, 1, "purge (1)");
$elt =~ s/\/.+//;
@list = dir_read("$tmpdir/$elt");
is(scalar(@list), 0, "purge (2)");
