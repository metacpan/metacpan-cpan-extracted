use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTML::Encoding',
    VERSION_FROM      => 'lib/HTML/Encoding.pm', # finds $VERSION
    PREREQ_PM         => {

      Encode              => 0, #
      HTML::Parser        => 0, # todo: figure out proper version
      HTTP::Headers::Util => 0, #
      HTTP::Response      => 0, #

                         },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Encoding.pm', # retrieve abstract from module
       AUTHOR         => 'Bjoern Hoehrmann <bjoern@hoehrmann.de>') : ()),

    LICENSE           => 'perl',
    'dist'            => {
      PREOP     => 'chmod 600 Makefile.PL',
      TARFLAGS	=> '--group=cpan --owner=bjoern -cvf',
    },
);
