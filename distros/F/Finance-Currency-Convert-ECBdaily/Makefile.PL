use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'Finance::Currency::Convert::ECBdaily',
    'VERSION_FROM'	=> 'lib/Finance/Currency/Convert/ECBdaily.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'strict'        => 0,
        'warnings'      => 0,
        'LWP::Simple'   => '6.0',

    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
        (ABSTRACT_FROM => 'lib/Finance/Currency/Convert/ECBdaily.pm', # retrieve abstract from module
        AUTHOR     => 'Details <details -at- cpan -dot- org>') : ()
    ),

    BUILD_REQUIRES => {
     	  'Test::More' => '0.47'
    },
);
