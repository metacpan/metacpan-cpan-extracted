use 5.00503;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Imager::TimelineDiagram',
    'VERSION_FROM'	=> 'TimelineDiagram.pm', 
    'PREREQ_PM'		=> {
        'Imager' => '0.43',
    }, 
    ($] >= 5.005 ?   
      (ABSTRACT_FROM => 'TimelineDiagram.pm', 
       AUTHOR     => 'Matt Sanford <mzsanford@cpan.org>') : ()),
);
