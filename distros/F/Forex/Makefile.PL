use ExtUtils::MakeMaker;

WriteMakefile(
	NAME	     => 'Forex',
	AUTHOR       => 'Bhavin Patel <mail4bhavin@gmail.com>',
	VERSION_FROM => 'Forex.pm',
	PREREQ_PM    => { 'Test::More'     => 0  ,
			'LWP::UserAgent' => 0  ,
			'JSON::XS'		  => 0  ,
			'DateTime'		  => 0 },
	dist	     => { COMPRESS => 'gzip -9f' , SUFFIX => 'gz' },
	INSTALLDIRS  => 'perl',
	ABSTRACT     => 'historic forex rates from openexchangerates.org',
	BUILD_REQUIRES => { English => 0, 'Test::More' => 0 , "utf8" => 0 },
	test	=> { TESTS => 't/*.t' }
);
