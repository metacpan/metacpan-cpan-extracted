use ExtUtils::MakeMaker;
WriteMakefile(
    'NAME'			=> 'Finance::Currency::Convert::XE',
    'VERSION_FROM'	=> 'lib/Finance/Currency/Convert/XE.pm',
    'PREREQ_PM'		=> {
		WWW::Mechanize		=> 0,
		HTML::TokeParser	=> 0,
		Test::More			=> 0.47,	# for testing
	},
	NO_META			=> 1,

    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT	=> 'An online currency conversion module.',
       AUTHOR	=> 'Barbie <barbie@cpan.org>') : ()),
);
