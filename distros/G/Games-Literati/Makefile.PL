use ExtUtils::MakeMaker;
require 5.008;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
%mm_args = (
    'NAME'		    => 'Games::Literati',
    'VERSION_FROM'	=> 'lib/Games/Literati.pm',
    'PREREQ_PM'		=> {'Exporter' => 0},
    'ABSTRACT_FROM' => 'lib/Games/Literati.pm',
    'AUTHOR'        => 'Peter C. jones <petercj AT cpan.org>, Chicheng Zhang',
);

{
    no warnings;
    if( $ExtUtils::MakeMaker::VERSION >= '6.31' ) {
        $mm_args{LICENSE} = 'perl_5';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.46' ) {
        $mm_args{META_MERGE} = {
            'meta-spec' => {
                version => '2',
                url     => 'http://search.cpan.org/perldoc?CPAN::Meta::Spec',
            },
            resources => {
                bugtracker => {
                    web     => 'https://github.com/pryrt/Games-Literati/issues',
                },
                repository => {
                    url     => 'https://github.com/pryrt/Games-Literati.git',
                    web     => 'https://github.com/pryrt/Games-Literati',
                    type    => 'git',
                },
            },
        keywords => [ 'Scrabble', 'Literati', 'Words with Friends', 'tile', 'word', 'game' ],
        };
        # automatically determine the versions for 'provides'; MM->parse_version exists as of MM v6.31, so not a problem with >= 6.46
        #   => this comes out right when printed... but MYMETA.* shows values that look wrong
        my $v = ''.MM->parse_version( $mm_args{VERSION_FROM} );
        $mm_args{META_MERGE}{provides} = {
            'Games::Literati' => {
                file => 'lib/Games/Literati.pm',
                version => $v,
            },
        };
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.48' ) {
        $mm_args{MIN_PERL_VERSION} = '5.8.0';
    }
    if( $ExtUtils::MakeMaker::VERSION >= '6.64' ) {
        $mm_args{TEST_REQUIRES} = {
            'warnings' => 0,
            'strict' => 0,
            'Test::More' => 0,
            'File::Basename' => 0,
            'Cwd' => 0,
            'IO::String' => 0,
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
testcover ::
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
	$(NOECHO) ( $(TEST_F) LICENSE.pod && $(RM_RF) LICENSE.pod ) || $(ECHO) realclean:: LICENSE.pod intermediary
	$(NOECHO) ( $(TEST_F) README.pod && $(RM_RF) README.pod ) || $(ECHO) realclean:: README.pod intermediary
	$(NOECHO) ( $(TEST_F) MYMETA.json.lock && $(RM_RF) MYMETA.json.lock ) || $(ECHO) realclean:: MYMETA.json.lock temp file

# veryclean: runs realclean, then deletes .bak, .old, .orig, and similar

# auto-generate the README from the lib/Games/Literati.pm
README.md :: lib/Games/Literati.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(README.pod));$$p->select({head1 => [qq(NAME),qq(SYNOPSIS),qq(DESCRIPTION),qq(LIMITATIONS),qq(INSTALLATION),qq(TODO),qq(AUTHOR),qq(COPYRIGHT),qq(LICENSE)], head2=>[]});$$p->parse_file(qq(lib/Games/Literati.pm));'
	pod2markdown README.pod README.md
	$(RM_F) README.pod

# auto-generate the LICENSE file from the lib/Games/Literati.pm
LICENSE :: lib/Games/Literati.pm Makefile.PL
	$(PERL) -MPod::Simple::Select -e 'my $$p = Pod::Simple::Select->new();$$p->output_file(qq(LICENSE.pod));$$p->select({head1 => [qw/AUTHOR COPYRIGHT LICENSE/]});$$p->parse_file(qq(lib/Games/Literati.pm));'
	pod2text LICENSE.pod LICENSE
	$(RM_F) LICENSE.pod

docs :: README.md LICENSE manifest

POSTAMBLE
}



WriteMakefile( %mm_args );
