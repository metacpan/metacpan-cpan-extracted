use strict;
use warnings;

use Config;

use File::Spec;
use File::Temp;

use Module::Build;

# -----------------------------------------------

sub is_dot_installed
{
	# 1: Create a temp file containing DOT commands.
	# The EXLOCK option is for BSD-based systems.
	# newdir() croaks() if it fails, which is what we want.
	# Hence there is no need to use Try::Tiny.

	my($temp_dir) = File::Temp -> newdir('temp.XXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
	my($gv_file)  = File::Spec -> catfile($temp_dir, 'test.gv');

	# We use the deprecated 2-argument form of open in case
	# this code is run on an ancient version of Perl.

	open(OUT, ">$gv_file")                   || die "Can't create temp file: $!\n";
	print OUT "digraph graph_14 {node_14}\n" || die "Can't write to temp file: $!\n";
	close OUT                                || die "Can't close temp file: $!\n";

	# 2: Run dot to create an SVG file.

	my $stdout = `dot -Tsvg $gv_file`;

	# 3: If that failed, we die.

	die "Please install Graphviz from http://www.graphviz.org/\n" if ($stdout !~ m|</svg>|);

} # End of is_dot_installed.

# -----------------------------------------------

sub is_perl_recent
{
	# We want Perl V 5.12 or later, because we 'use feature qw/say unicode_strings/'.

	my(@version) = split(/\./, $Config{version});

	die "Please install Perl V 5.12 or later\n" if ($version[1] < 12);

} # End of is_perl_recent.

# -----------------------------------------------

is_dot_installed();
is_perl_recent();

Module::Build -> new
(
	module_name    => 'GraphViz2::Marpa::PathUtils',
	license        => 'artistic_2',
	dist_abstract  => 'Provide various analyses of Graphviz dot files',
	dist_author    => 'Ron Savage <ron@savage.net.au>',
	build_requires =>
	{
		'Test::More' => 0.98,
#		'Test::Pod'  => 1.45, # Make it optional. See t/pod.t
	},
	configure_requires =>
	{
		'Module::Build' => 0.3800,
	},
	meta_merge =>
	{
		resources =>
		{
			repository => 'https://github.com/ronsavage/GraphViz2-Marpa-PathUtils',
		},
	},
	requires =>
	{
		'Capture::Tiny'    => 0.27,
		'Config'           => 0,
		'Config::Tiny'     => 2.20,
		'Date::Simple'     => 3.03,
		'File::Basename'   => 2.84,
		'File::Copy'       => 2.21,
		'File::HomeDir'    => 0.99,
		'File::Spec'       => 0,
		'File::Temp'       => 0,
		'Getopt::Long'     => 2.38,
		'GraphViz2::Marpa' => 2.03,
		'GraphViz2::Marpa::Renderer::Graphviz' => 2.03,
		'Moo'              => 1.006001,
		'open'             => 0,
		'parent'           => 0.225,
		'Path::Tiny'       => 0.061,
		'Pod::Usage'       => 1.36,
		'Set::Tiny'        => 0.02,
		'Sort::Key'        => 1.33,
		'strict'           => 0,
		'Text::Xslate'     => '3.3.3',
		'Types::Standard'  => 1.000005,
		'warnings'         => 0,
	},
) -> create_build_script();
