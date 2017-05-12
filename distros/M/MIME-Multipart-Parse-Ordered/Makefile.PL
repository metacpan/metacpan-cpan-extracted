use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'MIME::Multipart::Parse::Ordered',
    AUTHOR              => q{jimi <jimi@webu.co.uk>},
    VERSION_FROM        => 'lib/MIME/Multipart/Parse/Ordered.pm',
    ABSTRACT_FROM       => 'lib/MIME/Multipart/Parse/Ordered.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'artistic2')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'MIME-Multipart-Parse-Ordered-*' },
);
