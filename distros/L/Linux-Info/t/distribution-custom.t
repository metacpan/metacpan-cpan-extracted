use warnings;
use strict;
use Test::Most 0.38;

use Linux::Info::Distribution::BasicInfo;

my $class = 'Linux::Info::Distribution::Custom';
require_ok($class);
can_ok( $class, qw(_set_regex _set_others _parse_source new) );

dies_ok {
    $class->new(
        Linux::Info::Distribution::BasicInfo->new( 'foobar', '/foo/bar' ) )
}
'dies due abstract methods chained';
like $@, qr/Must be implemented by subclasses of/, 'got expected error';

done_testing;
