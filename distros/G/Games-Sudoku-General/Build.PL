use 5.006002;	# For 'our', at the very least.

use strict;
use warnings;

use lib qw{ inc };

use My::Module::Build;

use Config;
use FileHandle;
use Module::Build;
use My::Module::Meta;
use My::Module::Recommend;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %attr = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Solve Sudoku and related puzzles',
    module_name => 'Games::Sudoku::General',
    requires => $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    build_requires	=> $meta->build_requires(),
    configure_requires	=> {},	# Don't require Module::Build.
    get_options => {y => {}, n => {}},
    license => 'perl',
    add_to_cleanup	=> [ qw{ cover_db xt/author/optionals } ],
);

$mbv >= 0.28
    and $attr{meta_merge} = $meta->meta_merge();

# Don't require Module::Build if we're making a distribution, since the
# the user may simply prefer ExtUtils::MakeMaker.

$mbv >= 0.34
    and $attr{auto_configure_requires} = !$meta->distribution();

#	Generate a builder object.

my $bldr = My::Module::Build->new (%attr);

#	Find out what the user wants to do.

my %opt = $bldr->args ();

my @exe_files;
my @clean_files;

my @possible_exes = ('sudokug');
print <<'EOD';

In addition to Games::Sudoku::General, you can get the following
executable:

  sudokug -- an interactive interface to Games::Sudoku::General.

If you do not want this, run Build.PL with the -n option.

EOD


if ($opt{n}) {
    $opt{y}
	and die "You may not assert both -n and -y\n";
    print "Because you have asserted -n, the executables will not be installed.\n\n";
} else {
    @exe_files = @possible_exes;
}

if (@exe_files) {
    @exe_files = map { "script/$_" } @exe_files;
}

##my $vers = $] >= 5.008 ? '-5.8' : '';

#	Recommend modules

My::Module::Recommend->recommend();

#	Tell Module::Build what we want to do.

$bldr->add_to_cleanup (\@clean_files);
$bldr->script_files (\@exe_files);

#	Generate the build script, at long last.

$bldr->create_build_script ();

# ex: set textwidth=72 :
