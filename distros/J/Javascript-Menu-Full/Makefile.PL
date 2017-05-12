use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Menu',
    'DISTNAME'	=> 'Javascript-Menu-Full',
    'VERSION_FROM'	=> 'Javascript/Menu.pm', 
    'PREREQ_PM'		=> {}, 
    'PM'				=> 	{'Tree/Numbered.pm' => '$(INST_LIBDIR)/Tree/Numbered.pm', 
    						'Tree/Numbered/DB.pm' => , '$(INST_LIBDIR)/Tree/Numbered/DB.pm',
						'Javascript/Menu.pm' =>'$(INST_LIBDIR)/Javascript/Menu.pm'},
    ($] >= 5.005 ?    
      (AUTHOR     => 'Yosef Meller <mellerf@netvision.net.il>') : ()),
);
