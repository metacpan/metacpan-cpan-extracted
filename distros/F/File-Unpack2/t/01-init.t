#!perl -T
use strict;
use warnings;
use Test::More tests => 2;

use FindBin;
#use lib "$FindBin::Bin/..";    # fails under -T
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack2;

my $o = File::Unpack2->new(foo => 'bar');
ok(defined($o), "basic new");
isa_ok($o, 'File::Unpack2');
##
