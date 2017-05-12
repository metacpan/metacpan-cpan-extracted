#
# $Id: 08_coderef.t,v 1.1 2003/12/28 00:15:15 james Exp $
#

use strict;
use warnings;

use Test::More tests => 7;
use Test::Exception;

use File::Path;
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

# open a file for write
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new(">foo");
} 'open file for write';

# print something to it
$io->print("foo bar baz");

# set the compressor to a dummy coderef
my $compressor = sub {
    my($src_file, $dst_file) = @_;
    my $fh = IO::File->new($src_file);
    my $contents = <$fh>;
    $fh->close;
    $fh = IO::File->new(">$dst_file");
    $fh->print( scalar reverse $contents );
    $fh->close;
};
$io->compressor( $compressor );
$io->compress_to( $io->filename . '.reverse' );

# close the file
$io->close;
ok( ! -f "foo", "file 'foo' does not exist");
ok( -f "foo.reverse", "file 'foo.reverse' exists");
ok( -s "foo.reverse", "file 'foo.reverse' has non-zero size");

# open the file
my $fh;
lives_ok {
   $fh = IO::File->new("foo.reverse");
} 'open archive as a plain file';
my $test = <$fh>;
is( $test, "zab rab oof", "contents of file match");

#
# EOF

