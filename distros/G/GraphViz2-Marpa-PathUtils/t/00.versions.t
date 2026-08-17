#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use GraphViz2::Marpa; # For the version #.

use Test::More;

use Capture::Tiny;
use Config;
use Config::Tiny;
use Date::Simple;
use ExtUtils::MakeMaker;
use File::Basename;
use File::Copy;
use File::HomeDir;
use File::Spec;
use File::Temp;
use Getopt::Long;
use GraphViz2::Marpa;
use GraphViz2::Marpa::Renderer::Graphviz;
use Moo;
use open qw(:std :utf8);
use parent;
use Path::Tiny;
use Pod::Usage;
use Set::Tiny;
use Sort::Key;
use strict;
use Test::More;
use Text::Xslate;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Capture::Tiny
	Config
	Config::Tiny
	Date::Simple
	ExtUtils::MakeMaker
	File::Basename
	File::Copy
	File::HomeDir
	File::Spec
	File::Temp
	Getopt::Long
	GraphViz2::Marpa
	GraphViz2::Marpa::Renderer::Graphviz
	Moo
	open
	parent
	Path::Tiny
	Pod::Usage
	Set::Tiny
	Sort::Key
	strict
	Test::More
	Text::Xslate
	Types::Standard
	warnings
/;

diag "Testing GraphViz2::Marpa V $GraphViz2::Marpa::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
