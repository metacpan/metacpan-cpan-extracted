use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTTP::Body::MultiPart::Extend',
    AUTHOR              => q{Cindy Wang (CindyLinz)},
    VERSION_FROM        => 'lib/HTTP/Body/MultiPart/Extend.pm',
    ABSTRACT_FROM       => 'lib/HTTP/Body/MultiPart/Extend.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Deep' => 0,
	'HTTP::Body' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTTP-Body-MultiPart-Extend-*' },
);
