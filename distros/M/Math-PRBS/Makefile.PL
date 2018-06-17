use ExtUtils::MakeMaker;
use 5.006;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'          => 'Math::PRBS',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>',
    'VERSION_FROM'  => 'lib/Math/PRBS.pm',
    'ABSTRACT_FROM' => 'lib/Math/PRBS.pm',
    'PREREQ_PM'     => {
        'Exporter'      => 5.57,    # needed for `use Exporter qw(import);` notation
        'version'       => 0.77,
        'warnings'      => 0,
        'strict'        => 0,
        'Carp'          => 0,
    },
);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.46' ) {
        $mm_args{META_MERGE} = {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    mailto  => 'bug-Math-PRBS@rt.cpan.org',
                    web     => 'https://github.com/pryrt/Math-PRBS/issues',
                },
                repository => {
                    url     => 'https://github.com/pryrt/Math-PRBS.git',
                    web     => 'https://github.com/pryrt/Math-PRBS',
                    type    => 'git',
                },
            },
            keywords => [ 'Pseudorandom Binary Sequence', 'PRBS', 'Linear Feedback Shift Register', 'LFSR'],
        },
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        #   => this comes out right when printed... but MYMETA.* shows values that look wrong
        $mm_args{META_MERGE}{provides} = {
            $mm_args{NAME} => {
                file => $mm_args{VERSION_FROM},
                version => ''.MM->parse_version( $mm_args{VERSION_FROM} ),
            }
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.6.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.52' ) {
        $mm_args{CONFIGURE_REQUIRES} = {
            'ExtUtils::MakeMaker' => 0,
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
        },
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0.86,
            'constant' => 0,
            'Config' => 0,
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.18' ) {
        $mm_args{SIGN} = 1 if MM->can('signature_target') && $ENV{MM_SIGN_DIST};
    }
}

sub MY::postamble {
    my (undef,%h) = @_;
    #require Data::Dumper;
    #print STDERR Data::Dumper->Dump([\%h], [qw(mm_args{postamble})]);
    return <<'POSTAMBLE';
# TEST_D is used to test for the existence of a directory
TEST_D = $(ABSPERLRUN) -MExtUtils::Command -e test_d --

# run a test coverage report
testcover :: lib/Math/PRBS.pm
	$(NOECHO) cover -test -report html

# run author-tests on the original
authtest ::
	$(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# run author-tests on the distribution
distauthtest :: disttest
	cd $(DISTVNAME) && $(TEST_D) xt && $(MAKE) test TEST_FILES='xt/*.t'

# addition to realclean: also delete coverage database, if testcover was run
realclean ::
	$(NOECHO) ( $(TEST_D) cover_db && $(RM_RF) cover_db ) || $(ECHO) realclean:: skip "rm -rf cover_db"
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: skip "rm -rf MYMETA.json.lock"

# auto-generate the README from the lib/Math/PRBS.pm
README.md :: lib/Math/PRBS.pm
	podselect -section "NAME|SYNOPSIS|DESCRIPTION|INSTALLATION|AUTHOR|COPYRIGHT|LICENSE" lib/Math/PRBS.pm > README.pod
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/Math/PRBS.pm
LICENSE :: lib/Math/PRBS.pm
	podselect -section "AUTHOR|COPYRIGHT|LICENSE" lib/Math/PRBS.pm > LICENSE.pod
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: README.md LICENSE

POSTAMBLE
}

WriteMakefile( %mm_args )
