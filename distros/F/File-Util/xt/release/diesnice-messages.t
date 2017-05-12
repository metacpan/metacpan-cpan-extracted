
use strict;
use warnings;

use Test::More;

if ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{AUTHOR_TESTS} )
{                            # the tests in this file have a higher probability
   plan tests => 70;          # of failing in the wild, and so are reserved for
                             # the author/maintainers as release tests
   CORE::eval # hide the eval...
   '
use Test::NoWarnings;
   '; # ...from dist parsers
}
else
{
   plan skip_all => 'these tests are for testing by the author';
}

use lib './lib';
use File::Util qw( SL NL existent );

my $f = File::Util->new( fatals_as_errmsg => 1 );

# start testing failure sequence
# 1
like(
   $f->_throw(
      'no such file' =>
      {
         filename  => __FILE__,
         fatals_as_errmsg => 1,
         diag => 1,
      }
   ), qr/inaccessible or does not exist/,
   'no such file (diagnostic mode)'
);

# 1.5
like(
   $f->_throw(
      'no such file' =>
      {
         filename  => __FILE__,
         fatals_as_errmsg => 1,
      }
   ), qr/inaccessible or does not exist/,
   'no such file'
);

# 2
like(
   $f->_throw(
      'bad flock rules' => {
         bad  => __FILE__,
         all => [ $f->flock_rules() ],
         diag => 1,
      }
   ),
   qr/Invalid file locking policy/,
   'bad flock rules (diagnostic mode)'
);

is $f->diagnostic( 1 ), 1,
   'manually toggle on diagnostic mode for entire object';

# 2.25
like(
   $f->_throw(
      'bad flock rules' => {
         bad  => __FILE__,
         all => [ $f->flock_rules() ],
      }
   ),
   qr/Invalid file locking policy/,
   'bad flock rules (diagnostic mode) after manual object-wide diag toggle'
);

# 2.5
like(
   $f->_throw(
      'bad flock rules' => {
         bad  => __FILE__,
         all => [ $f->flock_rules() ],
      }
   ),
   qr/(?sm)^Invalid file locking policy/,
   'bad flock rules'
);

is $f->diagnostic( 0 ), 0,
   'manually toggle off diagnostic mode for entire object';

# 3
like(
   $f->_throw(
      'cant fread' => {
         filename => __FILE__,
         dirname  => '.',
         diag => 1,
      }
   ),
   qr/Permissions conflict\..+?can't read the contents of this file:/,
   'cant fread (diagnostic mode)'
);

# 3.5
like(
   $f->_throw(
      'cant fread' => {
         filename => __FILE__,
         dirname  => '.',
      }
   ),
   qr/(?sm)^Permissions conflict\.  Can't read:/,
   'cant fread'
);

# 4
like(
   $f->_throw( 'cant fread not found' => { diag => 1, filename => __FILE__ } ),
   qr/File not found\.  .+?can't read the contents of this file\:/,
   'cant fread no exists (diagnostic mode)'
);

# 4.5
like(
   $f->_throw( 'cant fread not found' => { filename => __FILE__ } ),
   qr/(?sm)^File not found:/,
   'cant fread no exists'
);

# 5
like(
   $f->_throw(
      'cant fcreate' => {
         filename => __FILE__,
         dirname  => '.',
         diag => 1,
      }
   ),
   qr/Permissions conflict\..+?can't create this file:/,
   'cant fcreate (diagnostic mode)'
);

# 5.5
like(
   $f->_throw(
      'cant fcreate' => {
         filename => __FILE__,
         dirname  => '.',
      }
   ),
   qr/(?sm)^Permissions conflict\.  Can't create:/,
   'cant fcreate'
);

# 6
like( $f->_throw( 'cant write_file on a dir' => { diag => 1, filename => __FILE__ } ),
   qr/can't write to the specified file/,
   'cant write_file on a dir (diagnostic mode)'
);

# 6.5
like( $f->_throw( 'cant write_file on a dir' => { filename => __FILE__ } ),
   qr/(?sm)^File already exists as directory:/,
   'cant write_file on a dir'
);

# 7
like(
   $f->_throw(
      'cant fwrite' => {
         filename => __FILE__,
         dirname  => '.',
         diag => 1,
      }
   ),
   qr/Permissions conflict\..+?can't write to this file:/,
   'cant fwrite (diagnostic mode)'
);

