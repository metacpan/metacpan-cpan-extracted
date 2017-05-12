#!/usr/bin/perl -w

use strict;

use Test::More tests => 14;
use File::stat qw();

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

my $fs  = File::stat::stat( $touchfile );
my $fsc = File::StatCache::get_stat( $touchfile );

ok( defined $fsc, 'defined $fsc' );

is( $fsc->dev,     $fs->dev,     'dev'     );
is( $fsc->ino,     $fs->ino,     'ino'     );
is( $fsc->mode,    $fs->mode,    'mode'    );
is( $fsc->nlink,   $fs->nlink,   'nlink'   );
is( $fsc->uid,     $fs->uid,     'uid'     );
is( $fsc->gid,     $fs->gid,     'gid'     );
is( $fsc->rdev,    $fs->rdev,    'rdev'    );
is( $fsc->size,    $fs->size,    'size'    );
is( $fsc->atime,   $fs->atime,   'atime'   );
is( $fsc->mtime,   $fs->mtime,   'mtime'   );
is( $fsc->ctime,   $fs->ctime,   'ctime'   );
is( $fsc->blksize, $fs->blksize, 'blksize' );
is( $fsc->blocks,  $fs->blocks,  'blocks'  );

