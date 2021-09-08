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

( my $mbv = Module::Build->VERSION ) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    add_to_cleanup	=> $meta->add_to_cleanup(),
    build_requires	=> $meta->build_requires(),
    configure_requires	=> $meta->configure_requires(),
    dist_abstract	=> $meta->abstract(),
    dist_author	=> $meta->author(),
    dist_name	=> $meta->dist_name(),
    get_options	=> { y => {}, n => {} },
    license	=> $meta->license(),
    module_name	=> $meta->module_name(),
    requires	=> $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
);

if ( $mbv >= 0.28 ) {
    $args{meta_merge} = $meta->meta_merge();
    $args{no_index} = $meta->no_index();
    $args{meta_add} = {
	$meta->provides(),
    },
}

# Don't require Module::Build if we're making a distribution, since the
# the user may simply prefer ExtUtils::MakeMaker.

$mbv >= 0.34
    and $args{auto_configure_requires} = ! $meta->distribution();

#	Generate a builder object.

my $bldr = My::Module::Build->new( %args );

#	Find out what the user wants to do.

my %opt = $bldr->args();

my @exe_files;

my @possible_exes = ('sudokug');
print <<'EOD';

In addition to Games::Sudoku::General, you can get the following
executable:

  sudokug -- an interactive interface to Games::Sudoku::General.

If you do not want this, run Build.PL with the -n option.

EOD


if ( $opt{n} ) {
    $opt{y}
	and die "You may not assert both -n and -y\n";
    print "Because you have asserted -n, the executables will not be installed.\n\n";
} else {
    @exe_files = @possible_exes;
}

if ( @exe_files ) {
    @exe_files = map { "script/$_" } @exe_files;
}

##my $vers = $] >= 5.008 ? '-5.8' : '';

#	Recommend modules

My::Module::Recommend->recommend();

#	Tell Module::Build what we want to do.

$bldr->script_files( \@exe_files );

#	Generate the build script, at long last.

$bldr->create_build_script();

# ex: set textwidth=72 :
