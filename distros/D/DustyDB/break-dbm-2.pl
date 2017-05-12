use strict;
use warnings;

use Test::More tests => 3;
use DBM::Deep;
use File::Temp qw( tempfile );
my $dbm = DBM::Deep->new( file => 'test.db', locking => 0 );

$dbm->{'0'} = 'test';
print "test = $dbm->{0}\n";

my $foo;
while (my ($key, $value) = each %$dbm) {
    $foo .= "($key=$value)"; # do almost nothing
}
pass("finished each with $foo");
my @keys   = keys %$dbm;
pass('got keys');
my @values = values %$dbm;
pass('got values');
