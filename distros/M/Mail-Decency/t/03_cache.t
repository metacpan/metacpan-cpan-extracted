#!/usr/bin/perl

use strict;
use Test::More tests => 4;
use Mail::Decency::Helper::Cache;
use FindBin qw/ $Bin /;
use lib "$Bin/lib";


SKIP: {
    
    skip "Cache::File not installed, skipping tests", 1 unless eval "use Cache::File; 1;";
    
    subtest "Cache::File" => sub {
        plan tests => 4;
        
        my $cache = Mail::Decency::Helper::Cache->new(
            class => "File",
            cache_root => "$Bin/data/cache"
        );
        test_cache( $cache );
        
    };
};


SKIP: {
    
    skip "Cache::FastMmap not installed, skipping tests", 1 unless eval "use Cache::FastMmap; 1;";
    
    subtest "Cache::FastMmap" => sub {
        plan tests => 4;
        
        my $file = "$Bin/data/test.mmap";
        unlink $file if -f $file;
        my $cache = Mail::Decency::Helper::Cache->new(
            class      => "FastMmap",
            share_file => $file,
        );
        test_cache( $cache );
        unlink $file if -f $file;
    };
};


SKIP: {
    
    skip "Cache::Memory not installed, skipping tests", 1 unless eval "use Cache::Memory; 1;";
    
    subtest "Cache::Memory" => sub {
        plan tests => 4;
        
        my $cache = Mail::Decency::Helper::Cache->new(
            class      => "Memory",
        );
        test_cache( $cache );
    };
};


SKIP: {
    
    skip "Cache::Memcached not installed, skipping tests", 1 unless eval "use Cache::Memcached; 1;";
    skip "Cache::Memcached skipped, set TEST_MEMCACHE in ENV to enable", 1 unless $ENV{ TEST_MEMCACHE };
    
    subtest "Cache::Memcached" => sub {
        plan tests => 4;
        
        my $server = $ENV{ MEMCACHE_HOST } || 'localhost';
        my $port   = $ENV{ MEMCACHE_PORT } || 11211;
        
        my $cache = Mail::Decency::Helper::Cache->new(
            class      => "Memcached",
            servers    => [ "$server:$port" ]
        );
        test_cache( $cache );
    };
};


sub test_cache {
    my ( $cache ) = @_;
    
    my $name = "some-name-". time();
    
    # check empty
    my $res = $cache->get( $name );
    ok( !$res, "Emptiness test" );
    
    # insert
    $cache->set( $name => "xxx" );
    $res = $cache->get( $name );
    ok( $res && $res eq "xxx", "Cache write and read" );
    
    # remove
    $cache->remove( $name );
    $res = $cache->get( $name );
    ok( ! $res, "Cache remove" );
    
    # timeout
    $cache->set( $name => "xxx", time()+1 );
    sleep 2;
    $res = $cache->get( $name );
    ok( ! $res, "Cache timeout works" );
}



