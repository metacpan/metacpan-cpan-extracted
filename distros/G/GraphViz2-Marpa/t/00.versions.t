#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use GraphViz2::Marpa; # For the version #.

use Test::More;

use Algorithm::Diff;
use Capture::Tiny;
use Config;
use Config::Tiny;
use Date::Format;
use Date::Simple;
use File::Basename;
use File::Copy;
use File::HomeDir;
use File::Spec;
use File::Temp;
use File::Which;
use Getopt::Long;
use HTML::Entities::Interpolate;
use Log::Handler;
use Marpa::R2;
use Moo;
use Path::Iterator::Rule;
use Path::Tiny;
use Pod::Usage;
use strict;
use Text::Xslate;
use Tree::DAG_Node;
use Try::Tiny;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Algorithm::Diff
	Capture::Tiny
	Config
	Config::Tiny
	Date::Format
	Date::Simple
	File::Basename
	File::Copy
	File::HomeDir
	File::Spec
	File::Temp
	File::Which
	Getopt::Long
	HTML::Entities::Interpolate
	Log::Handler
	Marpa::R2
	Moo
	Path::Iterator::Rule
	Path::Tiny
	Pod::Usage
	strict
	Text::Xslate
	Tree::DAG_Node
	Try::Tiny
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
