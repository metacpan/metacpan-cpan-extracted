use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'FFMPEG::Effects',
    AUTHOR              => q{Piero Bugoni <PBugoni@cpan.org>},
    VERSION_FROM        => 'lib/FFMPEG/Effects.pm',
    ABSTRACT_FROM       => 'lib/FFMPEG/Effects.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'FFMPEG-Effects-* *.mpg *.avi *.h264 *.flv *.png Title.ps' },
);