# 7.5
like(
   $f->_throw(
      'cant fwrite' => {
         filename => __FILE__,
         dirname  => '.',
      }
   ),
   qr/(?sm)^Permissions conflict\.  Can't write to:/,
   'cant fwrite'
);

# 8
like(
   $f->_throw(
      'bad openmode popen' => {
         filename => __FILE__,
         badmode  => 'illegal',
         meth     => 'anonymous',
         diag     => 1,
      }
   ),
   qr/Illegal mode specified for file open\./,
   'bad openmode popen (diagnostic mode)'
);

# 8.5
like(
   $f->_throw(
      'bad openmode popen' => {
         filename => __FILE__,
         badmode  => 'illegal',
         meth     => 'anonymous',
      }
   ),
   qr/(?sm)^Illegal mode specified for file open:/,
   'bad openmode popen'
);

# 9
like(
   $f->_throw(
      'bad openmode sysopen' => {
         filename => __FILE__,
         badmode  => 'illegal',
         meth     => 'anonymous',
         diag     => 1,
      }
   ),
   qr/Illegal mode specified for file sysopen/,
   'bad openmode sysopen (diagnostic mode)'
);

# 9.5
like(
   $f->_throw(
      'bad openmode sysopen' => {
         filename => __FILE__,
         badmode  => 'illegal',
         meth     => 'anonymous',
      }
   ),
   qr/(?sm)^Illegal mode specified for sysopen:/,
   'bad openmode sysopen'
);

# 10
like( $f->_throw( 'cant dread' => { diag => 1, dirname => '.' } ),
   qr/Permissions conflict\..+?can't list the contents of this/,
   'cant dread (diagnostic mode)'
);

# 10.5
like( $f->_throw( 'cant dread' => { dirname => '.' } ),
   qr/(?sm)^Permissions conflict\.  Can't list directory:/,
   'cant dread'
);

# 11
like(
   $f->_throw(
      'cant dcreate' => {
         dirname => '.',
         parentd => '..',
         diag    => 1,
      }
   ),
   qr/Permissions conflict\..+?can't create:/,
   'cant dcreate (diagnostic mode)'
);

# 11.5
like(
   $f->_throw(
      'cant dcreate' => {
         dirname => '.',
         parentd => '..',
      }
   ),
   qr/(?sm)^Permissions conflict\.  Can't create directory:/,
   'cant dcreate'
);

# 12
like(
   $f->_throw(
      'make_dir target exists' => {
         dirname  => '.',
         filetype => [ $f->file_type('.') ],
         diag     => '.',
      }
   ),
   qr/make_dir target already exists\./,
   'make_dir target exists (diagnostic mode)'
);

# 12.5
like(
   $f->_throw(
      'make_dir target exists' => {
         dirname  => '.',
         filetype => [ $f->file_type('.') ],
      }
   ),
   qr/(?sm)^make_dir target already exists:/,
   'make_dir target exists'
);

# 13
like(
   $f->_throw(
      'bad open' => {
         mode      => 'illegal mode',
         filename  => __FILE__,
         exception => 'dummy',
         cmd       => 'illegal cmd',
         diag      => 1,
      }
   ),
   qr/can't open this file for.+?illegal mode/,
   'bad open (diagnostic mode)'
);

# 13.5
like(
   $f->_throw(
      'bad open' => {
         mode      => 'illegal mode',
         filename  => __FILE__,
         exception => 'dummy',
         cmd       => 'illegal cmd',
      }
   ),
   qr/(?sm)^Can't open:/,
   'bad open'
);

# 14
like(
   $f->_throw(
      'bad close' => {
         mode      => 'illegal mode',
         filename  => __FILE__,
         exception => 'dummy',
         diag      => 1,
      }
   ),
   qr/couldn't close this file after.+?illegal mode/,
   'bad close (diagnostic mode)'
);

# 14.5
like(
   $f->_throw(
      'bad close' => {
         mode      => 'illegal mode',
         filename  => __FILE__,
         exception => 'dummy',
      }
   ),
   qr/(?sm)^Couldn't close:/,
   'bad close'
);

