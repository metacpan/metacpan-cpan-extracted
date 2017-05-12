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

my @PL_files;
foreach my $if (qw{Pasteboard.xs constant-c.inc constant-h.inc
    constant-xs.inc pbl.c pbl.h ppport.h}) {
    my $of = 'lib/Mac/' . $if;
    push @PL_files, $of;
}

(my $mbv = Module::Build->VERSION) =~ s/_//g;

my $meta = My::Module::Meta->new();

my @ccflags = $meta->ccflags();

my %attr = (
    dist_author => 'Tom Wyant (wyant at cpan dot org)',
    dist_abstract => 'Manipulate Mac OS X pasteboards',
    module_name => 'Mac::Pasteboard',
    dist_name => 'Mac-Pasteboard',
    dist_version_from => 'lib/Mac/Pasteboard.pm',
    get_options => {y => {}, n => {}},
    dynamic_config => 1,
    license => 'perl',
    requires => $meta->requires(
	perl	=> $meta->requires_perl(),
    ),
    build_requires => $meta->build_requires(
	$meta->distribution() ? () : (
	    'ExtUtils::CBuilder' => 0,
	),
    ),
    config => {
	lddlflags => $Config{lddlflags} . ' -framework ApplicationServices',
    },
    PL_files => {
	'MBCopy.PL' => \@PL_files,
    },
    c_source => 'lib/Mac',	# We rely on MBCopy.PL to put them there.
    (@ccflags ?
	(extra_compiler_flags => \@ccflags) :
	()
    ),
    add_to_cleanup	=> [ qw{ cover_db *.gcov *.gcda *.gcno } ],
);

$mbv >= 0.28
    and $attr{meta_merge} = $meta->meta_merge();

$mbv >= 0.34
    and $attr{auto_configure_requires} = 0;	# Don't require Module::Build

my $bldr = My::Module::Build->new (%attr);

my %opt = $bldr->args ();
my @exe_files;

$meta->want_pbtool( \%opt, $bldr )
    and push @exe_files, 'script/pbtool';

$bldr->script_files (\@exe_files);

$bldr->create_build_script ();
