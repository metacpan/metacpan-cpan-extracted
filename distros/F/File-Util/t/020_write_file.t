
use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use File::Temp qw( tempdir );

use lib './lib';
use File::Util qw( SL OS );

# one recognized instantiation setting
my $ftl = File::Util->new( );

$ftl->use_flock( 0 ) if $^O =~ /solaris|sunos/i;

my $tempdir = tempdir( CLEANUP => 1 );

my @test_files = qw(
   i.jpg   j.xls
   k.ppt   l.scr
   m.html  n.js
   o.css   p.avi
);

write_ref_args();

my $dir_ref = $ftl->load_dir( $tempdir => { as_listref => 1 } );

is_deeply $dir_ref => [
  ( 'PeRl' ) x 8
] => 'write_file writes right w/ ref args';

write_two_args();

$dir_ref = $ftl->load_dir( $tempdir => { as_listref => 1 } );

is_deeply $dir_ref => [
  ( 'JAPH' ) x 8
] => 'write_file writes right w/ 2 args';

write_hybrid();

$dir_ref = $ftl->load_dir( $tempdir => { as_listref => 1 } );

is_deeply $dir_ref => [
  ( 'JAPHRaptor' ) x 8
] => 'write_file appends right w/ 2 args + opts hashref';

exit;

sub write_ref_args {

   for my $tfile ( @test_files )
   {
      $ftl->write_file(
         { file => $tempdir . SL . $tfile, content => 'PeRl' }
      );
   }

   return;
}

sub write_two_args {

   for my $tfile ( @test_files )
   {
      $ftl->write_file( $tempdir . SL . $tfile => 'JAPH' );
   }

   return;
}

sub write_hybrid {

   for my $tfile ( @test_files )
   {
      $ftl->write_file(
         $tempdir . SL . $tfile => 'Raptor' => { mode => 'append' }
      );
   }

   return;
}

