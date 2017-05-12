use ExtUtils::MakeMaker;
WriteMakefile(
    NAME              => 'HTML::AccountAutoDiscovery',
    VERSION_FROM      => 'lib/HTML/AccountAutoDiscovery.pm',
    PREREQ_PM         => {
		Test::More => 0.32,
		LWP::UserAgent => 0,
		Class::ErrorHandler => 0,
	},
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/HTML/AccountAutoDiscovery.pm',
       AUTHOR         => 'Naoya Ito <naoya@naoya.dyndns.org>') : ()),
);
