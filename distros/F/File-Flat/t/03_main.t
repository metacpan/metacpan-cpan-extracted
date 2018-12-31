#!/usr/bin/perl

# Formal testing for File::Flat

use strict;
use File::Spec::Functions ':ALL';
BEGIN {
	$|  = 1;
	$^W = 1;
}

use File::Copy   'copy';
use File::Remove 'remove';
use File::Find   'find';

# If we are root, some things we WANT to fail won't,
# and we'll have to skip some tests.
use vars qw{$root $win32};
BEGIN {
	$root  = ($> == 0) ? 1 : 0;
	$win32 = ($^O eq 'MSWin32') ? 1 : 0;
}

# cygwin permissions are insane, so lets treat everyone like
# root and skip all the relevant tests.
# we ALSO want to skip all the tests (mostly related to canExecute)
# that fail on Win32.
BEGIN {
	if ( $^O eq 'cygwin' ) {
		$root  = 1;
		$win32 = 1;
	}
}

use Test::More tests => 269;

# Set up any needed globals
use vars qw{$loaded $ci $bad};
use vars qw{$content_string @content_array $content_length};
use vars qw{$curdir %f};
BEGIN {
	$loaded = 0;
	$| = 1;
	$content_string = "one\ntwo\nthree\n\n";
	@content_array  = ( 'one', 'two', 'three', '' );
	$content_length = length $content_string;

	# Define all the paths we are going to need in advance
	$curdir = curdir();
	%f = (
		null           => catfile( $curdir, 'null'      ),
		something      => catfile( $curdir, 'something' ),

		rwx            => catfile( $curdir, '0000'   ),
		Rwx            => catfile( $curdir, '0400'   ),
		rWx            => catfile( $curdir, '0200'   ),
		rwX            => catfile( $curdir, '0100'   ),
		RWx            => catfile( $curdir, '0600'   ),
		RwX            => catfile( $curdir, '0500'   ),
		rWX            => catfile( $curdir, '0300'   ),
		RWX            => catfile( $curdir, '0700'   ),
		gooddir        => catdir(  $curdir, 'gooddir' ),
		baddir         => catdir(  $curdir, 'baddir'  ),

		ff_handle      => catfile( $curdir, 't', 'ff_handle'  ),
		ff_binary      => catfile( $curdir, 't', 'ff_binary'  ),
		ff_text        => catfile( $curdir, 't', 'ff_text'    ),
		ff_content     => catfile( $curdir, 't', 'ff_content' ),

		ff_content2    => catfile( $curdir, 'ff_content2'   ),
		a_ff_text3     => catfile( $curdir, 'a', 'ff_text3' ),
		abcde_ff_text3 => catfile( $curdir, 'a', 'b', 'c', 'd', 'e', 'ff_text3' ),
		abdde_ff_text3 => catfile( $curdir, 'a', 'b', 'd', 'd', 'e', 'ff_text3' ),
		abc            => catdir(  $curdir, 'a', 'b', 'c' ),
		abd            => catdir(  $curdir, 'a', 'b', 'd' ),
		a              => catdir(  $curdir, 'a' ),
		b              => catdir(  $curdir, 'b' ),

		moved_1        => catfile( $curdir, 'moved_1' ),
		moved_2        => catfile( $curdir, 'b', 'c', 'd', 'e', 'moved_2' ),		

		write_1        => catfile( $curdir, 'write_1' ),
		write_2        => catfile( $curdir, 'write_2' ),
		write_3        => catfile( $curdir, 'write_3' ),
		write_4        => catfile( $curdir, 'write_4' ),
		write_5        => catfile( $curdir, 'write_5' ),
		write_6        => catfile( $curdir, 'write_6' ),

		over_1         => catfile( $curdir, 'over_1' ),
		over_2         => catfile( $curdir, 'over_2' ),
		over_3         => catfile( $curdir, 'over_3' ),
		over_4         => catfile( $curdir, 'over_4' ),

		append_1       => catfile( $curdir, 'append_1' ),
		append_2       => catfile( $curdir, 'append_2' ),
		append_3       => catfile( $curdir, 'append_3' ),
		append_4       => catfile( $curdir, 'append_4' ),

		size_1         => catfile( $curdir, 'size_1' ),
		size_2         => catfile( $curdir, 'size_2' ),
		size_3         => catfile( $curdir, 'size_3' ),

		trunc_1        => catfile( $curdir, 'trunc_1' ),

		prune          => catdir(  $curdir, 'prunedir' ),
		prune_1        => catdir(  $curdir, 'prunedir', 'single' ),
		prune_2        => catdir(  $curdir, 'prunedir', 'multiple', 'lots', 'of', 'dirs' ),
		prune_2a       => catdir(  $curdir, 'prunedir', 'multiple' ),
		prune_3        => catdir(  $curdir, 'prunedir', 'onlyone', 'thisone' ),
		prune_4        => catdir(  $curdir, 'prunedir', 'onlyone', 'notthis' ),
		prune_4a       => catdir(  $curdir, 'prunedir', 'onlyone' ),
		prune_5        => catdir(  $curdir, 'prunedir', 'onlyone', 'notthis', 'orthis' ),
		
		remove_prune_1 => catfile( $curdir, 'prunedir', 'remove', 'prune_1' ),
		remove_prune_2 => catfile( $curdir, 'prunedir', 'remove', 'prune_2' ),
		remove_prune_3 => catfile( $curdir, 'prunedir', 'remove', 'prune_3' ),
		remove_prune_4 => catfile( $curdir, 'prunedir', 'remove', 'prune_4' ),
		remove_prune_5 => catfile( $curdir, 'prunedir', 'remove', 'prune_5' ),
		remove_prune_6 => catfile( $curdir, 'prunedir', 'remove', 'prune_6' ),
		);

	# Avoid some 'only used once' warnings
	$File::Flat::errstr = $File::Flat::errstr;
	$File::Flat::AUTO_PRUNE = $File::Flat::AUTO_PRUNE;
}		

