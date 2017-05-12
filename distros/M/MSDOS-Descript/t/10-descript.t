#! /usr/bin/perl
#---------------------------------------------------------------------
# 10-descript.t
# Copyright 2007 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test the MSDOS::Descript module
#---------------------------------------------------------------------

use Test::More tests => 30;

BEGIN { use_ok('MSDOS::Descript') }

use FindBin '$Bin';
chdir $Bin or die "Unable to cd $Bin: $!";

my @files = (qw(alpha beta gamma delta epsilon), 'alpha omega');

my $d = MSDOS::Descript->new('sample.des');

isa_ok($d, 'MSDOS::Descript');

ok( ! $d->changed, 'nothing changed');

foreach (@files) {
    my $desc = "This is $_";
    is($d->description($_),    $desc, "description $_");
    is($d->description(uc $_), $desc, 'description ' . uc $_);
}

ok( ! $d->changed, 'still unchanged');

$d->rename('delta','wasdelta');
ok($d->changed, 'now changed');
is($d->description('delta'), undef, 'delta undef');
is($d->description('wasdelta'), 'This is delta', 'description wasdelta');

$d->description('beTA', 'New');
is($d->description('Beta'), 'New', 'description Beta');

$d->description('BEta', '');
is($d->description('beta'), undef, 'description beta removed');

$d->description('GAMMA', undef);
is($d->description('gamma'), undef, 'description gamma removed');

ok($d->changed, 'still changed');
$d->write('delete.me');
ok($d->changed, 'still changed after write');

my $d2 = MSDOS::Descript->new('delete.me');

isa_ok($d2, 'MSDOS::Descript');
ok( ! $d2->changed, '$d2 unchanged');

foreach ('Alpha', 'EPSILON', 'WasDelta', 'Alpha Omega') {
    is($d2->description($_), $d->description($_), "match $_");
}
unlink 'delete.me';
