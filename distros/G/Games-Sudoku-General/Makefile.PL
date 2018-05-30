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
getopts ('ny', \%opt) or die <<eod;
The only legal options are
  -n = answer all questions 'no';
  -y = answer all questions 'yes'.
eod

my @exe_files;
my @clean_files;

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

(my $mmv = ExtUtils::MakeMaker->VERSION) =~ s/_//g;
my %attr = (
##  (MM->can ('signature_target') ? (SIGN => 1) : ()),
    NAME => 'Games::Sudoku::General',
    VERSION_FROM => 'lib/Games/Sudoku/General.pm',
    PREREQ_PM => $meta->requires(),
    PL_FILES => {},	# Prevent old MakeMaker from running Build.PL
    EXE_FILES => \@exe_files,
#   'linkext' => {LINKTYPE => ''},
    'dist' => {COMPRESS => 'gzip', SUFFIX => 'gz'},
    realclean => {FILES => join ' ', @clean_files},
    AUTHOR => 'Tom Wyant (wyant at cpan dot org)',
    ABSTRACT => 'Solve Sudoku and related puzzles',
#   BINARY_LOCATION => "$Config{archname}$vers/Games-Sudoku-General.tar.gz",
    realclean	=> { FILES => 'cover_db xt/author/optionals' },
);


$mmv >= 6.31 and $attr{LICENSE} = 'perl';

$mmv >= 6.4501
    and $attr{META_MERGE} = $meta->meta_merge();

$mmv >= 6.4701 and $attr{MIN_PERL_VERSION} = $meta->requires_perl();

$mmv >= 6.5501
    and $attr{BUILD_REQUIRES} = $meta->build_requires()
    or $mmv >= 6.4501
    and $attr{META_MERGE}{build_requires} = $meta->build_requires();

My::Module::Recommend->recommend();

WriteMakefile(%attr);

sub MY::postamble {
    my ( $self ) = @_;	# @args unused.

    my $authortest = $self->test_via_harness(
	'$(FULLPERLRUN)', '$(AUTHORTEST_FILES)' );
    $authortest =~ s/ \s+ \z //smx;
    $authortest =~ s/ \A \s+ //smx;
    chomp $authortest;

    return <<"EOD";

AUTHORTEST_FILES = t/*.t xt/author/*.t xt/author/optionals/*.t

authortest :: pure_all
	\$(FULLPERLRUN) "-Iinc" "-MMy::Module::Recommend" "-e" "My::Module::Recommend->make_optional_modules_tests()"
	AUTHOR_TESTING=1 $authortest

testcover :: pure_all
	cover -test -ignore_re=inc/mock/
EOD
}

# ex: set textwidth=72 :
