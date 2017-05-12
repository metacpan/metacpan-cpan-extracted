#!/usr/bin/perl

#
# realpath.t
#


use strict ;
use Test ;
use Cwd;
use File::Path;
use File::PathConvert qw( setfstype realpath );

my @data ;
my $cdir ;
my $drive_letter ;

BEGIN {
   # BUG: This is completely unix/DOS centric. Need to build separate
   # tests for each platform and skip those that don't apply. It might work
   # for othe OSs, but we need testers...

   $cdir = cwd();
   ( $drive_letter= $cdir ) =~ s#^((?:[a-zA-Z]:)?).*$#$1# ;

   @data = (
      # INPUT                OUTPUT
      [ $cdir, '/',                  "$drive_letter/"     ],
      [ $cdir, '///',                "$drive_letter/"     ],
      [ $cdir, '/.',                 "$drive_letter/"     ],
      [ $cdir, '.',                  "$cdir"              ],
      [ $cdir, "test",               "$cdir/test"         ],
      [ $cdir, "file",               "$cdir/file"         ],
      [ $cdir, "test/./t1",          "$cdir/test/t1"      ],
      [ $cdir, "test/t1/../t1/file", "$cdir/test/t1/file" ],
      [ $cdir, "test/t1/../t1/file", "$cdir/test/t1/file" ],
      [ $cdir, "test/t1/../t1/.", "$cdir/test/t1" ],
      [ $cdir, "test/t1/../t1/t2/..", "$cdir/test/t1" ],
   );

   -d 'test/t1/t2/t3' || mkpath('test/t1/t2/t3') || die("cannot mkpath");
   -d 'test/t1/t4/t5' || mkpath('test/t1/t4/t5') || die("cannot mkpath");
   open(FILE, ">test/t1/t4/t5/file") || die("cannot create");
   close(FILE);

   #----------------------------------------------------------------------
   #
   # Symlinks:
   # test/t1/la -> t4/t5
   # test/t1/t2/t3/lb -> ../../t1/la
   # test/t1/t2/lc -> t3/lb
   # test/t1/ld -> t4
   #
   #----------------------------------------------------------------------
   # Only do symbolic link tests if symlinks can be made on this OS.
   chdir("$cdir/test/t1") || die("cannot chdir");
   if ( -l 'la' || eval { symlink('t4/t5', 'la') } ) {
      push( @data, [ $cdir, "test/t1/la", "$cdir/test/t1/t4/t5" ] ) ;
   }

   if ( -l 'ld' || eval { symlink('t4', 'ld') } ) {
      push( @data, [ $cdir, "test/t1/ld", "$cdir/test/t1/t4" ] ) ;
      push( @data, [ $cdir, "test/t1/ld/t5", "$cdir/test/t1/t4/t5" ] ) ;
   }

   chdir("$cdir/test/t1/t2/t3") || die("cannot chdir");
   if ( -l 'lb' || eval { symlink('../../../t1/la', 'lb') } ) {
      push( @data, [ $cdir, "test/t1/t2/t3/lb", "$cdir/test/t1/t4/t5" ] ) ;
   }

   chdir("$cdir/test/t1/t2") || die("cannot chdir");
   if ( -l 'lc' || eval { symlink('t3/lb', 'lc') } ) {
      push( @data, [ $cdir, "test/t1/t2/lc", "$cdir/test/t1/t4/t5" ] ) ;
      push( @data, [ $cdir, "test/t1/t2/lc/file", "$cdir/test/t1/t4/t5/file" ] ) ;
   }

   plan tests => ( $#data + 1 ) ;
}

my $oldfsspec = '' ;

my $i ;

for ( $i = 0 ; $i <= $#data ; ++$i )
{
   my( $cdir, $in, $expected ) = @{ $data[ $i ] } ;

   die '$cdir undefined'
      unless defined( $cdir ) ;
   die '$in undefined'
      unless defined( $in ) ;
   die '$expected undefined'
      unless defined( $expected ) ;

   chdir("$cdir") || die("cannot chdir $cdir");
   ok( realpath($in), $expected, "realpath( \"$in\" )" ) ;
}
