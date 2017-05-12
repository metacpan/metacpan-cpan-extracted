#!perl

use strict;
use warnings;
use Encode;
use Directory::Queue::Normal qw();
use File::Temp qw(tempdir);
use No::Worries::Dir qw(dir_read);
use POSIX qw(:errno_h :fcntl_h);
use Test::More tests => 45;

use constant STR_ISO     => "Théâtre Français";
use constant STR_UNICODE => "is \x{263A}?";

our($tmpdir, $dq, $elt, @list, $time, $tmp);

sub contents ($) {
    my($path) = @_;
    my($fh, $contents, $done);

    sysopen($fh, $path, O_RDONLY) or die("cannot sysopen($path): $!\n");
    binmode($fh) or die("cannot binmode($path): $!\n");
    $contents = "";
    $done = -1;
    while ($done) {
	$done = sysread($fh, $contents, 8192, length($contents));
	die("cannot sysread($path): $!\n") unless defined($done);
    }
    close($fh) or die("cannot close($path): $!\n");
    return($contents);
}

$tmpdir = tempdir(CLEANUP => 1);
#diag("Using temporary directory $tmpdir");

@list = dir_read($tmpdir);
is(scalar(@list), 0, "empty directory");

$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { string => "string" });
@list = sort(dir_read($tmpdir));
is("@list", "obsolete temporary", "empty queue");

$elt = $dq->add(string => STR_ISO);
@list = sort(dir_read($tmpdir));
is("@list", "00000000 obsolete temporary", "non-empty queue");
@list = dir_read("$tmpdir/00000000");
is("00000000/@list", $elt, "one element");
is(contents("$tmpdir/$elt/string"), encode("UTF-8", STR_ISO), "ISO-8859-1 string");
is($dq->count(), 1, "count 1");

$elt = $dq->add(string => STR_UNICODE);
is(contents("$tmpdir/$elt/string"), encode("UTF-8", STR_UNICODE), "Unicode string");
is($dq->count(), 2, "count 2");

$elt = $dq->first();
ok($elt, "first");
ok(!$dq->_is_locked($elt), "lock testing 1");
ok($dq->lock($elt), "lock");
ok( $dq->_is_locked($elt), "lock testing 2");
ok($dq->unlock($elt), "unlock");
ok(!$dq->_is_locked($elt), "lock testing 3");

$elt = $dq->next();
ok($elt, "next");
ok($dq->lock($elt), "lock");
eval { $dq->remove($elt) };
is($@, "", "remove 1");
is($dq->count(), 1, "count 1");

$elt = $dq->first();
ok($elt, "first");
eval { $dq->remove($elt) };
like($@, qr/not locked/, "remove 2");
ok($dq->lock($elt), "lock");
eval { $dq->remove($elt) };
is($@, "", "remove 3");
is($dq->count(), 0, "count 0");

$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { string => "binary" });
$elt = $dq->add(string => STR_ISO);
is(contents("$tmpdir/$elt/string"), STR_ISO, "ISO-8859-1 binary");

$tmp = "foobar";
$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { string => "binary*" });
eval { $elt = $dq->add(string => $tmp) };
like($@, qr/unexpected/, "add by reference 1");
eval { $elt = $dq->add(string => \$tmp) };
is($@, "", "add by reference 2");
is(contents("$tmpdir/$elt/string"), $tmp, "binary by reference");

$tmp = $dq->count();
$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { string => "binary" }, maxelts => $tmp);
@list = sort(dir_read($tmpdir));
is("@list", "00000000 obsolete temporary", "subdirs 1");
$elt = $dq->add(string => $tmp);
@list = sort(dir_read($tmpdir));
is("@list", "00000000 00000001 obsolete temporary", "subdirs 2");

$time = time() - 10;
$elt = $dq->first();
$dq->lock($elt);
$tmp = $dq->path() . "/" . $elt;
utime($time, $time, $tmp) or die("cannot utime($time, $time, $tmp): $!\n");
$elt = $dq->next();
$dq->lock($elt);
$tmp = $dq->path() . "/" . $elt;
utime($time, $time, $tmp) or die("cannot utime($time, $time, $tmp): $!\n");
$elt = $dq->first();
$dq->touch($elt);
$tmp = 0;
{
    local $SIG{__WARN__} = sub { $tmp++ if $_[0] =~ /removing too old locked/ };
    $dq->purge(maxlock => 5);
}
is($tmp, 1, "purge 1");
$elt = $dq->first();
$elt = $dq->next();
ok($dq->lock($elt), "purge 2");
is($dq->count(), 3, "purge 3");

$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { string => "binary", optional => "string?" });
$tmp = "add by hash";
ok($dq->add(string => $tmp), "$tmp 1");
ok($dq->add(string => $tmp, optional => "yes"), "$tmp 2");
$tmp = "add by hash ref";
ok($dq->add({string => $tmp}), "$tmp 1");
ok($dq->add({string => $tmp, optional => "yes"}), "$tmp 2");

$elt = $dq->add(string => "foo", optional => "bar");
eval { @list = $dq->get($elt) };
like($@, qr/not locked/, "get");
ok($dq->lock($elt), "lock");
eval { @list = $dq->get($elt) };
is($@, "", "get by hash 1");
is(scalar(@list), 4, "get by hash 2");
eval { $tmp = $dq->get($elt) };
is($@, "", "get by hash ref 1");
is(ref($tmp), "HASH", "get by hash ref 2");

$dq = Directory::Queue::Normal->new(path => $tmpdir);
$tmp = 0;
for ($elt = $dq->first(); $elt; $elt = $dq->next()) {
    $tmp++;
}
is($dq->count(), $tmp, "iteration");
for ($elt = $dq->first(); $elt; $elt = $dq->next()) {
    $dq->lock($elt); # don't care if failed...
    $dq->remove($elt);
}
is($dq->count(), 0, "emptying");
$dq->purge();
@list = sort(dir_read($tmpdir));
is("@list", "00000001 obsolete temporary", "purged");
