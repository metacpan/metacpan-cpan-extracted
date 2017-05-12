use strict;
use warnings;
use Module::Build;
my $build = Module::Build->new(
	module_name => 'HTML::Form::XSS',
	license => 'perl',
	dist_author => 'MacGyveR <dumb@cpan.org>',
	requires => {
		'perl' => '5.10.1',
		"Carp" => 0,
		"Data::Dumper" => 0,
		"XML::Simple" => 0,
		"HTML::XSSLint::Result" => 0
	},
	build_requires => {
		"Test::More" => 0,
		"WWW::Mechanize" => 0,
		"HTML::Form" => 0
	},
	configure_requires => {
		'Module::Build' => 0
	},
	create_makefile_pl => 'traditional',
	meta_merge => {
		resources => {
			repository => 'https://github.com/thedumbterminal/HTML-Form-XSS'
		}
	}
	
);
$build->create_build_script;
