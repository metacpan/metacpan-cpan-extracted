#!/usr/bin/env perl
use strict; use warnings;
use FindBin qw( $Bin );
BEGIN { require "$Bin/device-oui-test-lib.pl" };

plan tests => 40;

{
    Device::OUI->cache_db( undef );
    ok( my $handle = Device::OUI->cache_handle, "got the cache_handle" );
    is( ref $handle, 'HASH', '... is a hashref' );
    cache_tests();
}

{
    Device::OUI->cache_db( 'test-cache.db' );
    ok( my $handle = Device::OUI->cache_handle, "got the cache_handle" );
    is( ref $handle, 'HASH', '... is a hashref' );
    cache_tests();
}

{
    # update_from_file tests
    Device::OUI->cache_db( undef );
    Device::OUI->file_url( undef );
    Device::OUI->search_url( undef );
    Device::OUI->cache_file( "$Bin/minimal-oui.txt" );
    for my $sample ( samples() ) {
        my $oui = Device::OUI->new( $sample->{ 'oui' } );
        is(
            $oui->organization,
            $sample->{ 'organization' },
            "org matches for update_from_file",
        );
    }
}

{
    my $in = { foo => 'bar', baz => undef };
    Device::OUI->cache( stuff => $in );
    $in->{ 'baz' } = '';
    my $out = Device::OUI->cache( 'stuff' );
    is_deeply( $in, $out, "cache filled in undefined values" );
}

sub cache_tests {
    my @simple_tests = (
        { oui => '00-00-01', organization => 'cache test' },
        { oui => '00-00-02', organization => 'a b c d e f g h i j k l m' },
        { oui => '00-00-03', organization => 'n o p q r s t u v w x y z' },
        { oui => '00-00-04', organization => "a\nb\nc\nd\ne\nf\ng\nh\ni" },
    );
    for my $t ( @simple_tests ) {
        my $n = $t->{ 'oui' };
        ok( Device::OUI->cache( $n => $t ), "simple cache set $n" );
        ok( my $o = Device::OUI->cache( $n ), "simple cache get $n" );
        is_deeply( $t, $o, "simple cache round-tripped $n" );
    }
    my $test = {
      oui => "00-17-F2",
      company_id => "0017F2",
      organization => "Apple Computer",
      address => "1 Infinite Loop MS:35GPO\nCupertino CA 95014\nUNITED STATES",
    };
    ok( Device::OUI->cache( $test->{ 'oui' } => $test ), "cache set" );
    ok( my $new = Device::OUI->cache( $test->{ 'oui' } ), "cache get" );
    is_deeply( $test, $new, "cache round-tripped ok" );
}

my $obj = Device::OUI->new( '00-17-F2' );
