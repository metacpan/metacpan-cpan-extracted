use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'GraphViz::ISA::Multi',
    VERSION_FROM => 'lib/GraphViz/ISA/Multi.pm', # finds $VERSION
    AUTHOR       => 'Marcus Thiesen (marcus@cpan.org)',
    ABSTRACT_FROM     => 'lib/GraphViz/ISA/Multi.pm',
    PREREQ_PM    => {
                     'Test::Simple' => 0.44,
		     'GraphViz'     => 0,
                    },
);