# Convenience functions to avoid system calls
sub touch_test_file($) {
	# Do the 'touch' part
	my $file = catfile( $curdir, $_[0] );
	open FILE, ">>$file" or return undef;
	close FILE;

	# And now the chmod part
	my $mask = oct($_[0]);
	chmod $mask, $file or return undef;

	1;
}

sub chmod_R($$) {
    my($mask, $dir) = @_;
    chmod $mask, $dir;
    find( sub { chmod $mask, $File::Find::name }, $dir );
}

# Check their perl version, and that modules are installed
ok( $] >= 5.005, "Your perl is new enough" );
use_ok( 'File::Flat' );




# Check for the three files that should already exist
ok( -f $f{ff_text},    'ff_text exists'    );
ok( -f $f{ff_binary},  'ff_binary exists'  );
ok( -f $f{ff_content}, 'ff_content exists' );

# Create the files for the file test section
touch_test_file('0000') or die "Failed to create file we can do anything to";
touch_test_file('0400') or die "Failed to create file we can only read";
touch_test_file('0200') or die "Failed to create file we can only write";
touch_test_file('0100') or die "Failed to create file we can only execute";
touch_test_file('0600') or die "Failed to create file we can read and write";
touch_test_file('0500') or die "Failed to create file we can read and execute";
touch_test_file('0300') or die "Failed to create file we can write and execute";
touch_test_file('0700') or die "Failed to create file we can read, write and execute";

unless ( chmod 0777, $curdir ) {
	die "Failed to set current directory to mode 777";
}
unless ( -e $f{gooddir} ) {
	unless ( mkdir $f{gooddir}, 0755 ) {
		die "Failed to create mode 0755 directory";
	}
}
unless ( -e $f{baddir} ) {
	unless ( mkdir $f{baddir}, 0000 ) {
		die "Failed to create mode 0000 directory";
	}
}

# We are also going to use a file called "./null" to represent
# a file that doesn't exist.



### Test Section 1
# Here we will test all the static methods that are handled directly, and
# not passed on to the object form of the methods.

# Test the error message handling
my $error_message = 'foo';
my $rv = File::Flat->_error( $error_message );
ok( ! defined $rv, "->_error returns undef" );
ok( $File::Flat::errstr eq $error_message, "->_error sets error message" );
ok( File::Flat->errstr eq $error_message, "->errstr retrieves error message" );

# Test the static ->exists method
ok( ! File::Flat->exists( $f{null} ), "Static ->exists doesn't see missing file" );
ok( File::Flat->exists( $f{rwx} ), "Static ->exists sees mode 000 file" );
ok( File::Flat->exists( $f{Rwx} ), "Static ->exists sees mode 400 file" );
ok( File::Flat->exists( $f{RWX} ), "Static ->exists sees mode 700 file" );
ok( File::Flat->exists( $curdir ), "Static ->exists sees . directory" );
ok( File::Flat->exists( $f{baddir} ), "Static ->exists sees mode 000 directory" );

# Test the static ->isaFile method
ok( ! File::Flat->isaFile( $f{null} ), "Static ->isaFile returns false for missing file" );
ok( File::Flat->isaFile( $f{rwx} ), "Static ->isaFile returns true for mode 000 file" );
ok( File::Flat->isaFile( $f{RWX} ), "Static ->isaFile returns true for mode 700 file" );
ok( ! File::Flat->isaFile( $curdir ), "Static ->isaFile returns false for current directory" );
ok( ! File::Flat->isaFile( $f{gooddir} ), "Static ->isaFile returns false for subdirectory" );

# Test the static ->isaDirectory method
ok( ! File::Flat->isaDirectory( $f{null} ), "Static ->isaDirectory returns false for missing directory" );
ok( ! File::Flat->isaDirectory( $f{rwx} ), "Static ->isaDirectory returns false for mode 000 file" );
ok( ! File::Flat->isaDirectory( $f{RWX} ), "Static ->isaDirectory returns false for mode 700 file" );
ok( File::Flat->isaDirectory( $curdir ), "Static ->isaDirectory returns true for current directory" );
ok( File::Flat->isaDirectory( $f{gooddir} ), "Static ->isaDirectory returns true for readable subdirectory" );
ok( File::Flat->isaDirectory( $f{baddir} ), "Static ->isaDirectory return true for unreadable subdirectory" );

