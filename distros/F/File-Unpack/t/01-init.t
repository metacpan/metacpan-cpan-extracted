#!perl -T
use strict;
use warnings;
use Test::More tests => 2;

use FindBin;
#use lib "$FindBin::Bin/..";    # fails under -T
BEGIN { unshift @INC, "$1/../blib/lib" if $FindBin::Bin =~ m{(.*)} };
use File::Unpack;

my $o = File::Unpack->new(foo => 'bar');
ok(defined($o), "basic new");
isa_ok($o, 'File::Unpack');
##
