use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Games::QuizTaker',
    'VERSION_FROM'	=> 'lib/Games/QuizTaker.pm', # finds $VERSION
    'PREREQ_PM'		=> {Carp=>0,
			    Object::InsideOut=>0,
			    Text::Wrap=>0,
                            Fcntl=>0,
			    Test::More => 0,
			    Test::Harness => 0,
			    Test::Pod => 0,
                            Sub::Override => 0,
			   }, # e.g., Module::Name => 1.1
);
