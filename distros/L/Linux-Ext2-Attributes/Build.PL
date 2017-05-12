use strict;
use warnings;

use Module::Build;

if($^O ne "linux")
{
	die("No support for OS");
}

Module::Build->new(
	dist_name     => "Linux-Ext2-Attributes",
	dist_version  => "0.20",
	dist_abstract => "Linux ext2/3/4 filesystem attributes",
	dist_author   => [ "Daniel Collins <solemnwarning\@solemnwarning.net>" ],
	
	module_name => "Linux::Ext2::Attributes",
	license     => "perl",
	
	build_requires => {
		"Module::Build"  => "0.2806",
		"ExtUtils::H2PM" => "0.03",
	},
	
	configure_requires => {
		"Module::Build"  => "0.2806",
	},
)->create_build_script();
