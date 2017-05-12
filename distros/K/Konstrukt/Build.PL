#!/usr/bin/perl

use Module::Build;

my $build = Module::Build->new(
	module_name => 'Konstrukt',
	dist_author => 'Thomas Wittek <mail@gedankenkonstrukt.de>',
	dist_abstract => 'Web application/design framework',
	license => 'perl',
	create_readme => 1,
	create_makefile_pl => 'passthrough',
	configure_requires => 'Module::Build',
	build_requires => {
		'Module::Build'       => '0.26',
		'File::Temp'          => 0,
		'Test::More'          => 0,
		'Test::Pod'           => 0,
		'Test::Pod::Coverage' => 0,
		'Test::Strict'        => 0,
		'Cwd'                 => 0,
	},
	requires => {
		#'Some::Module'   => '1.23',
		#'Other::Module'  => '>= 1.2, != 1.5, < 2.0',
		
		'perl'                   => '5.6.1',
		
		'Bundle::LWP'            => '1',
		'Clone'                  => '0.2',
		'CGI'                    => '3',
		'Cwd'                    => '0',
		'Date::Calc'             => '5.4',
		'DateTime'               => '0.2',
		'DateTime::Format::Mail' => '0.28',
		'DBI'                    => '1.4',
		'Devel::UseAnyFunc'      => '1',
		'Digest::SHA'            => '5.32',
		'HTTP::BrowserDetect'    => '0.98',
		'Image::Magick'          => '6.2.4',
		'MIME::Base64'           => '3',
		'POSIX'                  => '1',
		'Session'                => '0.01',
		'Storable'               => '2.1',
		'Text::Diff'             => '0.35',
		'Time::HiRes'            => '1.5',
		'Time::Local'            => '1',
		'Time::Zone'             => '2',
	},
	recommends => {
		'Clone::Fast'            => '0.9',
		'Data::Dump'             => '1',
		'Digest::HMAC_MD5'       => '1',
		'Mail::Sender'           => '0.8.13',
		'Scalar::Util::Clone'    => '0.04',
	},
);

$build->create_build_script;
