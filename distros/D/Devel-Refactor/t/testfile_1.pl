#!/usr/bin/perl
# $Header: $
#
# This file is fodder for various Devel::Refactor tests
###############################################################################


use strict;
use warnings;

# We will eventually want to change the name of oldSub
my $string = oldSub(1,2,3);

package FakeClass;

my $string2 = oldSub ($string,'a','b');

my $object = {};
bless $object, 'FakeClass';

my $string3 = $object->oldSub(6,7);

print "Got $string and then $string2 and then $string3\n";

oldSub('d','e','f') or die("Couldn't execute oldSub: $!");

###################

sub oldSub {
    my ($arg1,$arg2,$arg3) = @_;
    my $result = $arg1 . $arg2;
    return $result;
}