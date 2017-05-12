#!/usr/bin/perl -w

# these are for the win32 module and do require win32

use strict;

use Test::More tests => 1;

SKIP: {
    eval "use Win32";
	skip('These tests are only applicable on a win32 platform', 1) if $@;

    use Devel::Platform::Info::Win32;

    my $win32 = Devel::Platform::Info::Win32->new();
	my $info = $win32->get_info();
	# this doesn't really check whether we got a sensible result
	# more that it didn't crash.
	is($info->{osflag}, $^O);

};
