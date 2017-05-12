
use strict;
use warnings;

# This test structure is completely procedural and serial.  I'm sorry, it's
# a little ugly.  It makes sense if you just read it though, one open/close
# at a time.  We're just testing Perl IO and C IO on filehandles from the
# open_handle() method.
#
# Also, because the C IO ops are not as portable as Perl IO, this is a
# developer-only release test so we can avoid bad test reports for platforms
# that have troublesome C libraries, which isn't our fault.

use Test::More;

if ( $ENV{RELEASE_TESTING} || $ENV{AUTHOR_TESTING} || $ENV{AUTHOR_TESTS} )
{                            # the tests in this file have a higher probability
   plan tests => 39;         # of failing in the wild, and so are reserved for
                             # the author/maintainers as release tests
   CORE::eval # hide the eval...
   '
use Test::NoWarnings;
   '; # ...from dist parsers
}
else
{
   plan skip_all => 'these tests are for release candidate testing';
}

use File::Temp qw( tempfile );

use lib './lib';
use File::Util qw( NL );

# one recognized instantiation setting
my $ftl = File::Util->new( );

my ( $tempfh, $tempfile ) = tempfile;

close $tempfh;

BEGIN { ++$| }

################################################################################
# TEST PERL IO (READ/WRITE/APPEND)
################################################################################

# ------------------------------------
# Perl IO (write)
# ------------------------------------

my $fh = $ftl->open_handle( $tempfile => 'write' );

is ref $fh, 'GLOB', 'got file handle for write';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for write';

print $fh 'dangerian' . NL . 'jspice' . NL . 'codizzle' . NL;

close $fh;

is fileno( $fh ), undef, 'closed file handle after write';

undef $fh;

# ------------------------------------
# Perl IO (read)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'read' );

is ref $fh, 'GLOB', 'got file handle for read';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for read';

my @lines = <$fh>;

chomp for @lines;

is_deeply
   \@lines,
   [ qw( dangerian jspice codizzle ) ],
   'read the lines just previously written';

close $fh;

is fileno( $fh ), undef, 'closed file handle after read';

undef $fh;
undef @lines;

# ------------------------------------
# Perl IO (append)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'append' );

is ref $fh, 'GLOB', 'got file handle for append';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for append';

print $fh 'redbeard' . NL . 'tbone' . NL;

close $fh;

is fileno( $fh ), undef, 'closed file handle after append';

undef $fh;

# ------------------------------------
# Perl IO (read)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile ); # implicit mode => 'read'

is ref $fh, 'GLOB', 'got file handle for read using implicit read mode';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for read';

@lines = <$fh>;

chomp for @lines;

is_deeply
   \@lines,
   [ qw( dangerian jspice codizzle redbeard tbone ) ],
   'read the lines just previously appended';

close $fh;

is fileno( $fh ), undef, 'closed file handle after read';

undef $fh;
undef @lines;

################################################################################
# TEST C IO (SYSREAD/SYSWRITE/ETC)
################################################################################
use Fcntl qw( SEEK_SET SEEK_CUR SEEK_END );

# ------------------------------------
# System IO (sysread)
# ------------------------------------

$fh = $ftl->open_handle(  # make sure old-school still works
   file => $tempfile,     # otherwise, this "null" test would
   mode => 'read',        # make everything else fail when it die()d
   { use_sysopen => 1 }
);

$fh = $ftl->open_handle( $tempfile => 'read' => { use_sysopen => 1 } );

is ref $fh, 'GLOB', 'got file handle for sysread';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for sysread';

my ( $buffer, $string );

$string .= $buffer while sysread( $fh, $buffer, 4096 );

is_deeply
   [ split( /\r|\n|\r\n/, $string ) ],
   [ qw( dangerian jspice codizzle redbeard tbone ) ],
   'SYS-read the lines just previously PERLIO-appended';

close $fh;

is fileno( $fh ), undef, 'closed file handle after sysread';

undef $fh;
undef $buffer;
undef $string;

unlink $tempfile or die $!;

is -e $tempfile,
   undef,
   'removed tempfile in preparation for syswrite (rwcreate)';

# ------------------------------------
# System IO (rwcreate)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'rwcreate' => { use_sysopen => 1 } );

is ref $fh, 'GLOB', 'got file handle for syswrite (rwcreate)';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for rwcreate';

syswrite $fh, 'llama';
sysseek $fh, 0, 0;

$string .= $buffer while sysread( $fh, $buffer, 4096 );

is $string,
   'llama',
   'string is a llama (I just sysread what I just syswrote (rwcreate))';

close $fh;

is fileno( $fh ), undef, 'closed file handle after rwcreate';

undef $fh;
undef $buffer;
undef $string;

is -e $tempfile, 1, 'successfully rwcreate-ed tempfile with syswrite';

# ------------------------------------
# System IO (rwupdate)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'rwupdate' => { use_sysopen => 1 } );

is ref $fh, 'GLOB', 'got file handle for syswrite (rwupdate)';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for rwupdate';

syswrite $fh, 'LL';
sysseek $fh, 0, 0;

$string .= $buffer while sysread( $fh, $buffer, 4096 );

is $string,
   'LLama',
   'string is a LLama (I just sysread what I just syswrote (rwupdate))';

close $fh;

is fileno( $fh ), undef, 'closed file handle after syswrite (rwupdate)';

undef $fh;
undef $buffer;
undef $string;

# ------------------------------------
# System IO (rwappend)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'rwappend' => { use_sysopen => 1 } );

is ref $fh, 'GLOB', 'got file handle for syswrite (rwappend)';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for rwappend';

syswrite $fh, 's are seldom thirsty';
sysseek $fh, 0, 0;

$string .= $buffer while sysread( $fh, $buffer, 4096 );

is $string,
   'LLamas are seldom thirsty',
   'LLamas are seldom thirsty (I just sysread what I just syswrote (rwappend))';

close $fh;

is fileno( $fh ), undef, 'closed file handle after syswrite (rwupdate)';

undef $fh;
undef $buffer;
undef $string;

# ------------------------------------
# System IO (rwclobber)
# ------------------------------------

$fh = $ftl->open_handle( $tempfile => 'rwclobber' => { use_sysopen => 1 } );

is ref $fh, 'GLOB', 'got file handle for syswrite (rwclobber)';
is !!fileno( $fh ), 1, 'file handle open to a file descriptor for rwclobber';

syswrite $fh, 'Han shot first!';
sysseek $fh, 0, 0;

$string .= $buffer while sysread( $fh, $buffer, 4096 );

is $string,
   'Han shot first!',
   'Han shot first! (I just sysread what I just syswrote (rwclobber))';

close $fh;

is fileno( $fh ), undef, 'closed file handle after syswrite (rwclobber)';

undef $fh;
undef $buffer;
undef $string;

################################################################################
# TEST SOME FAILURE SCENARIOS
################################################################################

$fh = $ftl->open_handle( undef, { onfail => 'zero' } );

is $fh, 0, 'failed open with onfail => 0 handler returns 0';

$fh = $ftl->open_handle( undef, { onfail => 'undefined' } );

is $fh, undef, 'failed open with onfail => undefined handler returns undef';

exit;

