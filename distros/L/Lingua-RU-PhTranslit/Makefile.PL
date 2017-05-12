use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Lingua::RU::PhTranslit',
    'VERSION_FROM'	=> 'PhTranslit.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PhTranslit.pm', # retrieve abstract from module
       AUTHOR     => 'Mikhail V. Basov <CPAN -at- Basov -dot- net>') : ()),
);
