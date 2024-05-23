use warnings;
use strict;
use Test::Most 0.38;

my $class = 'Linux::Info::Distribution::Custom';
require_ok($class);
can_ok( $class, qw(_set_regex _set_others _parse_source new) );

dies_ok {
    $class->new( { name => 'Foobar', id => 'foobar' } )
}
'new dies with missing keys';
like $@, qr/file_to_parse/, 'got expected error message';

dies_ok {
    $class->new(
        { name => 'Foobar', id => 'foobar', file_to_parse => '/foo/bar' } )
}
'dies due abstract methods chained';
like $@, qr/Must be implemented by subclasses of/, 'got expected error';

done_testing;
