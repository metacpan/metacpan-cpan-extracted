#/usr/bin/env perl

use strict;
use warnings;

# I tried 'require'-ing modules but that did not work.

use Log::Handler::Plugin::DBI; # For the version #.

use Test::More;

use Carp;
use Config::Plugin::Tiny;
use DBD::SQLite;
use DBIx::Admin::CreateTable;
use DBIx::Connector;
use File::HomeDir;
use File::Spec;
use Log::Handler::Output::DBI;
use Moo;
use strict;
use Test::More;
use Test::Pod;
use vars;
use warnings;

# ----------------------

pass('All external modules loaded');

my(@modules) = qw
/
	Carp
	Config::Plugin::Tiny
	DBD::SQLite
	DBIx::Admin::CreateTable
	DBIx::Connector
	File::HomeDir
	File::Spec
	Log::Handler::Output::DBI
	Moo
	strict
	Test::More
	Test::Pod
	vars
	warnings
/;

diag "Testing Log::Handler::Plugin::DBI V $Log::Handler::Plugin::DBI::VERSION";

for my $module (@modules)
{
	no strict 'refs';

	my($ver) = ${$module . '::VERSION'} || 'N/A';

	diag "Using $module V $ver";
}

done_testing;
