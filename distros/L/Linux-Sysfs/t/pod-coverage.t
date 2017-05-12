#!perl -T

use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage" if $@;

plan tests => 8;

pod_coverage_ok( 'Linux::Sysfs::Attribute' );
pod_coverage_ok( 'Linux::Sysfs::Bus' );
pod_coverage_ok( 'Linux::Sysfs::Class' );
pod_coverage_ok( 'Linux::Sysfs::ClassDevice' );
pod_coverage_ok( 'Linux::Sysfs::Device' );
pod_coverage_ok( 'Linux::Sysfs::Driver' );
pod_coverage_ok( 'Linux::Sysfs::Module' );
pod_coverage_ok( 'Linux::Sysfs' );
