
# tests for functions documented in memcached_stats.pod

use strict;
use warnings;

use Test::More;

use Memcached::libmemcached
    #   functions explicitly tested by this file
    qw(
    ),
    #   other functions used by the tests
    qw(
        memcached_server_count
    );

use lib 't/lib';
use libmemcached_test;

my $memc = libmemcached_test_create();

plan tests => 8;

ok $memc;

# walk_stats()

{
    # statistics information actually change from version to version,
    # so we can't even be sure of the number of tests.
    # We could probably do a version specific testing, but for now
    # just check that the some constant items/constraints stay constant.
    my $arg_count_ok = 1;
    my $keys_defined_ok = 1;
    my $hostport_defined_ok = 1;
    my $type_ok = 1;
    my (%seen_hostport, %seen_distinct);
    my $walk_stats_rc = $memc->walk_stats("", sub {
        $arg_count_ok = scalar(@_) == 4 if $arg_count_ok;
        my ($key, $value, $hostport, $type) = @_; # $type is deprecated
        print "$hostport $type: $key=$value\n";
        $keys_defined_ok = defined $key if $keys_defined_ok;
        $hostport_defined_ok = defined $hostport if $hostport_defined_ok;
        $type_ok = defined $type && "" eq $type if $type_ok;
        $seen_hostport{$hostport} = 1;
        $seen_distinct{"$hostport:$key"}++;
        # XXX build $seen_hostport{$hostport} and  it matches memcached_server_count
        # XXX build hash
        return;
    });
    ok( $walk_stats_rc, "walk_stats should return true");
    ok( $arg_count_ok, "walk_stats argument count is sane" );
    ok( $keys_defined_ok, "keys are sane" );
    ok( $hostport_defined_ok, "hostport are sane" );
    ok( $type_ok, "types are sane" );
    is( scalar keys %seen_hostport, memcached_server_count($memc),
        "should see responses from each server");
    is( scalar (grep { $_ != 1 } values %seen_distinct), 0,
        "should see no distinct hostport+key more than once");
}
