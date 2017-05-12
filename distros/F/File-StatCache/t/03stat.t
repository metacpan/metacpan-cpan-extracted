#!/usr/bin/perl -w

use strict;

use Test::More tests => 28;

use File::StatCache qw( get_stat );

sub touch($)
{
   my ( $path ) = @_;

   local *F;
   open( F, ">", $path ) or die "Cannot open '$path' in append mode - $!";
   print F "Content\n";
   close( F );
}

my $touchfile = "./test-file-statcache.touch";

END {
   unlink( $touchfile );
}

if( -f $touchfile ) {
   die "Testing file $touchfile already exists";
}

touch( $touchfile );

my @fs  = stat( $touchfile );
my $fsc = File::StatCache::get_stat( $touchfile );

ok( defined $fsc, 'defined $fsc' );

is( $fsc->dev,     $fs[0],  'dev'     );
is( $fsc->ino,     $fs[1],  'ino'     );
is( $fsc->mode,    $fs[2],  'mode'    );
is( $fsc->nlink,   $fs[3],  'nlink'   );
is( $fsc->uid,     $fs[4],  'uid'     );
is( $fsc->gid,     $fs[5],  'gid'     );
is( $fsc->rdev,    $fs[6],  'rdev'    );
is( $fsc->size,    $fs[7],  'size'    );
is( $fsc->atime,   $fs[8],  'atime'   );
is( $fsc->mtime,   $fs[9],  'mtime'   );
is( $fsc->ctime,   $fs[10], 'ctime'   );
is( $fsc->blksize, $fs[11], 'blksize' );
is( $fsc->blocks,  $fs[12], 'blocks'  );

my @fsc = File::StatCache::stat( $touchfile );

is( scalar @fsc, 13, 'scalar @fsc' );

is( $fsc[0],  $fs[0],  'dev'     );
is( $fsc[1],  $fs[1],  'ino'     );
is( $fsc[2],  $fs[2],  'mode'    );
is( $fsc[3],  $fs[3],  'nlink'   );
is( $fsc[4],  $fs[4],  'uid'     );
is( $fsc[5],  $fs[5],  'gid'     );
is( $fsc[6],  $fs[6],  'rdev'    );
is( $fsc[7],  $fs[7],  'size'    );
is( $fsc[8],  $fs[8],  'atime'   );
is( $fsc[9],  $fs[9],  'mtime'   );
is( $fsc[10], $fs[10], 'ctime'   );
is( $fsc[11], $fs[11], 'blksize' );
is( $fsc[12], $fs[12], 'blocks'  );

