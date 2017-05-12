use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::WikiConverter',
    AUTHOR              => 'David J. Iberri <diberri@cpan.org>',
    LICENSE             => 'perl',
    VERSION_FROM        => 'lib/HTML/WikiConverter.pm',
    ABSTRACT_FROM       => 'lib/HTML/WikiConverter.pm',
    PL_FILES            => {},
    EXE_FILES           => [ 'bin/html2wiki' ],
    PREREQ_PM => {
        'Test::More'       => 0,
        'HTML::Tree'       => 3.18,
        'HTML::Element'    => 0,
        'CSS'              => 1.07, # (bug #20594)
        'URI'              => 1.35,
        'Pod::Usage'       => 1.16,
        'URI::Escape'      => 0,
        'HTML::Entities'   => 1.27,
        'HTML::Tagset'     => 3.04,
        'Params::Validate' => 0.77,
        'Class::Data::Inheritable' => 0.02,
        'Exporter'         => 0,
        'Carp'             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-WikiConverter-*' },
);
