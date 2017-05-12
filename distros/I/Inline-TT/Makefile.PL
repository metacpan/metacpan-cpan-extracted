use ExtUtils::MakeMaker;

WriteMakefile(
    NAME			=> 'Inline::TT',
    VERSION_FROM	=> 'lib/Inline/TT.pm',
    PREREQ_PM		=> { Inline		=> '0.42',
						 Template	=> '2.0' },
    ABSTRACT_FROM	=> 'lib/Inline/TT.pm',
    AUTHOR			=> 'Phil Crow <philcrow2000@yahoo.com>'
);
