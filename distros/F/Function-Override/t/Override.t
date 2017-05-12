#!/usr/bin/perl -w

use strict;
use Test::More tests => 7;

BEGIN { use_ok 'Function::Override'; }

sub foo {
    my($blech) = @_;
    return "BLECH!";
}

use vars qw($NumArgs);
#$Function::Override::Debug = 1;

my $callback = sub { $NumArgs = scalar @_ };
override('foo', $callback);

is( foo(qw(this that)), 'BLECH!' );
is( $NumArgs, 2 );


# Has to be in a BEGIN block so the prototype applies.
my $override_called = 0;
BEGIN {
    if( $] >= 5.010 ) {
        eval q{
            sub underscore (_) { return $_[0] }
        };
    
        override('underscore', sub { $override_called++ });
    }
}

SKIP: {
    skip "_ prototype introduced in 5.10", 4 if $] < 5.010;

    local $_ = 42;
    is underscore(),   42;
    is $override_called, 1;
    is underscore(23), 23;
    is $override_called, 2;
}

