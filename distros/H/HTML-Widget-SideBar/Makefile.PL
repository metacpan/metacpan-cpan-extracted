use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'HTML::Widget::SideBar',
    'VERSION_FROM'	=> 'SideBar.pm', 
    'PREREQ_PM'		=> {Tree::Numbered => 1.0, Tree::Numbered::DB => 1.01}, 
    ($] >= 5.005 ?    
      (AUTHOR     => 'Yosef Meller <mellerf@netvision.net.il>') : ()),
);
