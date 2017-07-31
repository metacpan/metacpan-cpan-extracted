#!perl -T

use strict;
use warnings FATAL => 'all';
use Test::More tests => 1;

eval "use Hash::Merge::Extra qw(NOT_EXISTS)";
like(
    $@,
    qr/^Unable to register NOT_EXISTS \(no such behavior\) /,
    "Must croak for absent behaviors"
);

