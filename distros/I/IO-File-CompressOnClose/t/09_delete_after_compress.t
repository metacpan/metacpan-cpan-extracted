#
# $Id: 09_delete_after_compress.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;

use File::Path;

BEGIN {
    chdir 't' if -d 't';
}

mkdir 'compress' unless -d 'compress';
chdir 'compress' or die;

END {
    chdir("..") or die;
    rmtree 'compress' unless @ARGV;
}

use_ok('IO::File::CompressOnClose');

# open for write with delete after compress turned on
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "w");
} 'create an object for write';
is($io->compress_on_close, 1, 'will compress a file opened for write');
$io->print("foo bar baz");
lives_ok {
    $io->compress_to($io->filename . '.archive');
} 'set compress to for file opened for write';
lives_ok {
    $io->close;
} 'close file opened for write';
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.archive", "file 'foo.archive' exists");
ok( -s "foo.archive", "file 'foo.archive' has non-zero size");

# open for write with delete after compress turned off
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "w");
} 'create an object for write';
is($io->compress_on_close, 1, 'will compress a file opened for write');
$io->print("foo bar baz");
lives_ok {
    $io->compress_to($io->filename . '.archive2');
} 'set compress to for file opened for write';
lives_ok {
    $io->delete_after_compress(0);
} 'turn off deletion after compression';
is($io->delete_after_compress, 0, 'will not delete original file');
lives_ok {
    $io->close;
} 'close file opened for write';
ok( -f "foo", "file 'foo' still exists");
ok( -f "foo.archive2", "file 'foo.archive2' exists");
ok( -s "foo.archive2", "file 'foo.archive2' has non-zero size");

#
# EOF
