

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'FedoraCommons::APIM',
    VERSION_FROM => 'lib/FedoraCommons/APIM.pm', # finds \$VERSION
    AUTHOR       => 'David L. Fielding (dlf2@cornell.edu)',
    ABSTRACT     => 'Implements Fedora Commons Repository APIM api interface.',
    PREREQ_PM    => {
	'Test::Simple'        => 0.44,
	'MIME::Base64'        => 3.03,
	'SOAP::Lite'          => 0.67,
	'Time::HiRes'         => 1.59,
	'Carp'                => 1.03,
	'LWP'                 => 5.800,
	'POSIX'               => 1.08,
	'HTML::Template'      => 2.9,
    },
);
