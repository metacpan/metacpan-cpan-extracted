#!/usr/bin/perl
#
# Copyright (C) 2011 by Opera Software Australia Pty Ltd
#
# This library is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#

use strict;
use warnings;
use IO::File;
use lib 'lib';

my @cmds = (
    "make -C test PERL=\"$^X\" run",
);

foreach my $cmd (@cmds)
{
    print "$cmd\n";
    STDOUT->flush;
    my $res = system($cmd);
    die "Failed running: $cmd" unless defined $res && $res == 0;
}
