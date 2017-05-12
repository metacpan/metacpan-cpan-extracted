use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'Apache::Earlybird',
    'VERSION_FROM' => 'Earlybird.pm', # finds $VERSION
    'PREREQ_PM' => { 'Apache::Constants' => 1.09,
	             'Mail::Sendmail' => 0.78,
		     'Net::DNS' => 0.12,
		     'Cache::Cache' => 0.08,
		     'Time::Zone' => 2.20,
		     'HTTP::Request' => 1.26,
                     'LWP::UserAgent' => 1.66 }, 

   ($] >= 5.005 ? ## Add these new keywords supported since 5.005

    (ABSTRACT => 'The Earlybird gets the worm. Responds to CodeRed and Nimda worm attacks with e-mail warnings.',
     AUTHOR => 'Ronald Florence <ron@18james.com>') :
     ()),
);
