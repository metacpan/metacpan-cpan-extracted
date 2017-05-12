use ExtUtils::MakeMaker;
WriteMakefile(
	      NAME            => 'Devel::Profile',
	      VERSION_FROM    => 'Profile.pm',
	      ABSTRACT_FROM   => 'Profile.pm',
	      AUTHOR          => 'Jeff Weisberg <http://www.tcp4me.com/>',
	      PREREQ_PM       => {Time::HiRes => 0},
);
