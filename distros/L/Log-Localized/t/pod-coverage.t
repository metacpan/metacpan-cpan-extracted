#!/usr/local/bin/perl
#################################################################
#
#   $Id: pod-coverage.t,v 1.1 2006/05/23 13:58:46 erwan Exp $
#
#   050912 erwan Created
#   

use Test::More;
#eval "use Test::Pod 1.14";
#plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
all_pod_coverage_ok();

#my @files = all_pod_files("../lib/","lib/");
#plan tests => scalar(@files);
#foreach my $file (@files) {
#    pod_coverage_ok($file);
#}



