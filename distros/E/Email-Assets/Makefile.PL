use strict;
use warnings FATAL => 'all';
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'Email::Assets',
    AUTHOR           => q{Aaron J Trevena <teejay@cpan.org>},
    VERSION_FROM     => 'lib/Email/Assets.pm',
    ABSTRACT_FROM    => 'lib/Email/Assets.pm',
    LICENSE          => 'Artistic_2_0',
    PL_FILES         => {},
    MIN_PERL_VERSION => 5.006,
    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 0,
    },
    BUILD_REQUIRES => {
        'Test::More' => 0,
	'Test::Exception' => 0,
        'Test::Differences' => 0,
        'File::Temp' => 0,
        'File::Compare' => 0,
        'File::Slurp' => 0,
    },
    PREREQ_PM => {
        'Moose' => 0,
        'MIME::Types' => 0,
        'MIME::Base64' => 0,
	'File::Type' => 0.22,
	'MIME::Lite' => 0,
        'Data::UUID' => 0,
    },
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Email-Assets-*' },
);
