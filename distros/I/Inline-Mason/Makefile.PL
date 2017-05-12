use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'Inline::Mason',
    VERSION_FROM      => 'lib/Inline/Mason.pm',
    PREREQ_PM         => {
	'Text::MicroMason' => '1',
	'Inline::Files::Virtual' => '0.53',
    },
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Inline/Mason.pm',
       AUTHOR         => 'xern <xern@cpan.org>') : ()),
);