# 15
like(
   $f->_throw(
      'bad systrunc' => {
         filename  => __FILE__,
         exception => 'dummy',
         diag      => 1,
      }
   ),
   qr/couldn't truncate\(\) on.+?after having/,
   'bad systrunc (diagnostic mode)'
);

# 15.5
like(
   $f->_throw(
      'bad systrunc' => {
         filename  => __FILE__,
         exception => 'dummy',
      }
   ),
   qr/(?sm)^Couldn't truncate\(\) on/,
   'bad systrunc'
);

# 16
like(
   $f->_throw(
      'bad flock' => {
         filename  => __FILE__,
         exception => 'illegal',
         diag      => 1
      }
   ),
   qr/can't get a lock on the file/,
   'bad flock (diagnostic mode)'
);

# 16.5
like(
   $f->_throw(
      'bad flock' => {
         filename  => __FILE__,
         exception => 'illegal',
      }
   ),
   qr/(?sm)^Can't get a lock on the file:/,
   'bad flock'
);

# 17
like( $f->_throw( 'called open on a dir' => { diag => 1, filename => __FILE__ } ),
   qr/can't call open\(\) on this file because it is a directory/,
   'called open on a dir (diagnostic mode)'
);

# 17.5
like( $f->_throw( 'called open on a dir' => { filename => __FILE__ } ),
   qr/(?sm)^Can't call open\(\) on a directory:/,
   'called open on a dir'
);

# 18
like( $f->_throw( 'called opendir on a file' => { diag => 1, filename => __FILE__ } ),
   qr/can't opendir\(\) on this file because it is not a directory/,
   'called opendir on a file (diagnostic mode)'
);

# 18.5
like( $f->_throw( 'called opendir on a file' => { filename => __FILE__ } ),
   qr/(?sm)^Can't opendir\(\) on non-directory:/,
   'called opendir on a file'
);

# 19
like( $f->_throw( 'called mkdir on a file' => { diag => 1, filename => __FILE__ } ),
   qr/can't auto-create a directory for this path name because/,
   'called mkdir on a file (diagnostic mode)'
);

# 19.5
like( $f->_throw( 'called mkdir on a file' => { filename => __FILE__ } ),
   qr/(?sm)^Can't make directory; already exists as a file\./,
   'called mkdir on a file'
);

# 20
like( $f->_throw( 'bad read_limit' => { read_limit => 42, diag => 1 } ),
   qr/Bad call to .+?\:\:read_limit\(\)\.  This method can only be/,
   'bad read_limit (diagnostic mode)'
);

# 20.5
like( $f->_throw( 'bad read_limit' => { read_limit => 42 } ),
   qr/(?sm)^Bad input provided to read_limit\(\)/,
   'bad read_limit'
);

# 21
like(
   $f->_throw(
      'read_limit exceeded' => {
         filename   => __FILE__,
         size       => 'testtesttest',
         read_limit => 42,
         diag       => 1,
      }
   ),
   qr/(?sm)can't load file.+?into memory because its size exceeds/,
   'read_limit exceeded (diagnostic mode)'
);

# 21.5
like(
   $f->_throw(
      'read_limit exceeded' => {
         filename   => __FILE__,
         size       => 'testtesttest',
         read_limit => 42,
      }
   ),
   qr/(?sm)^Stopped reading:.+?Read limit exceeded:/,
   'read_limit exceeded'
);

# 22
like( $f->_throw( 'bad abort_depth' => { diag => 1 } ),
   qr/Bad call to .+?\:\:abort_depth\(\)\.  This method can only be/,
   'bad abort_depth (diagnostic mode)'
);

# 22.5
like( $f->_throw( 'bad abort_depth' => { } ),
   qr/(?sm)^Bad input provided to abort_depth\(\)/,
   'bad abort_depth'
);

# 23
like( $f->_throw( 'abort_depth exceeded' => { diag => 1 } ),
   qr/Recursion limit reached at .+?dives\.  The maximum level of/,
   'abort_depth exceeded (diagnostic mode)'
);

# 23.5
like( $f->_throw( 'abort_depth exceeded' => { } ),
   qr/(?sm)^Recursion limit exceeded at/,
   'abort_depth exceeded'
);

