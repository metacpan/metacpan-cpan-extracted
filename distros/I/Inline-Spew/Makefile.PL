use 5.006;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Inline::Spew',
    'VERSION_FROM'	=> 'lib/Inline/Spew.pm',
    'PREREQ_PM'		=> {
			    'Inline' => 0,
			    'Parse::RecDescent' => 0,
			    'YAML' => 0,
			   },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'lib/Inline/Spew.pm',
       AUTHOR     => 'Randal L. Schwartz <merlyn@stonehenge.com>') : ()),
);
