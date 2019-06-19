#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use MarpaX::Demo::JSONParser; # For the version #.

use Test::More;

use File::Basename;
use File::Slurper;
use Marpa::R2;
use MarpaX::Simple;
use Moo;
use Path::Tiny;
use strict;
use Try::Tiny;
use Types::Standard;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	File::Basename
	File::Slurper
	Marpa::R2
	MarpaX::Simple
	Moo
	Path::Tiny
	strict
	Try::Tiny
	Types::Standard
	warnings
/;

diag "Testing MarpaX::Demo::JSONParser V $MarpaX::Demo::JSONParser::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
