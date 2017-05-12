# $Id: 22_pod.t 1084 2008-12-16 16:59:19Z tinita $
use strict;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( examples blib );
all_pod_files_ok( all_pod_files( @poddirs ) );

