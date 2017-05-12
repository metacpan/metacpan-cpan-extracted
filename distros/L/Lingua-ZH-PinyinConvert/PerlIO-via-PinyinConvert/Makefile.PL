use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'PerlIO::via::PinyinConvert',
    'VERSION_FROM'	=> 'PinyinConvert.pm', 
    'PREREQ_PM'		=> {}, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'PinyinConvert.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
