#
# $Id: 02_basic.t,v 1.2 2003/12/28 00:15:15 james Exp $
#

use Test::More tests => 2;
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

my $io;
lives_ok {
    $io = IO::File::CompressOnClose->new('foo', 'w');
    print $io "foo bar baz\n";
    $io->close;
} 'open/print/close a file';

#
# EOF

