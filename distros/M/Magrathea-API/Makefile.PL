
use strict;
use warnings;
use 5.10.0;

use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my $preop =
    'pod2text $(VERSION_FROM) | tee $(DISTVNAME)/README > README;' .
    'pod2markdown $(VERSION_FROM) | tee $(DISTVNAME)/README.md > README.md;' .
    'pod2markdown lib/Magrathea/API/Emergency.pm | tee $(DISTVNAME)/Emergency.md > Emergency.md;';


WriteMakefile(
    NAME              => 'Magrathea::API',
    VERSION_FROM      => 'lib/Magrathea/API.pm', # finds $VERSION
    PREREQ_PM         => {
	Carp		=> 0,
	enum		=> 0,
	'Net::Telnet'	=> 3.03,
	'Phone::Number'	=> 0.01,
	'Email::Address'=> 1.892,
	'Data::Dumper'	=> 0,
        'Attribute::Boolean' => v1.0.8,
    }, 
    TEST_REQUIRES       => {
        'Text::Autoformat' => 0,
    },
    ABSTRACT_FROM  => 'lib/Magrathea/API.pm', # retrieve abstract from module
    AUTHOR         => 'Cliff Stanford <cliff@may.be>',
    MIN_PERL_VERSION => 5.10.0,
    dist    => {
        PREOP   => $preop,
    },
);
