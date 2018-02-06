#!/usr/bin/env perl

use strict;
use warnings;
use feature qw(say);

open my $fh, '<', '/foo/bar/baz' or die $!;
say 'here';

__DATA__
# exit: 2

open("/foo/bar/baz", *, *) = * at exception.pl line 7.
