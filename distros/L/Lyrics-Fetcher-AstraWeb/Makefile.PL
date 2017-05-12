use 5.005000;
use ExtUtils::MakeMaker;

# $Id: Makefile.PL 333 2008-04-24 18:53:53Z davidp $

WriteMakefile(
    NAME              => 'Lyrics::Fetcher::AstraWeb',
    VERSION_FROM      => 'lib/Lyrics/Fetcher/AstraWeb.pm',
    PREREQ_PM         => { WWW::Mechanize => 0 },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Lyrics/Fetcher/AstraWeb.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),
       
    # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);
