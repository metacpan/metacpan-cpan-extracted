use ExtUtils::MakeMaker;


WriteMakefile(
    'NAME'		=> 'Lingua::ZH::ZhuYinWen',
    'VERSION_FROM'	=> 'ZhuYinWen.pm', 
    'PREREQ_PM'		=> {
	'String::Multibyte' => '1.03',
    }, 
    ($] >= 5.005 ?    
      (ABSTRACT_FROM => 'ZhuYinWen.pm', 
       AUTHOR     => 'xern <xern@cpan.org>') : ()),
);