# Test the static ->canRead method
ok( ! File::Flat->canRead( $f{null} ), "Static ->canRead returns false for missing file" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canRead( $f{rwx} ), "Static ->canRead returns false for mode 000 file" );
}
ok( File::Flat->canRead( $f{Rwx} ), "Static ->canRead returns true for mode 400 file" );
SKIP: {
	skip "Skipping tests known to fail for root", 2 if $root;
	ok( ! File::Flat->canRead( $f{rWx} ), "Static ->canRead returns false for mode 200 file" );
	ok( ! File::Flat->canRead( $f{rwX} ), "Static ->canRead returns false for mode 100 file" );
}
ok( File::Flat->canRead( $f{RWx} ), "Static ->canRead returns true for mode 500 file" );
ok( File::Flat->canRead( $f{RwX} ), "Static ->canRead returns true for mode 300 file" );
ok( File::Flat->canRead( $f{RWX} ), "Static ->canRead returns true for mode 700 file" );
ok( File::Flat->canRead( $curdir ), "Static ->canRead returns true for current directory" );
ok( File::Flat->canRead( $f{gooddir} ), "Static ->canRead returns true for readable subdirectory" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canRead( $f{baddir} ), "Static ->canRead returns false for unreadable subdirectory" );
}


# Test the static ->canWrite method
ok( File::Flat->canWrite( $f{null} ), "Static ->canWrite returns true for missing, creatable, file" );
SKIP: {
	skip "Skipping tests known to fail for root", 2 if $root;
	ok( ! File::Flat->canWrite( $f{rwx} ), "Static ->canWrite returns false for mode 000 file" );
	ok( ! File::Flat->canWrite( $f{Rwx} ), "Static ->canWrite returns false for mode 400 file" );
}
ok( File::Flat->canWrite( $f{rWx} ), "Static ->canWrite returns true for mode 200 file" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canWrite( $f{rwX} ), "Static ->canWrite returns false for mode 100 file" );
}
ok( File::Flat->canWrite( $f{RWx} ), "Static ->canWrite returns true for mode 500 file" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canWrite( $f{RwX} ), "Static ->canWrite returns false for mode 300 file" );
}
ok( File::Flat->canWrite( $f{RWX} ), "Static ->canWrite returns true for mode 700 file" );
ok( File::Flat->canWrite( $curdir ), "Static ->canWrite returns true for current directory" );
ok( File::Flat->canWrite( $f{gooddir} ), "Static ->canWrite returns true for writable subdirectory" );
SKIP: {
	skip "Skipping tests known to fail for root", 2 if $root;
	ok( ! File::Flat->canWrite( $f{baddir} ), "Static ->canWrite returns false for unwritable subdirectory" );
	ok( ! File::Flat->canWrite( catfile($f{baddir}, 'file') ), "Static ->canWrite returns false for missing, non-creatable file" );
}

# Test the static ->canReadWrite method
ok( ! File::Flat->canReadWrite( $f{null} ), "Static ->canReadWrite returns false for missing file" );
SKIP: {
	skip "Skipping tests known to fail for root", 4 if $root;
	ok( ! File::Flat->canReadWrite( $f{rwx} ), "Static ->canReadWrite returns false for mode 000 file" );
	ok( ! File::Flat->canReadWrite( $f{Rwx} ), "Static ->canReadWrite returns false for mode 400 file" );
	ok( ! File::Flat->canReadWrite( $f{rWx} ), "Static ->canReadWrite returns false for mode 200 file" );
	ok( ! File::Flat->canReadWrite( $f{rwX} ), "Static ->canReadWrite returns false for mode 100 file" );
}
ok( File::Flat->canReadWrite( $f{RWx} ), "Static ->canReadWrite returns true for mode 500 file" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canReadWrite( $f{RwX} ), "Static ->canReadWrite returns false for mode 300 file" );
}
ok( File::Flat->canReadWrite( $f{RWX} ), "Static ->canReadWrite returns true for mode 700 file" );
ok( File::Flat->canReadWrite( $curdir ), "Static ->canReadWrite returns true for current directory" );
ok( File::Flat->canReadWrite( $f{gooddir} ), "Static ->canReadWrite returns true for readwritable subdirectory" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canReadWrite( $f{baddir} ), "Static ->canReadWrite returns false for unreadwritable subdirectory" );
}

