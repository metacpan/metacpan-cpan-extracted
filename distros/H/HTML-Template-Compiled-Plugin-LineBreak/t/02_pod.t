# $Id: 02_pod.t 5 2007-07-14 15:28:44Z root $
use strict;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib );
all_pod_files_ok( all_pod_files( @poddirs ) );

