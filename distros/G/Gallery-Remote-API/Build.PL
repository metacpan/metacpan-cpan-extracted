use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Gallery::Remote::API',
    license             => 'perl',
    dist_author         => 'Jonathan Wright <mysteryte@cpan.org>',
    dist_version_from   => 'lib/Gallery/Remote/API.pm',
    requires => {
        'Test::More'      => 0,
		'Test::Mock::LWP' => 0,
        'version'         => 0,
		'Class::Accessor' => 0,
		'URI'             => 0,
		'URI::QueryParam' => 0,
		'LWP::UserAgent'  => 0,
		'HTTP::Cookies'   => 0,
		'File::Temp'      => 0,
		'Config::Properties' => 0,
		'Data::Diver'     => 0,
		'Sub::Name'       => 0,
		'Scalar::Util'    => 0,
		'Getopt::Long'    => 0,
		'Pod::Usage'      => 0,
		'Data::Dumper'    => 0,
		'Fcntl'           => 0
    },
    add_to_cleanup      => [ 'Gallery-Remote-API-*' ],
);

$builder->create_build_script();
