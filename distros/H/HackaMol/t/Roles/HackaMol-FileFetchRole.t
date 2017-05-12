#!/usr/bin/env perl

use strict;
use warnings;
use Test::Moose;
use Test::More;
use Test::Warn;
use Test::Fatal qw(lives_ok);
use Path::Tiny;
use HackaMol;

my @attributes = qw(
  pdbserver
  overwrite
);

my @methods = qw(
  get_pdbid
  getstore_pdbid
);

map has_attribute_ok( 'HackaMol', $_ ), @attributes;
map can_ok (          'HackaMol', $_ ), @methods;

my $bldr;
my $group;
lives_ok {
    $bldr = HackaMol->new();
}
'Test creation of bldr with role';

ok($bldr->DOES('HackaMol::Roles::FileFetchRole'), 'Class does FileFetchRole');

my $pdbid = '1l2y';
my $pdb = path($pdbid . ".pdb");
unlink("$pdb") if (-f $pdb);

my $file = $bldr->get_pdbid($pdbid);
$bldr->getstore_pdbid($pdbid);

my $tmp = $pdb->slurp;
is($file,$tmp, 'download file and text same');

warning_is { $bldr->getstore_pdbid($pdbid) }
    "$pdbid.pdb exists, set self->overwrite(1) to overwrite",
    "carp warning if trying to download a file that exists";

$bldr->overwrite(1);
$bldr->getstore_pdbid($pdbid);
$bldr->getstore_pdbid($pdbid,'quick.pdb');

ok(-f 'quick.pdb', 'write to another filehandle');
$tmp = path('quick.pdb')->slurp;
is($file,$tmp, 'download file and text again same');

unlink("$pdb") if (-f $pdb);
unlink("quick.pdb") if (-f 'quick.pdb');

done_testing();

