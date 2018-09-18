use strict;
use warnings;

use Test::More (tests => 1);
use Test::Exception;
use File::Temp qw/ tempfile tempdir /;

#
# This test checks for the installed/required git version
#
my $help=readpipe("git --version");
$help=~ /(\d+\.\d+.\d+)/;

ok($help=~/git version/, "git is available");
