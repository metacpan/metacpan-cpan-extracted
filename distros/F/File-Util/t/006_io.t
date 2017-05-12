
use strict;
use warnings;
use Test::More tests => 17;
use Test::NoWarnings;

use File::Temp qw( tempdir );

use lib './lib';
use File::Util qw( SL NL existent OS );

my $f          = File::Util->new();
my $tempdir    = tempdir( CLEANUP => 1 );
my $testbed    = $tempdir . SL . $$ . SL . time;
my $tmpf       = $testbed . SL . 'tmptest';
my $have_perms = $f->is_writable( $tempdir );
my $testfh;

SKIP: {

   if ( !$have_perms ) {

      skip 'Insufficient permissions to perform IO in tempdir' => 16;
   }
   elsif ( !solaris_cooperates() ) {

      skip 'Testing with an incooperative Solaris installation' => 16;
   }

   is $f->is_readable( $tempdir ),
      -r '.',
      'File::Util can tell if something is readable';

   is $f->is_writable( $tempdir ),
      -w '.',
      'File::Util can tell if something is writable';

   # this method "just is"... there's nothing to test; here for test coverage
   is $f->last_changed( $tempdir ),
      $f->last_changed( $tempdir ),
      'File::Util can tell when a file was last changed';

   # make a temporary testbed directory
   is $f->make_dir( $testbed => { if_not_exists => 1 } ),
      $testbed,
      "make temp testbed in $testbed";

   # see if it's there
   is -e $testbed, 1, 'testbed created OK';

   # ...again
   is $f->existent( $testbed ), 1, 'File::Util agrees it exists';

   # make a temporary file
   is $f->write_file( file => $tmpf, content => 'LARRY' ), 1,
      'write to a new text file' ;

   # File::Util::touch() a file, and see if it was created ok
   is(
      sub {
           my $tmpf = $testbed . SL . 'touched';

           $f->touch( $tmpf );

           my $result = $f->existent( $tmpf );

           unlink $tmpf;

           return $result;
      }->(), 1, 'create an empty file via File::Util::touch()'
   );

   # get an open file handle
   is(
      sub {
         $testfh = $f->open_handle(
            file => $tmpf,
            mode => 'append',
            onfail => 'message',
            warn_also => 1,
         );

         return ref $testfh
      }->(), 'GLOB', 'get open file handle for appending'
   );

   # make sure it's still open
   ok defined fileno $testfh, 'check if it has a fileno';

   # write to it, close it, write to it in append mode
   print $testfh 'WALL' and close $testfh;

   # load file
   is $f->load_file( $tmpf ), 'LARRYWALL', 'wrote to file OK';

   # write to it with method File::Util::write_file(), compare file contents
   # with the returned value
   is(
      sub {
         $f->trunc( $tmpf ); # again, a solaris workaround

         $f->write_file(
            filename => $tmpf,
            content  => OS . NL
         );

         return $f->load_file( $tmpf );
      }->(), OS . NL, 'write to a file with File::Util->write_file'
   );

   # get line count of file
   is $f->line_count( $tmpf ), 1, 'line count of new file is right';

   # truncate file
   is sub { $f->trunc( $tmpf ); return -s $tmpf }->(), 0,
      'truncate file, then make sure it is zero bytes';

   # get line count of file
   is $f->line_count( $tmpf ), 0, 'truncated file linecount is zero';

   # big directory creation / removal sequence
   my $newdir = $testbed
     . SL . int( rand time )
     . SL . int( rand time )
     . SL . int( rand time )
     . SL . int( rand time );

   # 13
   # make directories
   is $f->make_dir( $newdir, '--if-not-exists' ),
      $newdir, 'make a deep directory tree';
}

exit;

sub solaris_cooperates {

   # we're only probing for solaris here, which has known issues
   return 1 if $^O !~ /solaris|sunos/i;

   my $tmpf = $tempdir . SL . 'solaris';

   my $sf  = File::Util->new( fatals_as_status => 1 );

   my $fh = $sf->open_handle( file => $tmpf );

   my $ok = fileno $fh ? 1 : 0;

   close $fh if $ok;

   unlink $tmpf if $ok;

   $f->use_flock(0); # solaris flock is so broken, it might as well not exist

   return $ok;
}
