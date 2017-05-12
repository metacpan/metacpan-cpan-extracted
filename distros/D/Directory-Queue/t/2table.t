#!perl

use strict;
use warnings;
use Directory::Queue::Normal;
use Test::More tests => 128;
use File::Temp qw(tempdir);

use constant STR_ASCII   =>  join("", grep(/^[[:print:]]$/, map(chr($_ ^ 123), 0 .. 255)));
use constant STR_ISO     => "Théâtre Français";
use constant STR_UNICODE => "is \x{263A}?";

sub check_hash ($$$) {
    my($hash1, $hash2, $text) = @_;
    my($tmp1, $tmp2);

    $tmp1 = join("+", sort(keys(%$hash1)));
    $tmp2 = join("+", sort(keys(%$hash2)));
    is($tmp1, $tmp2, "$text (keys)");
    $tmp1 = join("+", map($hash1->{$_}, sort(keys(%$hash1))));
    $tmp2 = join("+", map($hash2->{$_}, sort(keys(%$hash2))));
    is($tmp1, $tmp2, "$text (values)");
}

sub check_elt ($$$$) {
    my($data, $dq, $elt, $text) = @_;
    my(@list, $scalar);

    $dq->lock($elt) or die;
    # list
    @list = $dq->get($elt);
    is(scalar(@list), 2, "$text - get() 1");
    is($list[0], "table", "$text - get() 2");
    check_hash($list[1], $data, "$text - get()");
    # scalar
    $scalar = $dq->get($elt);
    is(ref($scalar), "HASH", "$text - get{} 1");
    @list = keys(%$scalar);
    is("@list", "table", "$text - get{} 2");
    check_hash($data, $scalar->{table}, "$text - get{}");
}

sub check_data ($$$) {
    my($data, $dq, $text) = @_;
    my($elt);

    $elt = $dq->add(table => $data);
    check_elt($data, $dq, $elt, "$text - add()");
    $elt = $dq->add({ table => $data });
    check_elt($data, $dq, $elt, "$text - add{}");
}

our($tmpdir, $dq);

$tmpdir = tempdir(CLEANUP => 1);
$dq = Directory::Queue::Normal->new(path => $tmpdir, schema => { table => "table" });
check_data({}, $dq, "empty");
check_data({"" => "", "abc" => "", " " => "def"}, $dq, "zero");
check_data({foo => 1, bar => 2}, $dq, "normal");
check_data({STR_ASCII => STR_ASCII}, $dq, "ascii");
check_data({STR_ISO => STR_ISO}, $dq, "iso");
check_data({STR_UNICODE => STR_UNICODE}, $dq, "unicode");
check_data({STR_ISO => STR_UNICODE, STR_UNICODE => STR_ASCII, STR_ASCII => STR_ISO}, $dq, "all");
check_data({"\n" => "\t", "\t" => "\\", "\\" => "\n"}, $dq, "weird");
