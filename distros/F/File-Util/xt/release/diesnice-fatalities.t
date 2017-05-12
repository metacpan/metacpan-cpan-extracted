
use strict;
use warnings;

use Test::More;
use File::Temp qw( tempdir );

use lib './lib';

use File::Util qw( SL NL existent );

# ----------------------------------------------------------------------
# determine if we can run these fatal tests
# ----------------------------------------------------------------------
BEGIN {

   if ( $^O !~ /bsd|linux|cygwin/i )
   {
      plan skip_all => 'this OS doesn\'t fail reliably - chmod() issues';
   }
   # the tests in this file have a higher probability of failing in the
   # wild, and so are reserved for the author/maintainers as release tests.
   # these tests also won't reliably run on platforms that can't run or
   # can't respect chmod()... e.g.- windows (and even cygwin to some extent)
   elsif ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{AUTHOR_TESTS} )
   {
      {
         local $@;

         CORE::eval 'use Test::Fatal';

         if ( $@ )
         {
            plan skip_all => 'Need Test::Fatal to run these tests';
         }
         else
         {
            require Test::Fatal;

            Test::Fatal->import( qw( exception dies_ok lives_ok ) );

            plan tests => 37;

            CORE::eval <<'__TEST_NOWARNINGS__';
use Test::NoWarnings;
__TEST_NOWARNINGS__
         }
      }
   }
   else
   {
      plan skip_all => 'these tests are for testing by the author';
   }
}

my $ftl     = File::Util->new();
my $tempdir = tempdir( CLEANUP => 1 );
my $exception;

# ----------------------------------------------------------------------
# set ourselves up for failure
# ----------------------------------------------------------------------

# list of methods that will throw a special exception unless they get
# the input that they require
my @methods_that_need_input = qw(
   list_dir       load_file      write_file     touch
   load_dir       make_dir       open_handle
);

# make an inaccessible file
my $noaccess_file = make_inaccessible_file( 'noaccess.txt' );

# make a directory, inaccessible
my $noaccess_dir = make_inaccessible_dir( 'noaccess/' );

# make a somewhat-deep temp dir structure
$ftl->make_dir( $tempdir . SL . 'a' . SL . 'b' . SL . 'c' );

# ----------------------------------------------------------------------
# let the fail begin
# ----------------------------------------------------------------------

# just test the onfail toggle for all recognized key words.  This needs
# to be revisited to test the actual effect of a given call on a File::Util
# object, and not merely whether or not they return as expected.
is $ftl->onfail(), 'die', 'onfail "die" is default OK';

$ftl->onfail( 'zero' );
is $ftl->onfail(), 'zero', 'onfail "zero" setting toggled OK';

$ftl->onfail( 'warn' );
is $ftl->onfail(), 'warn', 'onfail "warn" setting toggled OK';

$ftl->onfail( 'message' );
is $ftl->onfail(), 'message', 'onfail "message" setting toggled OK';

$ftl->onfail( sub { } );
is ref $ftl->onfail(), 'CODE', 'onfail "callback" setting toggled OK';

$ftl->onfail( 'die' );
is $ftl->onfail(), 'die', 'onfail "die" setting toggled OK';

# the first of our real tests are  several simple failure scenarios wherein
# no input is sent to a given method that requires it.
for my $method ( @methods_that_need_input )
{
   # send no input to $method
   $exception = exception { $ftl->$method() };

   like $exception,
        qr/(?m)^Call to \( $method\(\) \) failed:/,
        sprintf 'send no input to %s()', $method;
}

# try to read-open a file that doesn't exist
$exception = exception { $ftl->load_file( get_nonexistent_file() ) };

like $exception,
     qr/(?m)^File inaccessible or does not exist:/,
     'attempt to read non-existant file';

# try to set a bad flock policy
$exception = exception { $ftl->flock_rules( 'dummy' ) };

like $exception,
     qr/(?m)^Invalid file locking policy/,
     'make a call to flock_rules() with improper input';

