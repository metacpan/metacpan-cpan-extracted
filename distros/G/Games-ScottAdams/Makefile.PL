use 5.008;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME	 => 'Games::ScottAdams',
    VERSION_FROM => 'lib/Games/ScottAdams.pm', # finds $VERSION
    AUTHOR       => 'Mike Taylor <mike@miketaylor.org.uk>',
    ABSTRACT     => 'Compiler to produce Scott Adams-style adventure games',
    EXE_FILES    => [ 'bin/sac', 'bin/sad' ],
);

sub MY::postamble {
    '# I think this gets added to the Makefile.';
}
