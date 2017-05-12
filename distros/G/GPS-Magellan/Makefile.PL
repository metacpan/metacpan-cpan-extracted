
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'GPS::Magellan',
    'VERSION_FROM'	=> 'Magellan.pm',
    'PREREQ_PM'		=> {},
     AUTHOR     => 'Peter Banik <peter@login-fo.net>',
    'LIBS'		=> ['-Lgpslib -lgps'],
    'DEFINE'		=> '-DLINUX',
    'INC'		=> '-I.',
    # 'OBJECT'		=> '$(O_FILES)', # link all the C files too
);

