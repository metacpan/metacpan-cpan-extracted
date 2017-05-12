use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Imager::Chart::Radial',
    'VERSION_FROM'	=> 'Radial.pm', # finds $VERSION
    'PREREQ_PM'		=> {Imager => 0 }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'Radial.pm', # retrieve abstract from module
       AUTHOR     => 'Aaron J Trevena <teejay@droogs.org>') : ()),
);
