#!/usr/bin/perl -w

# t/t3.t
#
# Test script for the BioChrome Apache handler

use strict;

use lib qw(. ./t ./lib ../lib ./blib/lib ../blib/lib);

use DummyRequest;

my $dir = -d 't' ? 't/' : './';

print "1..11\n";

use Apache::BioChrome;

print "ok 1\n";

my $d1 = new DummyRequest { 
	uri => '/biochrome/alpha_ff0000_0000ff/simple.gif',
	location => '/biochrome',
};

print "ok 2\n";

# $Apache::BioChrome::DEBUG = 1;
# $Image::BioChrome::DEBUG = 1;
# $Image::BioChrome::VERBOSE = 1;

# expect this to return DECLINED as there is no BioChrome config
my $res = Apache::BioChrome::handler($d1);
print $res == 0 ? "ok 3\n" : "not ok 3\n";

my $d2 = new DummyRequest { 
	uri => '/biochrome/ff0000_0000ff/simple.jpg',
	location => '/biochrome',
	biochrome_cache => "${dir}tmp", 
	biochrome_source => "${dir}gif",
};

$res = Apache::BioChrome::handler($d2);
# we expect this one to return OK
print $res == 200 ? "ok 4\n" : "not ok 4\n";

# we also expect there to be a file in the cache dir
check_and_delete_file("${dir}tmp/biochrome/ff0000_0000ff/simple.jpg",5);

my $d3 = new DummyRequest { 
	uri => '/biochrome/ff0000_0000ff/simple.gif',
	location => '/biochrome',
	biochrome_cache => "${dir}tmp", 
	biochrome_source => "${dir}gif",
};

$res = Apache::BioChrome::handler($d3);
print $res == 200 ? "ok 6\n" : "not ok 6\n";

# we also expect there to be a file in the cache dir
check_and_delete_file("${dir}tmp/biochrome/ff0000_0000ff/simple.gif",7);


# test the no color functionality
my $d4 = new DummyRequest { 
	uri => '/biochrome/simple.gif',
	location => '/biochrome',
	biochrome_cache => "${dir}tmp", 
	biochrome_source => "${dir}gif",
};


$res = Apache::BioChrome::handler($d4);
print $res == 200 ? "ok 8\n" : "not ok 8\n";

# we also expect there to be a file in the cache dir
check_and_delete_file("${dir}tmp/biochrome/simple.gif",9);


my $d5 = new DummyRequest { 
	uri => '/biochrome/ff0000_0000ff/simple.gif',
	location => '/biochrome',
	biochrome_cache => "${dir}tmp", 
	biochrome_path => "${dir}gif",
};


$res = Apache::BioChrome::handler($d5);
print $res == 200 ? "ok 10\n" : "not ok 10\n";

# we also expect there to be a file in the cache dir
check_and_delete_file("${dir}tmp/biochrome/ff0000_0000ff/simple.gif",11);



sub check_and_delete_file {
	my $file = shift || return;
	my $test = shift || return;

	if (-f $file) {
		print "ok $test\n";
		unlink($file);
	} else {
		print "not ok $test\n";
	}
}
