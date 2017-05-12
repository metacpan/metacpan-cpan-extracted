use strict;
use ExtUtils::MakeMaker;
eval "use Test::Manifest";

unless( $@ )
	{
	* ExtUtils::MM_Any::test_via_harness = sub
		{
		my($self, $perl, $tests) = @_;
		
		return qq|\t$perl "-MTest::Manifest" | .
			qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', | .
			qq|'\$(INST_ARCHLIB)')"\n|;
		}
	}

WriteMakefile(
	'NAME'          => 'List::Rotation::Cycle',
	'VERSION_FROM'  => 'lib/List/Rotation/Cycle.pm',
	'LICENSE'       => 'perl',
    'ABSTRACT'      => 'Cycle through a list of values via a singleton object implemented as closure. ',
    'AUTHOR'        => 'pelagic',
    'SIGN'          => 1,

 
	'PREREQ_PM'		=> {
		'Test::More'       => '0',
		'Memoize'          => '0',
    },
    
	'MAN3PODS'      => {'lib/List/Rotation/Cycle.pm'  => '$(INST_MAN3DIR)/List::Rotation::Cycle.3'},
	'clean' => { FILES => 'List-Rotation-Cycle-*' },
);

