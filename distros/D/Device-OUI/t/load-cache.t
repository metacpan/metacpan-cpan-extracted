#!/usr/bin/env perl
use strict; use warnings;
use FindBin qw( $Bin );
BEGIN {
    require "$Bin/device-oui-test-lib.pl";
    require "$Bin/fake-lwp.pl";
}
use constant {
    OUI     => 'Device::OUI',
    db      => "$Bin/test-cache",
    txt     => "$Bin/minimal-oui.txt",
    url     => "file://$Bin/minimal-oui.txt",
    tmp     => "$Bin/test-download.txt",
    cache   => "$Bin/test-cache-file.txt",
};

plan tests => 19;

# Setup for offline testing
OUI->cache_file( txt );
rm( db );
OUI->cache_db( db );
OUI->search_url( undef );
OUI->file_url( undef );

my $src = slurp( txt );

# Test load_cache_from_file ( with file specified )
rm( db );
ok( OUI->load_cache_from_file( txt ), "load_cache_from_file( file )" );
is( OUI->dump_cache(1), $src, "...dumped cache matches source" );

# Test load_cache_from_file ( without file specified )
rm( db );
ok( OUI->load_cache_from_file, "load_cache_from_file()" );
is( OUI->dump_cache(1), $src, "...dumped cache matches source" );

OUI->cache_file( cache );

# Test load_cache_from_web ( with url and file specified )
rm( db, tmp, cache );
ok( OUI->load_cache_from_web( url, tmp ), "load_cache_from_web( url,tmp )" );
is( OUI->dump_cache(1), $src, "...dumped cache matches source" );
is( slurp( tmp ), $src, "...mirrored cache file matches source" );
ok( ! -f cache, "...cache_file wasn't used" );

# Test load_cache_from_web ( with url but not file specified )
rm( db, tmp, cache );
ok( OUI->load_cache_from_web( url, undef ), "load_cache_from_web( url, )" );
is( OUI->dump_cache(1), $src, "...dumped cache matches source" );
is( slurp( cache ), $src, "...mirrored cache file matches source" );
ok( -f cache, "...cache_file was used" );

# Test load_cache_from_web ( with url specified but not file )
rm( db, tmp, cache );
ok( OUI->load_cache_from_web( url, undef ), "load_cache_from_web( url, )" );
is( OUI->dump_cache(1), $src, "...dumped cache matches source" );
is( slurp( cache ), $src, "...mirrored cache file matches source" );
ok( -f cache, "...cache_file was used" );

OUI->cache_file( undef );
is(
    OUI->new( 'FF-FF-FF' )->update_from_file, undef,
    "update_from_file returns undef when no cache_file is set",
);
OUI->cache_file( tmp );
is(
    OUI->new( 'FF-FF-FF' )->update_from_file, undef,
    "update_from_file returns undef when cache_file doesn't exist",
);

OUI->cache_handle( { test => 'foo' } );
is_deeply( OUI->cache_handle, { test => 'foo' } );

# Try getting a cache handle with no AnyDBM_File working
OUI->cache_handle( undef );
@AnyDBM_File::ISA = ();
OUI->cache_handle;
