#
# $Id: 11_esoteric.t,v 1.1 2003/12/28 15:29:08 james Exp $
#

use strict;
use warnings;

use Test::More tests => 5;
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

# make sure we die when given non-filenames to open
throws_ok {
    IO::File::CompressOnClose->new(">&1");
} qr/does not exist after open/, "open '>&1";

throws_ok {
    IO::File::CompressOnClose->new("+>");
} qr/does not exist after open/, "open '+>";

throws_ok {
    IO::File::CompressOnClose->new("|$^X -e exit");
} qr/does not exist after open/, "open '|$^X -e exit";

throws_ok {
    IO::File::CompressOnClose->new("$^X -e exit|");
} qr/does not exist after open/, "open '$^X -e exit|";

#
# EOF

