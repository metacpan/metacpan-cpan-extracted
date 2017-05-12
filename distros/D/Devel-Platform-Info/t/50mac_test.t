#!/usr/bin/perl -w

use strict;
use Test::More tests => 12;

my @results = ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i');

BEGIN
{
    # I'd like to do this less crudely but I haven't figured out
    # how to get anything useful from the parameter passed to us
	*CORE::GLOBAL::readpipe = sub { 
		return shift @results;
	};
}


SKIP: {

    eval "use 5.010_000";
    skip('These tests only work on Perl 5.10 and higher', 12) if $@;
    use Devel::Platform::Info::Mac;

    my $info = Devel::Platform::Info::Mac->new();

    my $result = $info->get_info();
    is($$result{kernel}, 'c');
    is($$result{archname}, 'b');

    @results = ('Darwin', '10.3', 'PPC', 'Darwin 1', 'uname -a');
    $result = $info->get_info();
    is($result->{osname}, 'Mac');
    is($result->{osflag}, $^O);
    is($result->{oslabel}, 'OS X');
    is($result->{codename}, 'Panther');
    is($result->{osvers}, '10.3');
    is($result->{archname}, 'PPC');
    is($result->{is32bit}, 1);
    is($result->{is64bit}, 0);
    is($result->{kernel}, 'Darwin 1');
    is_deeply($result->{source}, 
        {
        'sw_vers -productVersion' => '10.3',
        'uname -p' => 'PPC',
        'uname -a' => 'uname -a',
        'uname -v' => 'Darwin 1',
        'uname -s' => 'Darwin',
        }
    );

}

