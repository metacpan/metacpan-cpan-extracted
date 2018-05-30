#!/usr/bin/perl

use strict;
use warnings;

use Error qw(:try);
use Test::More tests => 4;

try
{
    try { die "inner" }
    catch Error::Simple with { die "foobar" };
}
otherwise
{
    my $err = shift;

    # TEST
    ok( scalar( $err =~ /foobar/ ), "Error rethrown" );
};

try
{
    try { die "inner" }
    catch Error::Simple with { throw Error::Simple "foobar" };
}
otherwise
{
    my $err = shift;

    # TEST
    ok( scalar( "$err" =~ /foobar/ ), "Thrown Error::Simple" );
};

try
{
    try { die "inner" }
    otherwise { die "foobar" };
}
otherwise
{
    my $err = shift;

    # TEST
    ok( scalar( "$err" =~ /foobar/ ), "die foobar" );
};

try
{
    try { die "inner" }
    catch Error::Simple with { throw Error::Simple "foobar" };
}
otherwise
{
    my $err = shift;

    # TEST
    ok( scalar( $err =~ /foobar/ ), "throw Error::Simple" );
};

1;
