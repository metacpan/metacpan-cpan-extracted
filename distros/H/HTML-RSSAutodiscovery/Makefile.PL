use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
	      'NAME'	=> 'HTML::RSSAutodiscovery',
	      ($[ >= 5.005) ?
	      (AUTHOR   => 'Aaron Straup Cope (cpan@aaronland.net)',
	       ABSTRACT => '') : (),
	      'VERSION_FROM' => 'lib/HTML/RSSAutodiscovery.pm',
	      'PREREQ_PM'    => {
		  'LWP::UserAgent' => 0,
		  'HTTP::Request'  => 0,
		  'HTML::Parser'   => 0,
		  'Test::More'     => 0,
	      },
);
