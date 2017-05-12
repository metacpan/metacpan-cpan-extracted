#
# $Id: 05_modes.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More tests => 46;
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

# create a regular file
lives_ok {
    my $file = IO::File->new(">foo");
    $file->print("foo");
    $file->close;
} 'create a regular file';
ok( -s "foo", 'regular file has a non-zero size');

# open for read as bare filename
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new("foo");
} 'create an object for read';
isa_ok($io, 'IO::File::CompressOnClose');
is($io->compress_on_close, 0, 'will not compress a file opened for read');

# open for read with redirection char
lives_ok {
    $io = IO::File::CompressOnClose->new("<foo");
} 'create an object for read';
isa_ok($io, 'IO::File::CompressOnClose');
is($io->compress_on_close, 0, 'will not compress a file opened for read');

# open for append with redirection char
lives_ok {
    $io = IO::File::CompressOnClose->new(">>foo");
} 'create an object for append';
isa_ok($io, 'IO::File::CompressOnClose');
is($io->compress_on_close, 1, 'will compress a file opened for append');
lives_ok {
    $io->compress_to($io->filename . '.archive');
} 'set compress to for file opened for append';
lives_ok {
    $io->close;
} 'close file opened for append';
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.archive", "file 'foo.archive' exists");
ok( -s "foo.archive", "file 'foo.archive' has non-zero size");

# open for write with redirection char
lives_ok {
    $io = IO::File::CompressOnClose->new(">foo");
} 'create an object for write';
is($io->compress_on_close, 1, 'will compress a file opened for write');
$io->print("foo bar baz");
lives_ok {
    $io->compress_to($io->filename . '.archive2');
} 'set compress to for file opened for write';
lives_ok {
    $io->close;
} 'close file opened for write';
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.archive2", "file 'foo.archive2' exists");
ok( -s "foo.archive2", "file 'foo.archive2' has non-zero size");

# create a regular file
lives_ok {
    my $file = IO::File->new(">foo");
    $file->print("foo");
    $file->close;
} 'create a regular file';
ok( -s "foo", 'regular file has a non-zero size');

# open for read with mode char
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "r");
} 'create an object for read';
isa_ok($io, 'IO::File::CompressOnClose');
is($io->compress_on_close, 0, 'will not compress a file opened for read');

# open for append with mode char
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "a");
} 'create an object for append';
isa_ok($io, 'IO::File::CompressOnClose');
is($io->compress_on_close, 1, 'will compress a file opened for append');
lives_ok {
    $io->compress_to($io->filename . '.archive');
} 'set compress to for file opened for append';
lives_ok {
    $io->close;
} 'close file opened for append';
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.archive", "file 'foo.archive' exists");
ok( -s "foo.archive", "file 'foo.archive' has non-zero size");

# open for write with mode char
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "w");
} 'create an object for write';
is($io->compress_on_close, 1, 'will compress a file opened for write');
$io->print("foo bar baz");
lives_ok {
    $io->compress_to($io->filename . '.archive2');
} 'set compress to for file opened for write';
lives_ok {
    $io->close;
} 'close file opened for write';
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.archive2", "file 'foo.archive2' exists");
ok( -s "foo.archive2", "file 'foo.archive2' has non-zero size");

# test that we die on unsupported modes
use Fcntl;
throws_ok {
    $io = IO::File::CompressOnClose->new("foo", O_CREAT);
} qr/numeric modes not supported/, 'open with numeric mode';
throws_ok {
    $io = IO::File::CompressOnClose->new("file", "<:utf8");
} qr/io layers not supported/, 'open with layers';

#
# EOF
