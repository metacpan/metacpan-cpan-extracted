use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    ( MM->can('signature_target') ? ( SIGN => 1 ) : () ),
    NAME         => 'HTML::Hyphenate',
    VERSION_FROM => 'lib/HTML/Hyphenate.pm',
    PL_FILES     => {},
    PREREQ_PM    => {
        'Class::Meta::Express' => 0.11,
		'Class::Meta::Type'    => 0,
		'HTML::Entities'       => 0,
        'HTML::TreeBuilder'    => 0,
        'Log::Log4perl'        => 0,
        'Readonly'             => 1.03,
        'Set::Scalar'          => 0,
        'TeX::Hyphen'          => 0,
        'TeX::Hyphen::Pattern' => 0,
        'Test::More'           => 0.86,
        'Test::NoWarnings'     => 0,
        'version'              => 0,
    },
    (
        $] >= 5.005
        ? (
            ABSTRACT_FROM => 'lib/HTML/Hyphenate.pm',
            AUTHOR        => 'Roland van Ipenburg <ipenburg@xs4all.nl>'
          )
        : ()
    ),
    ( $ExtUtils::MakeMaker::VERSION >= 6.3002 ?
          ( 'LICENSE' => 'perl', )
        : () ),
    dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES    => 'HTML-Hyphenate-*' },
);
