#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use MarpaX::Languages::SVG::Parser; # For the version #.

use Test::More;

use Capture::Tiny;
use Config;
use Config::Tiny;
use Data::Section::Simple;
use Date::Simple;
use Encode;
use File::Basename;
use File::Copy;
use File::HomeDir;
use File::Slurper;
use File::Spec;
use File::Temp;
use Getopt::Long;
use Log::Handler;
use Marpa::R2;
use Moo;
use Path::Tiny;
use Pod::Usage;
use Set::Array;
use strict;
use Text::CSV;
use Text::Xslate;
use Types::Standard;
use utf8;
use warnings;
use XML::Parser;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Capture::Tiny
	Config
	Config::Tiny
	Data::Section::Simple
	Date::Simple
	Encode
	File::Basename
	File::Copy
	File::HomeDir
	File::Slurper
	File::Spec
	File::Temp
	Getopt::Long
	Log::Handler
	Marpa::R2
	Moo
	Path::Tiny
	Pod::Usage
	Set::Array
	strict
	Text::CSV
	Text::Xslate
	Types::Standard
	utf8
	warnings
	XML::Parser
/;

diag "Testing MarpaX::Languages::SVG::Parser V $MarpaX::Languages::SVG::Parser::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
