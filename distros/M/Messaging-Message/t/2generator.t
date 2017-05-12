#!perl

use strict;
use warnings;
use Messaging::Message::Generator;
use Test::More tests => 41;

#
# test the empty generator
#

sub test0 () {
    our($mg, $msg, $tmp);

    $mg = Messaging::Message::Generator->new();
    $tmp = 0;
    foreach (1 .. 10) {
	$msg = $mg->message();
	$tmp++ if $msg->serialize() eq "{}";
    }
    is($tmp, 10, "empty generator");
}

#
# test a reasonable generator (the one from the POD)
#

sub test1 () {
    our($mg, $msg, $tmp);

    $mg = Messaging::Message::Generator->new(
	"text" => "0-1",
	"body-length" => "0-1000",
	"body-entropy" => "1-4",
	"header-count" => "2^6",
	"header-name-length" => "10-20",
	"header-name-entropy" => "1-2",
	"header-name-prefix" => "rnd-",
	"header-value-length" => "20-40",
	"header-value-entropy" => "0-3",
    );
    foreach (1 .. 10) {
	$msg = $mg->message();
	$tmp = length($msg->body());
	ok($tmp <= 1000, "normal body $_");
	$tmp = keys(%{ $msg->header() });
	ok($tmp <= 6, "normal header $_");
	$tmp = grep($_ !~ /^rnd-/, keys(%{ $msg->header() }));
	is($tmp, 0, "normal header prefix $_");
    }
    $tmp = 0;
    foreach (1 .. 100) {
	eval { $msg = $mg->message() };
	$tmp++ unless $@;
    }
    is($tmp, 100, "normal generator");
}

#
# test random integers
#

sub test2 () {
    my(%seen, @tmp);

    %seen = ();
    foreach (1 .. 1000) {
	$seen{Messaging::Message::Generator::_rndint(17)}++;
    }
    @tmp = keys(%seen);
    is("@tmp", "17", "_rndint(17)");

    %seen = ();
    foreach (1 .. 1000) {
	$seen{Messaging::Message::Generator::_rndint("173-231")}++;
    }
    @tmp = keys(%seen);
    ok(scalar(@tmp) > 30, "_rndint(173-231)");
    @tmp = grep($_ < 173 || 231 < $_, keys(%seen));
    is("@tmp", "", "_rndint(173-231)");

    %seen = ();
    foreach (1 .. 1000) {
	$seen{Messaging::Message::Generator::_rndint("173^231")}++;
    }
    @tmp = keys(%seen);
    ok(scalar(@tmp) > 20, "_rndint(173^231)");
    @tmp = grep($_ < 173 || 231 < $_, keys(%seen));
    is("@tmp", "", "_rndint(173^231)");
}

#
# test random strings
#

sub test3 () {
    my(@range, $e, $tmp, $bogus);

    @range = ('A-Z', '0-9a-f', '0-9a-zA-Z\_\-', '\x20-\x7e');
    foreach $e (0 .. $#range) {
	$bogus = "";
	foreach (1 .. 1000) {
	    $tmp = Messaging::Message::Generator::_rndstr(0, 1000, $e);
	    next if $$tmp =~ /^[$range[$e]]{1000}$/;
	    $bogus = $$tmp;
	}
	is($bogus, "", "_rndstr(0, 1000, $e)");
    }
}

#
# test all
#

test0();
test1();
test2();
test3();
