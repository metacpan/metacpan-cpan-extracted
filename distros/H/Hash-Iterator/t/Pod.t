#!/usr/bin/perl
use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.00";
if ($@) {
	plan skip_all => "Test::Pod 1.00 required for testing POD";
}
my @poddirs = qw( lib );
use File::Spec::Functions qw( catdir updir );
all_pod_files_ok(
	all_pod_files( map { catdir updir, $_ } @poddirs )
);

done_testing();

