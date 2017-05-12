#!/usr/bin/perl

use strict;
use warnings;

use Error (qw(:try));
use Test::More tests => 2;

my $count_of_Error = 0;
eval
{
try
{
    die +{ 'private' => "Shlomi", 'family' => "Fish" };
}
catch Error with
{
    my $err = shift;
    $count_of_Error++;
}
};
my $exception = $@;

# TEST
is_deeply (
    $exception,
    +{'private' => "Shlomi", 'family' => "Fish"},
    "Testing for thrown exception",
);

# TEST
is ($count_of_Error, 0, "No Errors caught.");
