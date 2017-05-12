######################################################################
# Makefile.PL for Gaim::Log::Parser
# 2005, Mike Schilli <cpan@perlmeister.com>
######################################################################
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'         => 'Gaim::Log::Parser',
    'VERSION_FROM' => 'lib/Gaim/Log/Parser.pm', # finds $VERSION
    'PREREQ_PM'    => {
        Log::Log4perl              => 0,
        DateTime                   => 0,
        DateTime::TimeZone         => 0,
        DateTime::Format::Strptime => 0,
        Text::Wrap                 => 0,
    },
    EXE_FILES => ['eg/gaimlog-html2text'],
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Gaim/Log/Parser.pm',
       AUTHOR     => 'Mike Schilli <cpan@perlmeister.com>') : ()),
);