# Test the static ->canExecute method
SKIP: {
	skip( "Skipping tests known to falsely fail on Win32", 11 ) if $win32;

	ok( ! File::Flat->canExecute( $f{null} ), "Static ->canExecute returns false for missing file" );
	ok( ! File::Flat->canExecute( $f{rwx} ), "Static ->canExecute returns false for mode 000 file" );
	ok( ! File::Flat->canExecute( $f{Rwx} ), "Static ->canExecute returns false for mode 400 file" );
	ok( ! File::Flat->canExecute( $f{rWx} ), "Static ->canExecute returns false for mode 200 file" );
	ok( File::Flat->canExecute( $f{rwX} ), "Static ->canExecute returns true for mode 100 file" );
	ok( ! File::Flat->canExecute( $f{RWx} ), "Static ->canExecute returns false for mode 500 file" );
	ok( File::Flat->canExecute( $f{RwX} ), "Static ->canExecute returns true for mode 300 file" );
	ok( File::Flat->canExecute( $f{RWX} ), "Static ->canExecute returns true for mode 700 file" );
	ok( File::Flat->canExecute( $curdir ), "Static ->canExecute returns true for current directory" );
	ok( File::Flat->canExecute( $f{gooddir} ), "Static ->canExecute returns true for executable subdirectory" );

	skip( "Skipping tests known to falsely fail for root", 1 ) if $root;
	ok( ! File::Flat->canExecute( $f{baddir} ), "Static ->canExecute returns false for unexecutable subdirectory" );
}

# Test the static ->canOpen method
ok( ! File::Flat->canOpen( $f{null} ), "Static ->canOpen returns false for missing file" );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! File::Flat->canOpen( $f{rwx} ), "Static ->canOpen returns false for mode 000 file" );
}
ok( File::Flat->canOpen( $f{Rwx} ), "Static ->canOpen returns true for mode 400 file" );
SKIP: {
	skip "Skipping tests known to fail for root", 2 if $root;
	ok( ! File::Flat->canOpen( $f{rWx} ), "Static ->canOpen returns false for mode 200 file" );
	ok( ! File::Flat->canOpen( $f{rwX} ), "Static ->canOpen returns false for mode 100 file" );
}
ok( File::Flat->canOpen( $f{RWx} ), "Static ->canOpen returns true for mode 500 file" );
ok( File::Flat->canOpen( $f{RwX} ), "Static ->canOpen returns true for mode 300 file" );
ok( File::Flat->canOpen( $f{RWX} ), "Static ->canOpen returns true for mode 700 file" );
ok( ! File::Flat->canOpen( $curdir ), "Static ->canOpen returns false for current directory" );
ok( ! File::Flat->canOpen( $f{gooddir} ), "Static ->canOpen returns false for readable subdirectory" );
ok( ! File::Flat->canOpen( $f{baddir} ), "Static ->canOpen returns false for unreadable subdirectory" );

# Test the existence of normal and/or binary files
ok( ! File::Flat->isText( $f{null} ), "Static ->isText returns false for missing file" );
ok( ! File::Flat->isText( $f{ff_binary} ), "Static ->isText returns false for binary file" );
ok( File::Flat->isText( $f{ff_text} ), "Static ->isText returns true for text file" );
ok( ! File::Flat->isText( $f{gooddir} ), "Static ->isText returns false for good subdirectory" );
ok( ! File::Flat->isText( $f{baddir} ), "Static ->isText returns false for bad subdirectory" );
ok( ! File::Flat->isBinary( $f{null} ), "Static ->isBinary returns false for missing file" );
ok( File::Flat->isBinary( $f{ff_binary} ), "Static ->isBinary returns true for binary file" );
ok( ! File::Flat->isBinary( $f{ff_text} ), "Static ->isBinary returns false for text file" );
ok( ! File::Flat->isBinary( $f{gooddir} ), "Static ->isBinary return false for good subdirectory" );
ok( ! File::Flat->isBinary( $f{baddir} ), "Static ->isBinary returns false for bad subdirectory" );

my %handle = ();

# Do open handle methods return false for bad values
$handle{generic} = File::Flat->open( $f{null} );
$handle{readhandle} = File::Flat->open( $f{null} );
$handle{writehandle} = File::Flat->open( $f{null} );
$handle{appendhandle} = File::Flat->open( $f{null} );
$handle{readwritehandle} = File::Flat->open( $f{null} );
ok( ! defined $handle{generic}, "Static ->open call returns undef on bad file name" );
ok( ! defined $handle{readhandle}, "Static ->getReadHandle returns undef on bad file name" );
ok( ! defined $handle{writehandle}, "Static ->getWriteHandle returns undef on bad file name" );
ok( ! defined $handle{appendhandle}, "Static ->getAppendHandle returns undef on bad file name" );
ok( ! defined $handle{readwritehandle}, "Static ->getReadWriteHandle returns undef on bad file name" );

# Do the open methods at least return a file handle
copy( $f{ff_text}, $f{ff_handle} ) or die "Failed to copy file in preperation for test";
$handle{generic}         = File::Flat->open( $f{ff_handle} );
$handle{readhandle}      = File::Flat->getReadHandle( $f{ff_handle} );
$handle{writehandle}     = File::Flat->getWriteHandle( $f{ff_handle} );
$handle{appendhandle}    = File::Flat->getAppendHandle( $f{ff_handle} );
$handle{readwritehandle} = File::Flat->getReadWriteHandle( $f{ff_handle} );
isa_ok( $handle{generic},         'IO::File' ); # Static ->open call returns IO::File object
isa_ok( $handle{readhandle},      'IO::File' ); # Static ->getReadHandle returns IO::File object
isa_ok( $handle{writehandle},     'IO::File' ); # Static ->getWriteHandle returns IO::File object
isa_ok( $handle{appendhandle},    'IO::File' ); # Static ->getAppendHandle returns IO::File object
isa_ok( $handle{readwritehandle}, 'IO::File' ); # Static ->getReadWriteHandle returns IO::File object






