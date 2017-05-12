#!perl

use strict;
use warnings;
use Digest::MD5 qw(md5_hex);
use Encode qw();
use File::Temp qw(tempdir);
use Messaging::Message;
use Messaging::Message::Queue;
use POSIX qw(:fcntl_h);
use Test::More;

our(%Available, $tmpdir, $mqn, $mqs, $tpm);

eval("use Compress::LZ4 0.12 qw()");
$Available{"Compress::LZ4"}++ unless $@;
eval("use Compress::Snappy 0.17 qw()");
$Available{"Compress::Snappy"}++ unless $@;
eval("use Compress::Zlib 2.007 qw()");
$Available{"Compress::Zlib"}++ unless $@;
eval("use Directory::Queue::Normal 1.5 qw()");
$Available{"Directory::Queue::Normal"}++ unless $@;
eval("use Directory::Queue::Normal 1.5 qw()");
$Available{"Directory::Queue::Simple"}++ unless $@;

$tmpdir = tempdir(CLEANUP => 1);
$mqn = Messaging::Message::Queue->new(type => "DQN",  path => "$tmpdir/DQN")
    if $Available{"Directory::Queue::Normal"};
$mqs = Messaging::Message::Queue->new(type => "DQS",  path => "$tmpdir/DQS")
    if $Available{"Directory::Queue::Simple"};
$tpm = 1;
$tpm++ if $mqn;
$tpm++ if $mqs;

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

sub md5_msg ($) {
    my($msg) = @_;
    my($buf, $tmp, $name, $line);

    # text flag
    $buf = $msg->text() ? "1" : "0";
    # header
    $tmp = "";
    foreach $name (sort(keys(%{ $msg->header() }))) {
	$line = $name . ":" . $msg->header_field($name) . "\n";
	$tmp .= Encode::encode("UTF-8", $line, Encode::FB_CROAK|Encode::LEAVE_SRC);
    }
    $buf .= md5_hex($tmp);
    # body
    if ($msg->text()) {
	$tmp = Encode::encode("UTF-8", $msg->body(), Encode::FB_CROAK|Encode::LEAVE_SRC);
    } else {
	$tmp = $msg->body();
    }
    $buf .= md5_hex($tmp);
    # digest
    return(md5_hex($buf));
}

sub test_queue ($$$$) {
    my($mq, $msg, $md5, $path) = @_;
    my($elt);

    $elt = $mq->add_message($msg);
    $mq->lock($elt);
    $msg = $mq->get_message($elt);
    $mq->unlock($elt);
    is(md5_msg($msg), $md5, $path);
}

sub test_one ($) {
    my($path) = @_;
    my($md5, $tmp, $msg);

    die("unexpected path: $path\n")
	unless $path =~ /^(?:.+\/)?([0-9a-f]{32})(\.\d+)?$/;
    $md5 = $1;
    $tmp = contents($path);
    SKIP : {
	skip("recent enough Compress::LZ4 not installed", $tpm)
	    if $tmp =~ /\"encoding\"\s*:\s*\"[a-z0-9\+]*lz4\b/ and
	    not $Available{"Compress::LZ4"};
	skip("recent enough Compress::Snappy not installed", $tpm)
	    if $tmp =~ /\"encoding\"\s*:\s*\"[a-z0-9\+]*snappy\b/ and
	    not $Available{"Compress::Snappy"};
	skip("recent enough Compress::Zlib not installed", $tpm)
	    if $tmp =~ /\"encoding\"\s*:\s*\"[a-z0-9\+]*zlib\b/ and
	    not $Available{"Compress::Zlib"};
	eval { $msg = Messaging::Message->deserialize_ref(\$tmp) };
	if ($msg) {
	    is(md5_msg($msg), $md5, $path);
	    test_queue($mqn, $msg, $md5, $path) if $mqn;
	    test_queue($mqs, $msg, $md5, $path) if $mqs;
	} else {
	    $@ =~ s/\s*$//;
	    is($@, "", $path);
	}
    }
}

sub test_all (@) {
    plan tests => scalar(@_) * $tpm;
    foreach my $path (@_) {
	test_one($path);
    }
}

if (@ARGV) {
    test_all(@ARGV);
} else {
    test_all(glob("$0.d/*"));
}
