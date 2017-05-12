use 5.008;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME              => 'Mail::OpenRelay::Simple',
    VERSION_FROM      => 'lib/Mail/OpenRelay/Simple.pm',
    PREREQ_PM         => {
			Class::Accessor::Fast => 0.25,
			Net::Telnet => 3.03,
    			},
    ($] >= 5.005 ?     
      (ABSTRACT	      => 'Simple open relay check module',
       AUTHOR         => 'Matteo Cantoni <mcantoni@cpan.org>') : ()),
);
