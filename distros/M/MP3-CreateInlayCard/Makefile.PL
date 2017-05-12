use 5.005;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'MP3::CreateInlayCard',
    VERSION_FROM      => 'lib/MP3/CreateInlayCard.pm', # finds $VERSION
    PREREQ_PM         => {
        'HTML::Template'   => 0,
        'Music::Tag'       => 0,
        'Music::Tag::MP3'  => 0,
        'File::Find::Rule' => 0,
        'Cwd'              => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/MP3/CreateInlayCard.pm',
       AUTHOR         => 'David Precious <davidp@preshweb.co.uk>') : ()),

    # include the LICENSE param, as long as EU::MM is new enough to support it:
    ($ExtUtils::MakeMaker::VERSION >= 6.3002 ? (LICENSE => "perl") : () ),
);

# $Id: Makefile.PL 535 2009-02-13 23:26:32Z davidp $
