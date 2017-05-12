
use strict;
use warnings;

use Test::More tests => 4;
use Test::NoWarnings;

use File::Temp qw( tempdir );

use lib './lib';
use File::Util qw( SL );

# one recognized instantiation setting
my $ftl = File::Util->new( );

$ftl->use_flock( 0 ) if $^O =~ /solaris|sunos/i;

my $tempdir = tempdir( CLEANUP => 1 );

my $testbed = setup_test_tree();

my $dir_ref = $ftl->load_dir( $testbed );

is_deeply $dir_ref => {
  'o.css'  => 'JAPH',
  'l.scr'  => 'JAPH',
  'i.jpg'  => 'JAPH',
  'm.html' => 'JAPH',
  'k.ppt'  => 'JAPH',
  'j.xls'  => 'JAPH',
  'p.avi'  => 'JAPH',
  'n.js'   => 'JAPH'
} => 'load_dir() loads directory into hashref';

$dir_ref = $ftl->load_dir( $testbed => { as_listref => 1 } );

is_deeply $dir_ref => [
  ( 'JAPH' ) x 8
] => 'load_dir() loads directory into listref';

$dir_ref = [ $ftl->load_dir( $testbed => { as_list => 1 } ) ];

is_deeply $dir_ref => [
  ( 'JAPH' ) x 8
] => 'load_dir() loads directory into list';

exit;

sub setup_test_tree {

   my $deeper = $tempdir . SL . 'xfoo' . SL . 'zbar';

   $ftl->make_dir( $deeper );

   my @test_files = qw(
      i.jpg   j.xls
      k.ppt   l.scr
      m.html  n.js
      o.css   p.avi
   );

   for my $tfile ( @test_files )
   {
      $ftl->write_file( { file => $deeper . SL . $tfile, content => 'JAPH' } );
   }

   return $deeper;
}



