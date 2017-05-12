#!perl -T

use Test::More tests => 5;


BEGIN {
	use_ok("Digest::MD5::Reverse");
}

	diag("Testing Digest::MD5::Reverse $Digest::MD5::Reverse::VERSION, Perl $], $^X");
    is(reverse_md5("acbd18db4cc2f85cedef654fccc4a4d8"), "foo", "reverse a hash");
    is(reverse_md5("21232f297a57a5a743894a0e4a801fc3"), "admin", "reverse another hash");
    is(reverse_md5(""), undef, "empty string");
    is(reverse_md5("aaaa"), undef, "bad hash");

