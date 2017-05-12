use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Lingua::ZH::ChineseNaming',
    'VERSION_FROM'	=> 'ChineseNaming.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'ChineseNaming.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
