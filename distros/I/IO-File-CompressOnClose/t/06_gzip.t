#
# $Id: 06_gzip.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use File::Path;
use Compress::Zlib;

BEGIN {
    chdir 't' if -d 't';
}

mkdir 'compress' unless -d 'compress';
chdir 'compress' or die;

END {
    chdir("..") or die;
    rmtree 'compress' unless @ARGV;
}

use_ok('IO::File::CompressOnClose::Gzip');

# open a file for write
my $io;
lives_ok {
    $io = IO::File::CompressOnClose::Gzip->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# close the file
$io->close;
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.gz", "file 'foo.gz' exists");
ok( -s "foo.gz", "file 'foo.gz' has non-zero size");

# try to open the archive using Compress::Zlib
my $gz;
lives_ok {
   $gz = gzopen("foo.gz", "r");
} 'open archive as gzip file';
my $test;
$gz->gzreadline($test);
is( $test, "foo bar baz", "contents of archive match");

#
# EOF

