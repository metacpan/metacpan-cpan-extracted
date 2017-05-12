#
# $Id: 01_use.t,v 1.2 2003/12/28 00:15:15 james Exp $
#

use Test::More tests => 4;
use Test::Exception;

use strict;
use warnings;

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

# open a file for write
my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new("foo", "w");
} 'create an instance';
isa_ok($io, 'IO::File::CompressOnClose');

# make sure we can use the default compressor
use_ok($io->compressor);

#
# EOF