# Test the static ->copy method
ok( ! defined File::Flat->copy(), '->copy() returns error' );
ok( ! defined File::Flat->copy( $f{ff_content} ), '->copy( file ) returns error' );

$rv = File::Flat->copy( $f{ff_content}, $f{ff_content2} );
ok( $rv, "Static ->copy returns true correctly for same directory copy" );
ok( -e $f{ff_content2}, "Static ->copy actually created the file for same directory copy" );
ok( check_content_file( $f{ff_content2} ), "Static ->copy copies the file without breaking it" );

$rv = File::Flat->copy( $f{ff_text}, $f{a_ff_text3} );
ok( $rv, "Static ->copy returns true correctly for single sub-directory copy" );
ok( -e $f{a_ff_text3}, "Static ->copy actually created the file for single sub-directory copy" );

$rv = File::Flat->copy( $f{ff_text}, $f{abcde_ff_text3} );
ok( $rv, "Static ->copy returns true correctly for multiple sub-directory copy" );
ok( -e $f{abcde_ff_text3}, "Static ->copy actually created the file for multiple sub-directory copy" );

$rv = File::Flat->copy( $f{null}, $f{something} );
ok( ! $rv, "Static ->copy return undef when file does not exist" );

# Directory copying
$rv = File::Flat->copy( $f{abc}, $f{abd} );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( $rv, '->copy( dir, dir ) returns true' );
}
ok( -d $f{abd}, '->copy( dir, dir ): New dir exists' );
ok( -f $f{abdde_ff_text3}, '->copy( dir, dir ): Files within directory were copied' );

# Test the static ->move method
$rv = File::Flat->move( $f{abcde_ff_text3}, $f{moved_1} );
ok( $rv, "Static ->move for move to existing directory returns true " );
ok( ! -e $f{abcde_ff_text3}, "Static ->move for move to existing directory actually removes the old file" );
ok( -e $f{moved_1}, "Static ->move for move to existing directory actually creates the new file" );

$rv = File::Flat->move( $f{ff_content2}, $f{moved_2} );
ok( $rv, "Static ->move for move to new directory returns true " );
ok( ! -e $f{ff_content2}, "Static ->move for move to new directory actually removes the old file" );
ok( -e $f{moved_2}, "Static ->move for move to new directory actually creates the new file" );
ok( check_content_file( $f{moved_2} ), "Static ->move moved the file without breaking it" );






# Test the static ->slurp method
ok( check_content_file( $f{ff_content} ), "Content tester works" );
my $content = File::Flat->slurp();
ok( ! defined $content, "Static ->slurp returns error on no arguments" );
$content = File::Flat->slurp( $f{null} );
ok( ! defined $content, "Static ->slurp returns error on bad file" );
$content = File::Flat->slurp( $f{ff_content} );
ok( defined $content, "Static ->slurp returns defined" );
ok( defined $content, "Static ->slurp returns something" );
ok( UNIVERSAL::isa( $content, 'SCALAR' ), "Static ->slurp returns a scalar reference" );
ok( length $$content, "Static ->slurp returns content" );
ok( $$content eq $content_string, "Static ->slurp returns the correct file contents" );

# Test the static ->read
$content = File::Flat->read();
ok( ! defined $content, "Static ->read returns error on no arguments" );
$content = File::Flat->read( $f{null} );
ok( ! defined $content, "Static ->read returns error on bad file" );
$content = File::Flat->read( $f{ff_content} );
ok( defined $content, "Static ->read doesn't error on good file" );
ok( $content, "Static ->read returns true on good file" );
ok( ref $content, "Static ->read returns a reference on good file" );
ok( UNIVERSAL::isa( $content, 'ARRAY' ), "Static ->read returns an array ref on good file" );
ok( scalar @$content == 4, "Static ->read returns the correct length of data" );
my $matches = (
	$content->[0] eq 'one'
	and $content->[1] eq 'two'
	and $content->[2] eq 'three'
	and $content->[3] eq ''
	) ? 1 : 0;
ok( $matches, "Static ->read returns the expected content" );

# And again in an array context
my @content = File::Flat->read();
ok( ! scalar @content, "Static ->read (array context) returns error on no arguments" );
@content = File::Flat->read( $f{null} );
ok( ! scalar @content, "Static ->read (array context) returns error on bad file" );
@content = File::Flat->read( $f{ff_content} );
ok( scalar @content, "Static ->read (array context) doesn't error on good file" );
ok( scalar @content == 4, "Static ->read (array context) returns the correct length of data" );
$matches = (
	$content[0] eq 'one'
	and $content[1] eq 'two'
	and $content[2] eq 'three'
	and $content[3] eq ''
	) ? 1 : 0;
ok( $matches, "Static ->read (array context) returns the expected content" );





# Test the many and varies write() options.
ok( ! File::Flat->write(), "->write() fails correctly" );
ok( ! File::Flat->write( $f{write_1} ), "->write( file ) fails correctly" );
ok( ! -e $f{write_1}, "->write( file ) doesn't actually create a file" );

