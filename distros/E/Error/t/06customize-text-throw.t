#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 3;

use Error qw(:try);

package MyError::Foo;

use vars qw(@ISA);

@ISA=qw(Error);

package MyError::Bar;

use vars qw(@ISA);

@ISA=qw(Error);

package main;

{
    eval
    {
        try
        {
            die "Hello";
        }
        catch MyError::Foo with {
        };
    };

    my $err = $@;

    # TEST
    ok($err->isa("Error::Simple"), "Error was auto-converted to Error::Simple");
}

sub throw_MyError_Bar
{
    my $args = shift;
    my $err = MyError::Bar->new();
    $err->{'MyBarText'} = $args->{'text'};
    return $err;
}

{
    local $Error::ObjectifyCallback = \&throw_MyError_Bar;
    eval
    {
        try
        {
            die "Hello\n";
        }
        catch MyError::Foo with {
        };
    };

    my $err = $@;

    # TEST
    ok ($err->isa("MyError::Bar"), "Error was auto-converted to MyError::Bar");
    # TEST
    is ($err->{'MyBarText'}, "Hello\n", "Text of the error is correct");
}
