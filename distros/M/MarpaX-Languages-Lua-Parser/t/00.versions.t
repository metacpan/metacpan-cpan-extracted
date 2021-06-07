#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use MarpaX::Languages::Lua::Parser; # For the version #.

use Test::More;

use Data::RenderAsTree;
use Data::Section::Simple;
use File::Spec;
use File::Temp;
use Getopt::Long;
use Log::Handler;
use Marpa::R2;
use Moo;
use Path::Tiny;
use Pod::Usage;
use strict;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Data::RenderAsTree
	Data::Section::Simple
	File::Spec
	File::Temp
	Getopt::Long
	Log::Handler
	Marpa::R2
	Moo
	Path::Tiny
	Pod::Usage
	strict
	Types::Standard
	warnings
/;

diag "Testing MarpaX::Languages::Lua::Parser V $MarpaX::Languages::Lua::Parser::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