$rv = File::Flat->write( $f{write_1}, $content_string );
ok( $rv, "->File::Flat->write( file, string ) returns true" );
ok( -e $f{write_1}, "->write( file, string ) actually creates a file" );
ok( check_content_file( $f{write_1} ), "->write( file, string ) writes the correct content" );

$rv = File::Flat->write( $f{write_2}, $content_string );
ok( $rv, "->File::Flat->write( file, string_ref ) returns true" );
ok( -e $f{write_2}, "->write( file, string_ref ) actually creates a file" );
ok( check_content_file( $f{write_2} ), "->write( file, string_ref ) writes the correct content" );

$rv = File::Flat->write( $f{write_3}, \@content_array );
ok( $rv, "->write( file, array_ref ) returns true" );
ok( -e $f{write_3}, "->write( file, array_ref ) actually creates a file" );
ok( check_content_file( $f{write_3} ), "->write( file, array_ref ) writes the correct content" );

# Repeat with a handle first argument
my $handle = File::Flat->getWriteHandle( $f{write_4} );
ok( ! File::Flat->write( $handle ), "->write( handle ) fails correctly" );
ok( UNIVERSAL::isa( $handle, 'IO::Handle' ), 'Got write handle for test' );
$rv = File::Flat->write( $handle, $content_string );
$handle->close();
ok( $rv, "->write( handle, string ) returns true" );
ok( -e $f{write_4}, "->write( handle, string ) actually creates a file" );
ok( check_content_file( $f{write_1} ), "->write( handle, string ) writes the correct content" );

$handle = File::Flat->getWriteHandle( $f{write_5} );
ok( UNIVERSAL::isa( $handle, 'IO::Handle' ), 'Got write handle for test' );
$rv = File::Flat->write( $handle, $content_string );
$handle->close();
ok( $rv, "->File::Flat->write( handle, string_ref ) returns true" );
ok( -e $f{write_5}, "->write( handle, string_ref ) actually creates a file" );
ok( check_content_file( $f{write_5} ), "->write( handle, string_ref ) writes the correct content" );

$handle = File::Flat->getWriteHandle( $f{write_6} );
ok( UNIVERSAL::isa( $handle, 'IO::Handle' ), 'Got write handle for test' );
$rv = File::Flat->write( $handle, \@content_array );
$handle->close();
ok( $rv, "->File::Flat->write( handle, array_ref ) returns true" );
ok( -e $f{write_6}, "->write( handle, array_ref ) actually creates a file" );
ok( check_content_file( $f{write_6} ), "->write( handle, array_ref ) writes the correct content" );






# Check the ->overwrite method
ok( ! File::Flat->overwrite(), "->overwrite() fails correctly" );
ok( ! File::Flat->overwrite( $f{over_1} ), "->overwrite( file ) fails correctly" );
ok( ! -e $f{over_1}, "->overwrite( file ) doesn't actually create a file" );

$rv = File::Flat->overwrite( $f{over_1}, $content_string );
ok( $rv, "->File::Flat->overwrite( file, string ) returns true" );
ok( -e $f{over_1}, "->overwrite( file, string ) actually creates a file" );
ok( check_content_file( $f{over_1} ), "->overwrite( file, string ) writes the correct content" );

$rv = File::Flat->overwrite( $f{over_2}, $content_string );
ok( $rv, "->File::Flat->overwrite( file, string_ref ) returns true" );
ok( -e $f{over_2}, "->overwrite( file, string_ref ) actually creates a file" );
ok( check_content_file( $f{over_2} ), "->overwrite( file, string_ref ) writes the correct content" );

$rv = File::Flat->overwrite( $f{over_3}, \@content_array );
ok( $rv, "->overwrite( file, array_ref ) returns true" );
ok( -e $f{over_3}, "->overwrite( file, array_ref ) actually creates a file" );
ok( check_content_file( $f{over_3} ), "->overwrite( file, array_ref ) writes the correct content" );

# Check actually overwriting a file
ok ( File::Flat->copy( $f{ff_text}, $f{over_4} ), "Preparing for overwrite test" );
$rv = File::Flat->overwrite( $f{over_4}, \$content_string );
ok( $rv, "->overwrite( file, array_ref ) returns true" );
ok( -e $f{over_4}, "->overwrite( file, array_ref ) actually creates a file" );
ok( check_content_file( $f{over_4} ), "->overwrite( file, array_ref ) writes the correct content" );





# Check the basics of the ->remove method
ok( ! File::Flat->remove(), "->remove() correctly return an error" );
ok( ! File::Flat->remove( $f{null} ), "->remove( file ) returns an error for a nonexistant file" );
ok( File::Flat->remove( $f{over_4} ), "->remove( file ) returns true for existing file" );
ok( ! -e $f{over_4}, "->remove( file ) actually removes the file" );
ok( File::Flat->remove( $f{a} ), "->remove( directory ) returns true for existing directory" );
ok( ! -e $f{a}, "->remove( directory ) actually removes the directory" );





