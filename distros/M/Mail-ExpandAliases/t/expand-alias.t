#!/usr/bin/perl -w
# ----------------------------------------------------------------------
# vim: set ft=perl: -*-cperl-*-
# ----------------------------------------------------------------------

use strict;
use Config;
use Test;

my $result;
my $cmd = "$Config{'perlpath'} -Mblib expand-alias -f t/aliases 2>/dev/null";

BEGIN {
    plan test => 4;
}

chomp ($result = `$cmd spam`);
ok($result, "/dev/null");

chomp ($result = `$cmd tjones`);
ok($result, 'Tom_Jones@unresolvable.perl.org');

chomp ($result = `$cmd redist`);
ok($result, '| /path/to/redist');

chomp ($result = `$cmd jones`);
ok($result, 'Barnaby_Jones@unresolvable.perl.org Bridget_Jones@unresolvable.perl.org Quincy_Jones@unresolvable.perl.org Tom_Jones@unresolvable.perl.org');
