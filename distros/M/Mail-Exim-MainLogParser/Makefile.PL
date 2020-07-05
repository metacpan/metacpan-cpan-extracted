use strict;
use warnings;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'Mail::Exim::MainLogParser',
    VERSION_FROM => 'lib/Mail/Exim/MainLogParser.pm', # finds \$VERSION
    AUTHOR       => 'Russell Glaue (rglaue@cait.org)',
    ABSTRACT_FROM  => 'lib/Mail/Exim/MainLogParser.pm', # retrieve abstract from module
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
                    },
);

#    EXE_FILES    => [ 'bin/eximlogparser' ],