# 24
like(
   $f->_throw(
      'bad opendir' => {
         dirname   => '.',
         exception => 'illegal',
         diag      => 1,
      }
   ),
   qr/can't opendir on directory\:/,
   'bad opendir (diagnostic mode)'
);

# 24.5
like(
   $f->_throw(
      'bad opendir' => {
         dirname   => '.',
         exception => 'illegal',
      }
   ),
   qr/(?sm)^Can't opendir on directory:/,
   'bad opendir'
);

# 25
like(
   $f->_throw(
      'bad make_dir' => {
         dirname   => '.',
         bitmask   => 0777,
         exception => 'illegal',
         meth      => 'anonymous',
         diag      => 1,
      }
   ),
   qr/had a problem with the system while attempting to create/,
   'bad make_dir (diagnostic mode)'
);

# 25.5
like(
   $f->_throw(
      'bad make_dir' => {
         dirname   => '.',
         bitmask   => 0777,
         exception => 'illegal',
         meth      => 'anonymous',
      }
   ),
   qr/(?sm)^Can't create directory:/,
   'bad make_dir'
);

# 26
like(
   $f->_throw(
      'bad chars' => {
         string   => 'illegal characters',
         purpose  => 'testing',
         diag     => 1,
      }
   ),
   qr/(?sm)can't use this string.+?It contains illegal characters\./,
   'bad chars (diagnostic mode)'
);

# 26.5
like(
   $f->_throw(
      'bad chars' => {
         string   => 'illegal characters',
         purpose  => 'testing',
      }
   ),
   qr/(?sm)^String contains illegal characters:/,
   'bad chars'
);

# 27
like( $f->_throw( 'not a filehandle' => { diag => 1, argtype => 'illegal' } ),
   qr/can't unlock file with an invalid file handle reference\:/,
   'not a filehandle (diagnostic mode)'
);

# 27.5
like( $f->_throw( 'not a filehandle' => { argtype => 'illegal' } ),
   qr/(?sm)^Can't unlock file with an invalid file handle reference/,
   'not a filehandle'
);

# 28
like( $f->_throw( 'no input' => { diag => 1, meth => 'anonymous' } ),
   qr/(?sm)can't honor your call to.+?because you didn't provide/,
   'no input (diagnostic mode)'
);

# 28.5
like( $f->_throw( 'no input' => { meth => 'anonymous' } ),
   qr/(?sm)^Call to.+?failed: Required input missing/,
   'no input'
);

# 29
like( $f->_throw( 'plain error' => 'testtesttest', diag => 1 ),
   qr/failed with the following message\:/,
   'plain error (diagnostic mode)'
);

# 29.5
like( $f->_throw( 'plain error' => 'testtesttest' ),
   qr/(?sm)^testtesttest/,
   'plain error'
);

# 30
like( $f->_throw( 'unknown error message' => { diag => 1 } ),
   qr/failed with an invalid error-type designation\./,
   'unknown error message (diagnostic mode)'
);

# 30.5
like( $f->_throw( 'unknown error message' => { } ),
   qr/(?sm)^Failed with an invalid error-type designation\./,
   'unknown error message'
);

# 31
like( $f->_throw( 'empty error' => { diag => 1 } ),
   qr/failed with an empty error-type designation\./,
   'empty error (diagnostic mode)'
);

# 31.5
like( $f->_throw( 'empty error' => { } ),
   qr/(?sm)^Failed with an empty error-type designation\./,
   'empty error'
);

# 32
like( $f->_throw( 'no unicode' => { diag => 1 } ),
   qr/(?sm)can't read\/write with \(binmode => 'utf8'\)/,
   'no unicode support (diagnostic mode)'
);

# 32.5
like( $f->_throw( 'no unicode' => { } ),
   qr/(?sm)^Your version of Perl is not new enough/,
   'no unicode support'
);

# 33
like(
   $f->_throw(
      'bad binmode' => {
         filename => __FILE__,
         meth     => 'anonymous',
         diag     => 1,
      }
   ),
   qr/(?m)^IO discipline conflict/,
   'cant mix syswrite with :utf8 (diagnostic mode)'
);

# 33.5
like( $f->_throw( 'bad binmode' => { } ),
   qr/(?m)^The use of system IO.+?on utf8 file handles is deprecated/,
   'cant mix syswrite with :utf8'
);

exit;
