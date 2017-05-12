#!perl
#
# This file is part of Debug-Fork-Tmux
#
# This software is Copyright (c) 2013 by Peter Vereshagin.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#

use strict;
use warnings;
use Test::More;

foreach my $env_skip (
    qw(
    SKIP_POD_LINKCHECK
    )
    )
{
    plan skip_all => "\$ENV{$env_skip} is set, skipping"
        if $ENV{$env_skip};
}

eval "use Test::Pod::LinkCheck";
if ($@) {
    plan skip_all => 'Test::Pod::LinkCheck required for testing POD';
}
else {
    Test::Pod::LinkCheck->new->all_pod_ok;
}
