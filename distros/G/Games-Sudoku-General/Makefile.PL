use 5.006002;	# For 'our', at the very least.

use strict;
use warnings;

use lib qw{ inc };

use Config;
use ExtUtils::MakeMaker qw{WriteMakefile prompt};
use FileHandle;
use Getopt::Std;
use My::Module::Meta;
use My::Module::Recommend;

my $meta = My::Module::Meta->new();

my %opt;
getopts( 'ny', \%opt ) or die <<'EOD';
The only legal options are
  -n = answer all questions 'no';
  -y = answer all questions 'yes'.
EOD

my @exe_files;

print <<'EOD';

In addition to Games::Sudoku::General, you can get the following
executable:

  sudokug -- an interactive interface to Games::Sudoku::General.

If you do not want this executable installed, rerun this script
with the -n qualifier.

EOD

if ( $opt{n} ) {
    $opt{y}
	and die "You may not assert both -n and -y\n";
    print "Because you have asserted -n, the executable will not be installed.\n\n";
} else {
    push @exe_files, qw{ sudokug };
}

if (@exe_files) {
    @exe_files = map { "script/$_" } @exe_files;
}


##my $vers = $] >= 5.008 ? '-5.8' : '';
##my $vers = '';

( my $mmv = ExtUtils::MakeMaker->VERSION ) =~ s/_//g;

my %args = (
    ABSTRACT	=> $meta->abstract(),
    AUTHOR	=> $meta->author(),
    DISTNAME	=> $meta->dist_name(),
    EXE_FILES	=> \@exe_files,
    NAME	=> $meta->module_name(),
    PREREQ_PM	=> $meta->requires(),
    PL_FILES	=> {},	# Prevent old MakeMaker from running Build.PL
    realclean	=> {
	FILES => join( ' ', @{ $meta->add_to_cleanup() } ),
    },
    VERSION_FROM	=> $meta->version_from(),
);

$mmv >= 6.31
    and $args{LICENSE} = $meta->license();

if ( $mmv >= 6.4501 ) {
    $args{META_ADD} = {
	no_index => $meta->no_index(),
    };
    $args{META_MERGE} = $meta->meta_merge( $meta->provides() );
}

$mmv >= 6.4701
    and $args{MIN_PERL_VERSION} = $meta->requires_perl();


if ( $mmv >= 6.52 ) {
    $args{BUILD_REQUIRES} = $meta->build_requires();
    $args{CONFIGURE_REQUIRES} = $meta->configure_requires();
} elsif ( $mmv >= 6.5501 ) {
    $args{BUILD_REQUIRES} = $meta->build_requires();
    $args{META_MERGE}{configure_requires} = $meta->configure_requires();
} elsif ( $mmv >= 6.4501 ) {
    $args{META_MERGE}{build_requires} = $meta->build_requires();
    $args{META_MERGE}{configure_requires} = $meta->configure_requires();
} else {
    foreach my $method ( qw{ configure_requires build_requires } ) {
	my $req = $meta->$method();
	foreach my $key ( keys %{ $req } ) {
	    exists $args{PREREQ_PM}{$key}
		or $args{PREREQ_PM}{$key} = $req->{$key};
	}
    }
}

My::Module::Recommend->recommend();

WriteMakefile( %args );

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $test = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(TEST_FILES)' );
    my $structural_test = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(STRUCTURAL_TEST_FILES)' );
    foreach ( $test, $structural_test ) {
	s/ \s+ \z //smx;
	s/ \A \s+ //smx;
    }
    my $optionals = join ',', My::Module::Recommend->optionals();

    return <<"EOD";

STRUCTURAL_TEST_FILES = xt/author/*.t

functional_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) functional_test
	AUTHOR_TESTING=1 $test

optionals_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) optionals_test
	AUTHOR_TESTING=1 PERL5OPT=-MTest::Without::Module=$optionals $test

structural_test :: pure_all
	\$(NOECHO) \$(ECHO)
	\$(NOECHO) \$(ECHO) structural_test
	AUTHOR_TESTING=1 $structural_test

authortest :: functional_test optionals_test structural_test

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=eg/

.PHONY: functional_test optionals_test structural_test authortest testcover

EOD
}

# ex: set textwidth=72 :
