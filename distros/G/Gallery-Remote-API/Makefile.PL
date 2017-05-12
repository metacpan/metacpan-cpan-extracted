use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Gallery::Remote::API',
    AUTHOR              => 'Jonathan Wright <mysteryte@cpan.org>',
    VERSION_FROM        => 'lib/Gallery/Remote/API.pm',
    ABSTRACT_FROM       => 'lib/Gallery/Remote/API.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/remotegallery' ],
    PREREQ_PM => {
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
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Gallery-Remote-API-*' },
);
