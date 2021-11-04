use 5.006002;

use strict;
use warnings;

use lib qw{ inc };

$^O eq 'darwin'
    or die "OS unsupported\n";

use Module::Build;
use My::Module::Build;
use My::Module::Meta;
use Config;

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my %args = (
    add_to_cleanup	=> $meta->add_to_cleanup(),
    build_requires	=> $meta->build_requires(),
    c_source	=> 'lib/Mac',	# We rely on MBCopy.PL to put them there.
    config	=> {
	lddlflags => $Config{lddlflags} . ' -framework ApplicationServices',
    },
    configure_requires	=> $meta->configure_requires(),
    dist_abstract	=> $meta->abstract(),
    dist_author	=> $meta->author(),
    dist_name	=> $meta->dist_name(),
    license	=> $meta->license(),
    module_name	=> $meta->module_name(),
    requires	=> $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    script_files	=> [],
);

$mbv >= 0.26
    and $args{get_options} = {
	n	=> { type => '!' },
	p	=> { type => '!' },
	t	=> { type => '!' },
	u	=> { type => '!' },
	y	=> { type => '!' },
    };

if ( $mbv >= 0.28 ) {
    $args{meta_merge} = $meta->meta_merge();
    $args{no_index} = $meta->no_index();
    $args{meta_add} = {
	$meta->provides(),
    },
}

$mbv >= 0.34
    and $args{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new ( %args );

my %opt = $bldr->args();
my @exe_files;

$meta->want_pbtool( \%opt, $bldr )
    and push @exe_files, 'script/pbtool';

$bldr->script_files( \@exe_files );

$bldr->extra_compiler_flags( $meta->ccflags( \%opt ) );

$bldr->my_pl_files(
    $opt{p} ?
    [ qw{ Pasteboard.xs constant-c.inc constant-h.inc constant-xs.inc pbl.c pbl.h ppport.h } ] :
    [ qw{ Pasteboard.xs constant-xs.inc ppport.h } ],
);

$bldr->create_build_script ();

# ex: set textwidth=72 :
