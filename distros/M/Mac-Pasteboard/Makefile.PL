use 5.006002;

use strict;
use warnings;

$^O eq 'darwin'
    or die "OS unsupported\n";

use lib qw{ inc };

use Config;
use ExtUtils::MakeMaker;
use Getopt::Std;
use My::Module::Meta;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my %opt;
getopts ('ntuy', \%opt) or die <<'EOD';
The only legal options are
  -n = answer all questions 'no';
  -t = use traditional Mac default text flavor;
  -u = use UTF-8 as default text flavor;
  -y = answer all questions 'yes'.
You may not assert both -n and -y, nor both -t and -u.
The default text flavor is UTF-8 for macOS 10.14 Mojave and later, and
traditional for 10.13 High Sierra and earlier.
EOD

my $meta = My::Module::Meta->new();

my @exe_files;
my @clean_files;

$meta->want_pbtool( \%opt )
    and push @exe_files, 'script/pbtool';

push @clean_files, 'pbl';	# Just in case we built it.

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;

my @ccflags = $meta->ccflags( \%opt );

my %args = (
    ABSTRACT	=> $meta->abstract(),
    AUTHOR	=> $meta->author(),
    (@ccflags ? (CCFLAGS => join ' ', @ccflags) : ()),
    DISTNAME	=> $meta->dist_name(),
    EXE_FILES	=> \@exe_files,
    INC		=> '-I.', # e.g., '-I. -I/usr/include/other'
    LDDLFLAGS	=> $Config{lddlflags} . ' -framework ApplicationServices',
    LIBS	=> [''], # e.g., '-lm'
    NAME	=> $meta->module_name(),
    OBJECT	=> '$(O_FILES)', # link all the C files too
    PREREQ_PM	=> $meta->requires(),
    PL_FILES	=> {},	# Prevent old MakeMaker from running Build.PL
    realclean	=> {
	FILES => join( ' ', @{ $meta->add_to_cleanup() }, @clean_files ),
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

WriteMakefile( %args );

sub MY::postamble {
    my ( $self, @args ) = @_;

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t

authortest :: pure_all
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/ -ignore_re=/System
EOD
}

=begin comment

sub MY::postamble {
    <<'eod';

pbl : pbl.c
	$(CC) -o pbl -DTEST $(PBL_FLAGS) pbl.c -framework ApplicationServices
eod
}

=end comment

=cut

# ex: set textwidth=72 :
