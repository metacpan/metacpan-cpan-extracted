#
# $Id: 07_zip.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;

use File::Path;
use Archive::Zip;

BEGIN {
    chdir 't' if -d 't';
}

mkdir 'compress' unless -d 'compress';
chdir 'compress' or die;

END {
    chdir("..") or die;
    rmtree 'compress' unless @ARGV;
}

use_ok('IO::File::CompressOnClose::Zip');

# open a file for write
my $io;
lives_ok {
    $io = IO::File::CompressOnClose::Zip->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# close the file
$io->close;
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.zip", "file 'foo.zip' exists");
ok( -s "foo.zip", "file 'foo.zip' has non-zero size");

# try to open the archive using Compress::Zlib
my $zip;
lives_ok {
   $zip = Archive::Zip->new;
   $zip->read("foo.zip");
} 'open archive as zip file';
my $test;
if( my $member = $zip->memberNamed("foo") ) {
    $test = $member->contents;
}
is( $test, "foo bar baz", "contents of archive match");

# open a file for write changing the member name
lives_ok {
    $io = IO::File::CompressOnClose::Zip->new(">bar");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# set the archive member name
$io->member_filename("baz");

# close the file
$io->close;
ok( ! -f "bar", "file 'bar' does not exist");
ok( -f "bar.zip", "file 'bar.zip' exists");
ok( -s "bar.zip", "file 'bar.zip' has non-zero size");

# try to open the archive using Compress::Zlib
lives_ok {
   $zip = Archive::Zip->new;
   $zip->read("bar.zip");
} 'open archive as zip file';
if( my $member = $zip->memberNamed("baz") ) {
    $test = $member->contents;
}
is( $test, "foo bar baz", "contents of archive match");


#
# EOF

