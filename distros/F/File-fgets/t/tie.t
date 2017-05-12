#!/usr/bin/perl

# Test against a tied filehandle

use strict;
use warnings;

use File::fgets;
use Test::More;

BEGIN {
    plan skip_all => "Needs IO::Scalar to test against tied filehandles"
      unless eval { require IO::Scalar };
}

my $fh = IO::Scalar->new(\"foo\nbar");

is fgets($fh, 5), "foo\n";
is fgets($fh, 5), "bar";
ok !fgets($fh, 5);

done_testing;
