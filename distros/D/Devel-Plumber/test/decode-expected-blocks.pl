#!/usr/bin/perl
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

use strict;
use warnings;

my $filename = shift || 'expected-blocks.dat';
my $reclen = 16;
my $pack_template = "QLL";
my @state_names = qw(free LEAKED MAYBE_LEAKED reached);

open EB, '<', $filename
    or die "Cannot open $filename for reading: $!";
while (read(EB, $_, $reclen))
{
    my ($addr, $size, $state) = unpack($pack_template);
    printf "0x%016x 0x%x %s\n",
	$addr, $size, $state_names[$state];
}
close EB;
