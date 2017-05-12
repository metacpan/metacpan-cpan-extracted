
use strict;
use warnings;
use Test::More tests => 3;
use Test::NoWarnings;
use File::Temp qw( tmpnam );

use lib './lib';
use File::Util;

# check object constructor
my $f = File::Util->new();

my $fn = tmpnam(); # get absolute filename

my $have_perms  = $f->is_writable( $f->return_path( $fn ) );

SKIP: {

   if ( !$have_perms ) {

      skip 'Insufficient permissions to perform IO' => 2;
   }
   elsif ( $^O =~ /solaris|sunos/i ) {

      skip 'Solaris flock is broken' => 2;
   }

   # test write
   is $f->write_file( file => $fn, content => 'JAPH' ), 1,
      'write file with abs path' ;

   is $f->load_file( $fn ), 'JAPH', 'file content matches' ;
}

unlink $fn;

exit;
