use 5.005000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lyrics::Fetcher::LyricsDownload',
    VERSION_FROM      => 'lib/Lyrics/Fetcher/LyricsDownload.pm',
    PREREQ_PM => {
        'Encode'             => 0,
        'HTML::Entities'     => 0,
        'HTML::TokeParser'   => 0,
        'LWP::Simple'        => 0,
    },
    NO_META           => 1,
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lyrics/Fetcher/LyricsDownload.pm',
       AUTHOR         => 'Rick Blevins <rick816us@comcast.net>') : ()),
);
