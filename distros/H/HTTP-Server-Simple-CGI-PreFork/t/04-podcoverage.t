#!/usr/bin/perl -w

use strict;
use warnings;

use Test::More;

eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;
#all_pod_coverage_ok({  also_private => [ '/^[A-Z_]+$/' ], });

my @modules = all_modules();

my @web;
my @worker;
my @helpers;
my @other;

my $tests = 0;

foreach my $module (@modules) {
	if($module =~ /\:\:Worker\:\:/ && $module !~ /BaseModule/) {
		push @worker, $module;
        $tests++;
	} elsif($module =~ /\:\:Web\:\:/ && $module !~ /BaseModule/) {
		push @web, $module;
        $tests++;
	} elsif($module =~ /\:\:Helpers\:\:Cache/) {
		# Ignore local workaround clone
	} elsif($module =~ /\:\:Helpers\:\:/) {
		push @helpers, $module;
        $tests++;
	} else {
		push @other, $module;
        $tests++;
	}
}

plan tests => $tests;

# General modules
foreach my $module (@other) {
	pod_coverage_ok($module);
}

foreach my $module (@helpers) {
	my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
	pod_coverage_ok( $module, $trustparents );
}

# Worker modules
foreach my $module (@worker) {
	my $trustparents = { coverage_class => 'Pod::Coverage::CountParents' };
	pod_coverage_ok( $module, $trustparents );
}

# Web modules
foreach my $module (@web) {
	my $trustparents = {
        coverage_class => 'Pod::Coverage::CountParents',
    };
	pod_coverage_ok( $module, $trustparents );
}

done_testing();
