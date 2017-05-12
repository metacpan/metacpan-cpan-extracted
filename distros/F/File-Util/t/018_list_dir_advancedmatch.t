
use strict;
use warnings;

use Test::More tests => 19;
use Test::NoWarnings;

use File::Temp qw( tempdir );

use lib './lib';
use File::Util qw( SL NL strip_path );

# one recognized instantiation setting
my $ftl = File::Util->new( );

my $tempdir = tempdir( CLEANUP => 1 );

setup_test_tree();

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         rpattern    => '\.sh$|\.js$',
         files_only  => 1,
         recurse     => 1,
      }
   )
], [ qw( e.sh n.js ) ], 'legacy recursive file match (rpattern="...")';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         files_match => qr/\.sh$|\.js$/,
         files_only  => 1,
         recurse     => 1,
      }
   )
], [ qw( e.sh n.js ) ], 'recursive files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         files_match => { or => [ qr/\.sh$/, qr/\.js$/ ] },
         files_only  => 1,
         recurse     => 1,
      }
   )
], [ qw( e.sh n.js ) ], 'recursive OR files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         files_match => { and => [ qr/\.sh$/, qr/[[:alpha:]]\.\w\w/ ] },
         files_only  => 1,
         recurse     => 1,
      }
   )
], [ qw( e.sh ) ], 'recursive AND files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         dirs_match  => qr/[xyz](?:foo|bar)/,
         dirs_only   => 1,
         recurse     => 1,
      }
   )
], [ qw( xfoo zbar ) ], 'recursive dirs_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         dirs_match  => qr/[xyz](?:foo|bar)/,
         files_match => qr/^[ijk]/,
         recurse     => 1,
      }
   )
], [ qw( xfoo zbar i.jpg j.xls k.ppt ) ],
   'recursive dirs_match + files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         dirs_match  => { or  => [ qr/foo$/,  qr/^zba/  ] },
         files_match => { and => [ qr/^[ab]/, qr/\.\w+/ ] },
         recurse     => 1,
      }
   )
], [ qw( xfoo zbar a.txt b.log ) ],
   'recursive OR dirs_match + AND files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         dirs_match  => { or  => [ qr/^.foo/, qr/ar$/   ] },
         files_match => { and => [ qr/^[ij]/, qr/\.\w+/ ] },
         recurse     => 1,
         files_only  => 1,
      }
   )
], [ qw( i.jpg j.xls ) ],
   'a different recursive OR dirs_match + AND files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         parent_matches => { and => [ qr/^.b/, qr/ar$/   ] },
         files_match    => { and => [ qr/^[ij]/, qr/\.\w{3}/ ] },
         recurse        => 1,
         files_only     => 1,
      }
   )
], [ qw( i.jpg j.xls ) ],
   'recursive AND parent_matches + AND files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         parent_matches => qr/^[[:alnum:]\-_\.]+$/,
         files_match    => qr/^[def]/,
         recurse        => 1,
         files_only     => 1,
      }
   )
], [ qw( d.bat e.sh f.conf ) ],
   'recursive single arg parent_matches + single arg files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         parent_matches => qr/^.bar$/,
         files_match  => qr/^[jkl]/,
         recurse        => 1,
         files_only     => 1,
      }
   )
], [ qw( j.xls k.ppt l.scr ) ],
   'a different recursive single arg parent_matches + single arg files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         parent_matches => qr/^.bar$/,
         rpattern       => '^[jk]',
         recurse        => 1,
         files_only     => 1,
      }
   )
], [ qw( j.xls k.ppt ) ],
   'recursive single arg parent_matches + legacy files match (rpattern="...")';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         parent_matches => { or => [ qr/^[[:alnum:]\-_\.]+$/, qr/bar$/ ] },
         files_match  => qr/^[ak]/,
         recurse        => 1,
         files_only     => 1,
      }
   )
], [ qw( a.txt k.ppt ) ],
   'recursive OR parent_matches + single arg files_match';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         path_matches => { and => [ qr/foo/, qr/bar$/ ] },
         recurse      => 1,
      }
   )
], [ qw( zbar i.jpg j.xls k.ppt l.scr m.html n.js o.css p.avi ) ],
   'recursive AND path_matches';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         path_matches => { or => [ qr/foo$/, qr/bar$/ ] },
         recurse      => 1,
      }
   )
], [ qw( xfoo zbar i.jpg j.xls k.ppt l.scr m.html n.js o.css p.avi ) ],
   'recursive OR path_matches';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         path_matches => { and => [ qr/foo$/, qr/bar$/ ] },
         recurse      => 1,
      }
   )
], [ ],
   'recursive AND path_matches that should return an empty list';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         path_matches => { or => [ qr/foo$/, qr/bar$/ ] },
         dirs_only    => 1,
         recurse      => 1,
      }
   )
], [ qw( xfoo zbar ) ],
   'recursive OR path_matches returning only directories';

is_deeply [
   map { strip_path( $_ ) } $ftl->list_dir(
      $tempdir => {
         path_matches => qr/bar$/,
         dirs_only    => 1,
         recurse      => 1,
      }
   )
], [ qw( zbar ) ],
   'recursive single arg path_matches returning only directories';

exit;

sub setup_test_tree {

   my @test_files  = qw(
      a.txt   b.log
      c.ini   d.bat
      e.sh    f.conf
      g.bin   h.rc
   );

   for my $tfile ( @test_files )
   {
      $ftl->touch( $tempdir . SL . $tfile );
   }

   my $deeper = $tempdir . SL . 'xfoo' . SL . 'zbar';

   $ftl->make_dir( $deeper );

   @test_files = qw(
      i.jpg   j.xls
      k.ppt   l.scr
      m.html  n.js
      o.css   p.avi
   );

   for my $tfile ( @test_files )
   {
      $ftl->write_file( { file => $deeper . SL . $tfile, content => rand } );
   }

   return;
}


