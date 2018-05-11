#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Genealogy::Gedcom::Date; # For the version #.

use Test::More;

use Config;
use Data::Dumper::Concise;
use Getopt::Long;
use Log::Handler;
use Marpa::R2;
use Moo;
use Pod::Usage;
use strict;
use Try::Tiny;
use Types::Standard;
use utf8;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Config
	Data::Dumper::Concise
	Getopt::Long
	Log::Handler
	Marpa::R2
	Moo
	Pod::Usage
	strict
	Try::Tiny
	Types::Standard
	utf8
	warnings
/;

diag "Testing Genealogy::Gedcom::Date V $Genealogy::Gedcom::Date::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
