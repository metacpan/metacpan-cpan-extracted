#!perl
use strict;
use File::Basename;
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
$correct_version=~s/_.*//;	# strip development sub-version number
pod_section_like($module_pm,'VERSION',qr/Version $correct_version$/,
		 "version number in $module_name POD");

# do it for V0 also
my($name,$path)=fileparse($module_pm,qw(.pm));
$module_name.='::V0';
$module_pm=File::Spec->catfile($path,$name,'V0.pm');
pod_file_ok($module_pm,"$module_name POD okay");
pod_section_like($module_pm,'VERSION',qr/Version $correct_version$/,
		 "version number in $module_name POD");

done_testing();
