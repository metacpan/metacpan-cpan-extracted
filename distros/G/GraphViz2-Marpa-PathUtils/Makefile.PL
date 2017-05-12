use strict;
use warnings;

use Config;

use ExtUtils::MakeMaker;

use File::Spec;
use File::Temp;

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

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

my(%params) =
(
	($] ge '5.005') ?
	(
		AUTHOR   => 'Ron Savage (ron@savage.net.au)',
		ABSTRACT => 'Provide various analyses of Graphviz dot files',
	) : (),
	clean =>
	{
		FILES => 'blib/* Makefile MANIFEST GraphViz2-Marpa-PathUtils-*'
	},
	dist =>
	{
		COMPRESS => 'gzip',
		SUFFIX   => 'gz'
	},
	DISTNAME  => 'GraphViz2-Marpa-PathUtils',
	NAME      => 'GraphViz2::Marpa::PathUtils',
	LICENSE   => 'artistic_2',
	PL_FILES  => {},
	PL_FILES  => {},
	PREREQ_PM =>
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
		'Test::More'       => 0.98,
#		'Test::Pod'        => 1.45, # Make it optional. See t/pod.t
		'Text::Xslate'     => '3.3.3',
		'Types::Standard'  => 1.000005,
		'warnings'         => 0,
	},
	VERSION_FROM => 'lib/GraphViz2/Marpa/PathUtils.pm',
);

if ( ($ExtUtils::MakeMaker::VERSION =~ /^\d\.\d\d$/) && ($ExtUtils::MakeMaker::VERSION > 6.30) )
{
	$params{LICENSE} = 'artistic_2';
}

if ($ExtUtils::MakeMaker::VERSION ge '6.46')
{
	$params{META_MERGE} =
	{
		'meta-spec' =>
		{
			version => 2,
		},
		resources   =>
		{
			bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=GraphViz2-Marpa-PathUtils',
			license    => 'http://opensource.org/licenses/Artistic-2.0',
			repository =>
			{
				type => 'git',
				url  => 'https://github.com/ronsavage/GraphViz2-Marpa-PathUtils.git',
				web  => 'https://github.com/ronsavage/GraphViz2-Marpa-PathUtils',
			},
		},
	};
}

WriteMakefile(%params);
