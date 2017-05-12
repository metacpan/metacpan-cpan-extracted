use 5.006;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'HTML::Widget::Constraint::ComplexPassword',
    VERSION_FROM      => 'lib/HTML/Widget/Constraint/ComplexPassword.pm', # finds $VERSION
    PREREQ_PM         => {
    	HTML::Widget::Constraint => 0,
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/Widget/Constraint/ComplexPassword.pm', # retrieve abstract from module
       AUTHOR         => 'Jozef Kutej <jozef@kutej.net>') : ()),
	(MM->can('signature_target') ? (SIGN => 1) : ()),
);
