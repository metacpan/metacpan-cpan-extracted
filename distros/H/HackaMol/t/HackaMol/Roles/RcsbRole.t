#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use HackaMol;


my $bldr = HackaMol->new();
ok($bldr->does('HackaMol::Roles::RcsbRole'), 'thin test for now');
done_testing();
=tryout
my @pdbids = (
"207L",
"208L",
"11BA",
"11BG",
"32C2",
);

$bldr->rcsb_sync_local('cif', @pdbids);

=cut
