use 5.00503;
use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'		=> 'Mail::Thread',
    'VERSION_FROM'	=> 'Thread.pm',
    'PREREQ_PM'		=> { 
			'Test::More' => 0,
      'Email::Abstract' => 0 ,
		},
    ABSTRACT_FROM => 'Thread.pm',
    AUTHOR     => 'Tony Bowden <tmtm@cpan.org>',
);
