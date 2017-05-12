use strict;
use warnings;

use Test::More tests => 2;
use DBM::Deep;
my $dbm = DBM::Deep->new( 'test.db' );

$dbm->{'models'} = {};
$dbm->{'models'}{'Point'} = {};
$dbm->{'models'}{'Point'}{0}{0} = { y => 0, x => 0 };
$dbm->{'models'}{'Point'}{1}{0} = { y => 1, x => 0 };
$dbm->{'models'}{'Point'}{0}{1} = { y => 0, x => 1 };
$dbm->{'models'}{'Point'}{69}{42} = { y => 69, x => 42 };

my $table  = $dbm->{'models'}{'Point'};
my @keys   = keys %$table;
pass('got keys');
my @values = values %$table;
pass('got values');
