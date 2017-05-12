use strict;
use warnings;

use Module::Build;

if($^O ne "linux")
{
	die("No support for OS");
}

my %module_build_args = (
	dist_name     => "Linux-Ethtool",
	dist_version  => "0.11",
	dist_abstract => "Linux SIOCETHTOOL ioctl interface",
	dist_author   => [ "Daniel Collins <solemnwarning\@solemnwarning.net>" ],
	
	module_name => "Linux::Ethtool",
	license     => "perl",
	
	build_requires => {
		"Module::Build"  => "0.2806",
		"ExtUtils::H2PM" => "0.03",
	},
	
	include_dirs => [ "./" ],
);

Module::Build->new(%module_build_args)->create_build_script();
