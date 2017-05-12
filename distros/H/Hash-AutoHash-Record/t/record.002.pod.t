#!perl
use strict;
use File::Spec;
use Module::Build;
use Test::More;
use Test::Pod;
use Test::Pod::Content;

my $builder=Module::Build->current;
my $module_name=$builder->module_name;
my $module_pm=File::Spec->catdir('blib',$builder->dist_version_from);
pod_file_ok($module_pm,"$module_name POD okay");

my $correct_version=$builder->dist_version;
# NG 13-09-28: handle dev versions
$correct_version=~s/_.*//;    # strip development sub-version number
pod_section_like($module_pm,'VERSION',qr/Version $correct_version$/,"$module_name POD version number");

done_testing();
