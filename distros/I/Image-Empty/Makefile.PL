use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Image::Empty',
    AUTHOR              => q{Rob Brown <rob@intelcompute.com>},
    VERSION_FROM        => 'lib/Image/Empty.pm',
    ABSTRACT_FROM       => 'lib/Image/Empty.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
        'MIME::Base64'    => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Image-Empty-*' },
);
