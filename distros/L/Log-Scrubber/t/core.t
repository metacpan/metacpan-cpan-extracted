#!/usr/bin/perl

# Test the core warn() and die() functions.

use Test::More tests => 2;
use Log::Scrubber;

scrubber_init( { '\x1b' => '[esc]' } );

END { unlink "test.out"; }

sub _read
{
    open FILE, "test.out";
    my $ret = join('', <FILE>);
    close FILE;
    return $ret;
}

sub _setup
{
    open STDERR, ">test.out";
    select((select(STDERR), $|++)[0]);
}

eval { die "\x1bmsg\n"; };
ok($@ eq "[esc]msg\n", "CORE::die()");

eval 
{ 
    _setup;
    warn "\x1bmsg\n"; 
};
ok(_read eq "[esc]msg\n", "CORE::warn()");


