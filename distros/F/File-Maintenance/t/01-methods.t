#!perl

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/lib";
use Test::More;
use File::Maintenance;

my @methods =
    qw(age test recurse directory pattern archive_directory get_files archive
     purge);

plan tests => scalar(@methods) + 1;

my $obj   = File::Maintenance->new;
my $class = 'File::Maintenance';

isa_ok($obj, $class);

foreach my $m (@methods) {
    ok($obj->can($m), "$class->can('$m')");
}