# Check the append method
ok( ! File::Flat->append(), "->append() correctly returns an error" );
ok( ! File::Flat->append( $f{append_1} ), "->append( file ) correctly returns an error" );
ok( ! -e $f{append_1}, "->append( file ) doesn't actually create a file" );

$rv = File::Flat->append( $f{append_1}, $content_string );
ok( $rv, "->File::Flat->append( file, string ) returns true" );
ok( -e $f{append_1}, "->append( file, string ) actually creates a file" );
ok( check_content_file( $f{append_1} ), "->append( file, string ) writes the correct content" );

$rv = File::Flat->append( $f{append_2}, $content_string );
ok( $rv, "->File::Flat->append( file, string_ref ) returns true" );
ok( -e $f{append_2}, "->append( file, string_ref ) actually creates a file" );
ok( check_content_file( $f{append_2} ), "->append( file, string_ref ) writes the correct content" );

$rv = File::Flat->append( $f{append_3}, \@content_array );
ok( $rv, "->append( file, array_ref ) returns true" );
ok( -e $f{append_3}, "->append( file, array_ref ) actually creates a file" );
ok( check_content_file( $f{append_3} ), "->append( file, array_ref ) writes the correct content" );

# Now let's try an actual append
ok( File::Flat->append( $f{append_4}, "one\ntwo\n" ), "Preparing for real append" );
$rv = File::Flat->append( $f{append_4}, "three\n\n" );
ok( $rv, "->append( file, array_ref ) for an actual append returns true" );
ok( -e $f{append_4}, "->append( file, array_ref ): File still exists" );
ok( check_content_file( $f{append_4} ), "->append( file, array_ref ) results in the correct file contents" );





# Test the ->fileSize method
ok( File::Flat->write( $f{size_1}, 'abcdefg' )
	&& File::Flat->write( $f{size_2}, join '', ( 'd' x 100000 ) )
	&& File::Flat->write( $f{size_3}, '' ),
	"Preparing for file size tests"
	);
ok( ! defined File::Flat->fileSize(), "->fileSize() correctly returns error" );
ok( ! defined File::Flat->fileSize( $f{null} ), '->fileSize( file ) returns error for nonexistant file' );
ok( ! defined File::Flat->fileSize( $f{a} ), '->fileSize( directory ) returns error' );
$rv = File::Flat->fileSize( $f{size_1} );
ok( defined $rv, "->fileSize( file ) returns true for small file" );
ok( $rv == 7, "->fileSize( file ) returns the correct size for small file" );
$rv = File::Flat->fileSize( $f{size_2} );
ok( defined $rv, "->fileSize( file ) returns true for big file" );
ok( $rv == 100000, "->fileSize( file ) returns the correct size for big file" );
$rv = File::Flat->fileSize( $f{size_3} );
ok( defined $rv, "->fileSize( file ) returns true for empty file" );
ok( $rv == 0, "->fileSize( file ) returns the correct size for empty file" );







# Test the ->truncate method. Use the append files
ok( ! defined File::Flat->truncate(), '->truncate() correctly returns error' );
SKIP: {
	skip "Skipping tests known to fail for root", 1 if $root;
	ok( ! defined File::Flat->truncate( $f{rwx} ), '->truncate( file ) returns error when no permissions' );
}
ok( ! defined File::Flat->truncate( './b' ), '->truncate( directory ) returns error' );
$rv = File::Flat->truncate( $f{trunc_1} );
ok( $rv, '->truncate( file ) returns true for non-existant file' );
ok( -e $f{trunc_1}, '->truncate( file ) creates new file' );
ok( File::Flat->fileSize( $f{trunc_1} ) == 0, '->truncate( file ) creates file of 0 bytes' );

$rv = File::Flat->truncate( $f{append_1} );
ok( $rv, '->truncate( file ) returns true for existing file' );
ok( -e $f{append_1}, '->truncate( file ): File still exists' );
ok( File::Flat->fileSize( $f{append_1} ) == 0, '->truncate( file ) truncates to 0 bytes' );

$rv = File::Flat->truncate( $f{append_2}, 0 );
ok( $rv, '->truncate( file, 0 ) returns true for existing file' );
ok( -e $f{append_2}, '->truncate( file, 0 ): File still exists' );
ok( File::Flat->fileSize( $f{append_2} ) == 0, '->truncate( file, 0 ) truncates to 0 bytes' );

$rv = File::Flat->truncate( $f{append_3}, 5 );
ok( $rv, '->truncate( file, 5 ) returns true for existing file' );
ok( -e $f{append_3}, '->truncate( file, 5 ): File still exists' );
ok( File::Flat->fileSize( $f{append_3} ) == 5, '->truncate( file, 5 ) truncates to 5 bytes' );





#####################################################################
# Test the prune method

# Create the test directories
foreach ( 1 .. 5 ) {
	my $directory = $f{"prune_$_"};
	ok( File::Flat->makeDirectory( $directory ), "Created test directory '$directory'" );
}