# try to read an inaccessible file
$exception = exception { $ftl->load_file( $noaccess_file ) };

like $exception,
     qr/(?m)^Permissions conflict\.  Can't read:/,
     'attempt to read an inaccessible file';

# try to write to an inaccessible file
$exception = exception { $ftl->write_file( $noaccess_file => 'dummycontent' ) };

like $exception,
     qr/(?m)^Permissions conflict\.  Can't write to:/,
     'attempt to write to an inaccessible file';

# try to access a file in an inaccessible directory
$exception = exception { $ftl->load_file( $noaccess_dir . SL . 'dummyfile' ) };

like $exception,
     qr/(?m)^File inaccessible|^Permissions conflict/,
     'attempt to read a file in a restricted directory';

# try to create a file in the inaccessible directory
$exception = exception
{
   $ftl->write_file( $noaccess_dir . SL . 'dummyfile' => 'dummycontent' )
};

like $exception,
     qr/(?m)^Permissions conflict.  Can't (?:create|write)/, # cygwin differs
     'attempt to create a file in a restricted directory';

# try to open a directory as a file for reading
$exception = exception { $ftl->load_file( '.' ) };

like $exception,
     qr/(?m)^Can't call open\(\) on a directory:/,
     'attempt to do file open() on a directory (read)';

# try to open a directory as a file for writing
$exception = exception { $ftl->write_file( '.' => 'dummycontent' ) };

like $exception,
     qr/(?m)^File already exists as directory:/,
     'attempt to do file open() on a directory (write)';

# try to open a file with a bad "mode" argument
$exception = exception
{
   $ftl->write_file(
      {
         filename => 'dummyfile',
         content  => 'dummycontent',
         mode     => 'chuck norris',   # << invalid
         onfail   => 'roundhouse',     # << invalid
      }
   )
};

like $exception,
     qr/(?m)^Illegal mode specified for file open:/,
     'provide illegal open "mode" to write_file()';

# try to SYSopen a file with a bad "mode" argument
$exception = exception
{
   $ftl->open_handle
   (
      {
         use_sysopen => 1,
         filename    => 'dummyfile',
         mode        => 'stealth monkey', # << invalid
      }
   )
};

like $exception,
     qr/(?m)^Illegal mode specified for sysopen:/,
     'provide illegal SYSopen "mode" to write_file()';

# try to SYSopen a file with a utf8 binmode
$exception = exception
{
   $ftl->open_handle
   (
      {
         use_sysopen => 1,
         filename    => 'dummyfile',
         mode        => 'write',
         binmode     => 'utf8',
      }
   )
};

like $exception,
     qr/(?m)^The use of system IO.+?on utf8 file handles is deprecated/,
     'try to open_handle with mixed utf8 and systemIO options';

# try to opendir on an inaccessible directory
$exception = exception { $ftl->list_dir( $noaccess_dir ) };

like $exception,
     qr/(?m)^Can't opendir on directory:/,
     'attempt list_dir() on an inaccessible directory';

# try to makedir in an inaccessible directory
$exception = exception
{ $ftl->make_dir( $noaccess_dir . SL . 'snowballs_chance/' ) };

like $exception,
     qr/(?m)^Permissions conflict\.  Can't create directory:/,
     'attempt make_dir() in an inaccessible directory';

# try to makedir for an existent directory
$exception = exception { $ftl->make_dir( '.' ) };

like $exception,
     qr/(?m)^make_dir target already exists:/,
     'attempt make_dir() for a directory that already esists';

# try to makedir on a file
$exception = exception { $ftl->make_dir( __FILE__ ) };

like $exception,
     qr/(?m)^Can't make directory; already exists as a file/,
     'attempt make_dir() on a file';

# try to list_dir() on a file
$exception = exception { $ftl->list_dir( __FILE__ ) };

like $exception,
     qr/(?m)^Can't opendir\(\) on non-directory:/,
     'attempt to list_dir() on a file';

