

use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME         => 'FedoraCommons::APIA',
    VERSION_FROM => 'lib/FedoraCommons/APIA.pm', # finds \$VERSION
    AUTHOR       => 'David L. Fielding (dlf2@cornell.edu)',
    ABSTRACT     => 'Implements Fedora Commons Repository APIA interface.',
    PREREQ_PM    => {
	'Test::Simple' => 0.44,
	'SOAP::Lite'   => 0.67,
	'Time::HiRes'  => 1.59, 
	'Carp'         => 1.03,
	},
);
