use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Devel::SummarizedWarnings',
    'VERSION_FROM'	=> 'SummarizedWarnings.pm',
    'PREREQ_PM'		=> { Test::More => 0 },
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'SummarizedWarnings.pm',
       AUTHOR     => 'Josh Jore <josh@>') : ()),
);