# try to read more data from a file than the enforced read_limit amount
# ...we set the read_limit purposely low to induce the error
$exception = exception { $ftl->load_file( __FILE__, { read_limit => 0 } ) };

like $exception,
     qr/(?m)^Stopped reading:/,
     'attempt to read a file that\'s bigger than the set read_limit';

# send bad input to abort_depth()
$exception = exception { $ftl->abort_depth( 'cheezburger' ) };

like $exception,
     qr/(?m)^Bad input provided to abort_depth/,
     'make a call to abort_depth() with improper input';

# send bad input to read_limit()
$exception = exception { $ftl->read_limit( 'woof!' ) };

like $exception,
     qr/(?m)^Bad input provided to read_limit/,
     'make a call to read_limit() with improper input';

# intentionally exceed abort_depth
$exception = exception
{
   $ftl->list_dir( $tempdir => { recurse => 1, abort_depth => 1 } )
};

like $exception,
     qr/(?m)^Recursion limit exceeded/,
     'attempt to list_dir recursively past abort_depth limit';

# call write_file() with an invalid file handle
$exception = exception
{
   $ftl->load_file( file_handle => 'not a file handle at all' )
};

like $exception,
     qr/a true file handle reference/,
     'call write_file with a file handle that is invalid (not a real FH ref)';

# Knowing that the two tests below call File::Util methods with built-in
# onfail callbacks to handle issues when they can't create leading directories,
# and knowing that we're calling the methods in a way they will fail, we
# know that our own onfail callbacks (below) should return what we expect
# as long as the built-in onfail callbacks fire them off (repeater-style).
# The built-in onfail callbacks wrap around the callbacks we define below
# and make sure that those custom callbacks get invoked properly.

is $ftl->write_file(
   $noaccess_dir . SL . 'my' . SL . 'dog' . SL . 'rover', 'woof!' => {
      onfail => sub { return 'lassie' }
   }
), 'lassie', 'test native onfail callback repeater mechanism in write_file()';

is $ftl->open_handle(
   $noaccess_dir . SL . 'my' . SL . 'friend' . SL . 'john' => {
      onfail => sub { return 'ian' }
   }
), 'ian', 'test native onfail callback repeater mechanism in open_handle()';

# ----------------------------------------------------------------------
# clean up restricted-access files/dirs, and exit
# ----------------------------------------------------------------------

remove_inaccessible_file( $noaccess_file );
remove_inaccessible_dir( $noaccess_dir );

exit;


# ----------------------------------------------------------------------
# supporting subroutines
# ----------------------------------------------------------------------

sub make_inaccessible_file
{
   my $filename = $ftl->strip_path( shift @_ );

   $filename = $tempdir . SL . $filename;

   $ftl->touch( $filename );

   chmod oct 0, $filename or die $!;

   return $filename;
}

sub remove_inaccessible_file
{
   my $filename = $ftl->strip_path( shift @_ );

   $filename = $tempdir . SL . $filename;

   chmod oct 777, $filename or die $!;

   unlink $filename or die $!;
}

sub make_inaccessible_dir
{
   my $dirname = shift @_;

   $dirname = $tempdir . SL . $dirname;

   $ftl->make_dir( $dirname );

   $ftl->touch( $dirname . SL . 'dummyfile' );

   chmod oct 0, $dirname . SL . 'dummyfile' or die $!;
   chmod oct 0, $dirname or die $!;

   return $dirname;
}

sub remove_inaccessible_dir
{
   my $dirname = $ftl->strip_path( shift @_ );

   $dirname = $tempdir . SL . $dirname;

   chmod oct 777, $dirname or die $!;
   chmod oct 777, $dirname . SL . 'dummyfile' or die $!;

   unlink $dirname . SL . 'dummyfile' or die $!;

   rmdir $dirname or die $!;
}

sub get_nonexistent_file
{
   my $file = ( rand 100 ) . time . $$;

   while ( -e $file )
   {
      $file = get_nonexistent_file();
   }

   return $file;
}

