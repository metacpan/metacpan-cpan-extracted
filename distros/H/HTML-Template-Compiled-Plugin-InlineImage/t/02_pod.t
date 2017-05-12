# $Id: 02_pod.t,v 1.1 2006/08/26 15:04:22 tinita Exp $
use strict;
use Test::More;
eval "use Test::Pod 1.00";
plan skip_all => "Test::Pod 1.00 required for testing POD" if $@;
my @poddirs = qw( blib );
all_pod_files_ok( all_pod_files( @poddirs ) );

