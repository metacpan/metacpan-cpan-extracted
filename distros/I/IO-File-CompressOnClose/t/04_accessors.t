#
# $Id: 04_accessors.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More tests => 35;
use Test::Exception;

use File::Path;
use File::Spec;
use IO::File;

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

# open the file for read
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new( "foo" )
} 'open a file for read';
isa_ok($io, 'IO::File::CompressOnClose');

# test the filename accessor
my $abs = File::Spec->rel2abs("foo");
is( $io->filename, $abs, 'filename accessor works');

# test the compress_to accessor
ok( ! defined $io->compress_to, 'compress_to not defined');
lives_ok {
    $io->compress_to('foo.archive');
} 'set compress_to attribute';
is( $io->compress_to, 'foo.archive', 'compress_to defined');

# test the compress_on_close accessor
is( $io->compress_on_close, 0, 'compress_on_close not set');
lives_ok {
    $io->compress_on_close(1);
} 'set compress_on_close attribute';
is( $io->compress_on_close, 1, 'compress_on_close set');
lives_ok {
    $io->compress_on_close(0);
} 'set compress_on_close attribute';
is( $io->compress_on_close, 0, 'compress_on_close not set');
lives_ok {
    $io->compress_on_close('yes');
} 'set compress_on_close attribute';
is( $io->compress_on_close, 1, 'compress_on_close set');
lives_ok {
    $io->compress_on_close(0);
} 'set compress_on_close attribute';

# test the delete_after_compress accessor
is( $io->delete_after_compress, 1, 'delete_after_compress not set');
lives_ok {
    $io->delete_after_compress(0);
} 'clear delete_after_compress attribute';
is( $io->delete_after_compress, 0, 'delete_after_compress set');
lives_ok {
    $io->delete_after_compress(1);
} 'set delete_after_compress attribute';
is( $io->delete_after_compress, 1, 'delete_after_compress not set');
lives_ok {
    $io->delete_after_compress(0);
} 'set delete_after_compress attribute';

# test the compressed accessor
is( $io->compressed, 0, 'compressed not set');
lives_ok {
    $io->compressed(1);
} 'set compressed attribute';
is( $io->compressed, 1, 'compressed set');
lives_ok {
    $io->compressed(0);
} 'set compressed attribute';
is( $io->compressed, 0, 'compressed not set');
lives_ok {
    $io->compressed('yes');
} 'set compressed attribute';
is( $io->compressed, 1, 'compressed set');

# test the compressor accessor
ok( defined $io->compressor, 'compressor set');
lives_ok {
    $io->compressor('Foo::Bar');
} 'set compressor to a class';
is( $io->compressor, 'Foo::Bar', 'compressor set to Foo::Bar');
my $compress = sub {};
lives_ok {
    $io->compressor($compress);
} 'set compressor to a coderef';
is( $io->compressor, $compress);

#
# EOF

