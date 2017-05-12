#!/usr/bin/perl

# Test the Carp methods

use Carp qw(cluck carp croak confess);
use Test::More tests => 4;
use Log::Scrubber qw(:Carp);	# :all would also work

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

eval { croak "\x1bmsg\n"; };
#diag("croak returned $@\n");
ok(index($@, "[esc]msg\n") != -1, "Carp::croak()");

eval { confess "\x1bmsg\n"; };
#diag("confess returned $@\n");
ok(index($@, "[esc]msg\n") != -1, "Carp::confess()");

eval
{ 
    _setup;
    carp "\x1bmsg\n"; 
};
ok(index(_read, "[esc]msg\n") != -1, "Carp::carp()");

eval
{ 
    _setup;
    cluck "\x1bmsg\n"; 
};
ok(index(_read, "[esc]msg\n") != -1, "Carp::cluck()");