# Prune beneath the single dir
$rv = File::Flat->prune( catfile($f{prune_1}, 'file.txt') );
ok( $rv,              '->prune(single) returned true' );
ok( ! -e $f{prune_1}, '->prune(single) removed the single' );
ok(   -d $f{prune},   '->prune(single) didn\'t remove the master prunedir' );

# Prune beneath the multiple dir
$rv = File::Flat->prune( catfile($f{prune_2}, 'here') );
ok( $rv,               '->prune(multiple) returned true' );
ok( ! -e $f{prune_2},  '->prune(multiple) removed the top dir' );
ok( ! -e $f{prune_2a}, '->prune(multiple) removed all the dirs' );
ok(   -d $f{prune},    '->prune(multiple) didn\'t remove the master prunedir' );

# Prune stops correctly
$rv = File::Flat->prune( catfile($f{prune_3}, 'foo') );
ok( $rv,              '->prune(branched) returned true' );
ok( ! -e $f{prune_3}, '->prune(branched) removed the correct directory' );
ok(   -d $f{prune_4}, '->prune(branched) doesn\'t remove side directory' );
ok(   -d $f{prune},   '->prune(branched) didn\'t remove the master prunedir' );

# Don't prune anything
$rv = File::Flat->prune( catfile($f{prune_4a}, 'blah') );
ok( $rv,            '->prune(nothing) returned true' );
ok( -d $f{prune_4}, '->prune(nothing) doesn\'t remove side directory' );
ok( -d $f{prune},   '->prune(nothing) didn\'t remove the master prunedir' );

# Error when used as delete
$rv = File::Flat->prune( $f{prune_5} );
is( $rv, undef, '->prune(existing) returns an error' );
ok( File::Flat->errstr, '->prune(existing) sets ->errstr' );

# Test remove, with the prune option.

# Start by copying in some files to work with.
# We'll use the last of the untouched append files
foreach ( 1 .. 6 ) {
	ok( File::Flat->copy( $f{append_4}, catdir( $f{"remove_prune_$_"}, 'file' ) ), 'Copied in delete/prune test file' );
}

# By default, AUTOPRUNE is off and we don't tell ->remove to prune
ok( File::Flat->remove( catdir( $f{remove_prune_1}, 'file' ) ), '->remove(default) returns true' );
ok( -d $f{remove_prune_1}, '->remove(default) leaves dir intact' );

# Try with AUTOPRUNE on
AUTOPRUNE: {
	local $File::Flat::AUTO_PRUNE = 1;
	ok( File::Flat->remove( catdir( $f{remove_prune_2}, 'file' ) ), '->remove(AUTO_PRUNE) returns true' );
	ok( ! -e $f{remove_prune_2}, '->remove(AUTO_PRUNE) prunes directory' );
}

# By default, AUTOPRUNE is off
ok( File::Flat->remove( catdir( $f{remove_prune_3}, 'file' ) ), '->remove(default) returns true' );
ok( -d $f{remove_prune_3}, '->remove(default) leaves dir intact (AUTO_PRUNE used locally localises correctly)' );

# Tell ->remove to prune
ok( File::Flat->remove( catdir( $f{remove_prune_4}, 'file' ), 1 ), '->remove(prune) returns true' );
ok( ! -e $f{remove_prune_4}, '->remove(AUTO_PRUNE) prunes directory' );

# Tell ->remove explicitly not to prune
ok( File::Flat->remove( catdir( $f{remove_prune_5}, 'file' ), '' ), '->remove(noprune) returns true' );
ok( -d $f{remove_prune_5}, '->remove(noprune) leaves dir intact' );

# Make sure there's no warning with undef false value
ok( File::Flat->remove( catdir( $f{remove_prune_6}, 'file' ), undef ), '->remove(noprune) returns true' );
ok( -d $f{remove_prune_6}, '->remove(noprune) leaves dir intact' );

exit();





sub check_content_file {
	my $file = shift;
	return undef unless -e $file;
	return undef unless -r $file;

	open( FILE, $file ) or return undef;
	@content = <FILE>;
	chomp @content;
	close FILE;

	return undef unless scalar @content == 4;
	return undef unless $content[0] eq 'one';
	return undef unless $content[1] eq 'two';
	return undef unless $content[2] eq 'three';
	return undef unless $content[3] eq '';

	return 1;
}

END {
	# When we finish there are going to be some pretty fucked up files.
	# Make them less so.
	foreach my $clean1 ( qw{
		0000 0100 0200 0300 0400 0500 0600 0700
		ff_handle moved_1
		write_1 write_2 write_3 write_4 write_5 write_6
		over_1 over_2 over_3 over_4
		append_1 append_2 append_3 append_4
		size_1 size_2 size_3
		trunc_1
	} ) {
		if ( -e $clean1 ) {
			chmod 0600, $clean1;
			unlink $clean1;
			next;
		}
		my $clean2 = catfile( 't', $clean1 );
		if ( -e $clean2 ) {
			chmod 0600, $clean2;
			unlink $clean2;
			next;
		}
	}

	foreach my $dir ( qw{a b baddir gooddir} ) {
		next unless -e $f{$dir};
		chmod_R( 0700, $f{$dir} );
		remove \1, $f{$dir};
	}

	remove \1, $f{prune};
}
