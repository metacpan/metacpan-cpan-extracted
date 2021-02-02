#! perl

# Test non Latin filenames from file.

use strict;
use warnings;
use Test::More tests => 4;
use utf8;
use Encode qw(encode_utf8 encode);
use File::LoadLines;
binmode( STDERR, ':utf8' );

# The file.
my $filename = "testň.dat";
# And its contents.
my $reftext = "Hi There!";

-d "t" && chdir "t";

# We explicitly create the file, since this name is not portable and
# treated badly by archivers and unpackers.

if ( $^O =~ /mswin/i ) {
    require Win32API::File;
    my $fn = encode('UTF-16LE', "$filename").chr(0).chr(0);

    # Sometimes CREATE_ALWAYS barfs.
    Win32API::File::DeleteFileW($fn);

    # Create the file.
    my $fh = Win32API::File::CreateFileW
      ( $fn, Win32API::File::GENERIC_WRITE(), 0, [],
	Win32API::File::CREATE_ALWAYS(), 0, []);
    die("$filename: $^E (Win32)\n") if $^E;

    # Get handle and store contents.
    Win32API::File::OsFHandleOpen( 'FILE', $fh, "w")
	or die("$filename: $!\n");
    print FILE ( $reftext, "\n" );
    close(FILE);
}
else {
    open( my $fh, '>', encode_utf8($filename) );
    die("$filename: $!\n") unless $fh;
    print $fh ( $reftext, "\n" );
    close($fh);
}

my $options = {};
my @lines = loadlines( "testW.dat", $options );
is( $options->{encoding}, "UTF-8", "returned encoding" );
is( $lines[0], $filename, "correct data" );

$options = {};
@lines = loadlines( encode_utf8($lines[0]), $options );
is( $options->{encoding}, "ASCII", "returned encoding 2" );
is( $lines[0], $reftext, "correct data 2" );
