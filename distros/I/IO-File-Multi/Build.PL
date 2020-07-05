use strict;
use warnings;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'IO::File::Multi'
	, license => 'perl'
	, dist_author => 'Nem W. Schlecht <NEMWS@CPAN.org>'
	, dist_version_from => 'lib/IO/File/Multi.pm'
	, requires => {
		'IO::File' => 0
		, 'perl' => '5.005'
	}
	, build_requires => {
		'File::Temp' => 0
	}
);

$build->create_build_script();
