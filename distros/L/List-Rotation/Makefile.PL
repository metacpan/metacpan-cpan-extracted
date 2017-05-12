use strict;
use ExtUtils::MakeMaker;
eval "use Test::Manifest";

unless( $@ )
    {
    * ExtUtils::MM_Any::test_via_harness = sub
        {
        my($self, $perl, $tests) = @_;

        return qq|\t$perl "-MTest::Manifest" |
             . qq|"-e" "run_t_manifest(\$(TEST_VERBOSE), '\$(INST_LIB)', |
             . qq|'\$(INST_ARCHLIB)')"\n|;
        }
    }

WriteMakefile(
    'NAME'          => 'List::Rotation',
    'VERSION_FROM'  => 'lib/List/Rotation.pm',
    'LICENSE'       => 'perl',
    'ABSTRACT'      => 'Loop (Cycle, Alternate or Toggle) through a list of values via a singleton object implemented as closure.',
    'AUTHOR'        => 'pelagic',
    'SIGN'          => 1,

    'PREREQ_PM'     => {
        'Test::More'   => '0',
        'Memoize'      => '0',
    },

    'MAN3PODS'      => { 'lib/List/Rotation.pm'  => '$(INST_MAN3DIR)/List::Rotation.3', },
    'clean'         => { FILES          => 'List-Rotation-*' },
);

