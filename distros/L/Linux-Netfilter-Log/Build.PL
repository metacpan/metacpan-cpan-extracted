use strict;
use warnings;

use Module::Build;

if($^O ne "linux")
{
	die("No support for OS");
}

Module::Build->new(
	dist_name     => "Linux-Netfilter-Log",
	dist_version  => "1.0",
	dist_abstract => "Linux netfilter logging (libnetfilter_log) wrapper",
	dist_author   => [ "Daniel Collins <daniel.collins\@smoothwall.net>" ],
	
	module_name => "Linux::Netfilter::Log",
	license     => "perl",
	
	build_requires => {
		"Module::Build"  => "0.2806",
		"ExtUtils::H2PM" => "0.03",
	},
	
	include_dirs       => [ "./" ],
	extra_linker_flags => [ "-lnetfilter_log" ],
)->create_build_script();
