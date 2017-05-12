use 5.008007;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Lyrics::Fetcher::AZLyrics',
    VERSION_FROM      => 'lib/Lyrics/Fetcher/AZLyrics.pm',
    PREREQ_PM         => { LWP::UserAgent => 0, HTML::Strip => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lyrics/Fetcher/AZLyrics.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),

    # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);
