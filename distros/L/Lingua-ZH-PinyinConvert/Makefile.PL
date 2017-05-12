use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Lingua::ZH::PinyinConvert',
    'VERSION_FROM'	=> 'PinyinConvert.pm', # finds $VERSION
    'PREREQ_PM'		=> {}, # e.g., Module::Name => 1.1
    ($] >= 5.006 ?    ## Add these new keywords supported since 5.006
      (ABSTRACT_FROM => 'PinyinConvert.pm', # retrieve abstract from module
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
