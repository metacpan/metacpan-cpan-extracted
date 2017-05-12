use 5.008008;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME          => 'LWP::Protocol::UWSGI',
	VERSION_FROM  => 'lib/LWP/Protocol/UWSGI.pm', # finds $VERSION
	MAN3PODS      => {
		'lib/LWP/Protocol/UWSGI.pm' => 'blib/man3/LWP::Protocol::UWSGI.3',
	},
	PREREQ_PM     => {
		LWP                 => 0,
		LWP::Protocol       => 0,
		LWP::Protocol::http => 0,
		Net::HTTP           => 0,
		URI                 => 0,
		URI::Escape::XS	    => 0,
	},
	($] >= 5.005 ?	 ## Add these new keywords supported since 5.005
	  (ABSTRACT_FROM => 'lib/LWP/Protocol/UWSGI.pm', # retrieve abstract from module
	   AUTHOR        => 'Nikolas Shulyakovskiy <shulyakovskiy@mail.ru>') : ()),
);
