#!/usr/bin/perl -w

use strict;

use Test::More tests => 5;

use File::StatCache qw( stat );

sub touch($)
{
   my ( $path ) = @_;

   local *F;
   open( F, ">", $path ) or die "Cannot open '$path' in append mode - $!";
   print F "Content\n";
   close( F );
}

# Short cache timeout to ensure quicker testing run
$File::StatCache::STATTIMEOUT = 1;

my $touchfile = "./test-file-statcache.touch";

END {
   unlink( $touchfile );
}

if( -f $touchfile ) {
   warn "Testing file $touchfile already exists";
}

touch( $touchfile );

my @touchfilestats = CORE::stat( $touchfile );

my $now = time();
my @stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Initial stat() call" );

@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Soon cached stat() call" );

my $wait = $File::StatCache::STATTIMEOUT + 1;
sleep( $wait );

@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Later cached stat() call" );

unlink( $touchfile );

# We hope the cache doesn't time out yet - we want a cache hit
@stats = stat( $touchfile );
is_deeply( \@stats, \@touchfilestats, "Cache hit after unlink()" );

sleep( $wait );

@stats = stat( $touchfile );
is( scalar @stats, 0, "Later stat() call after unlink()" );
