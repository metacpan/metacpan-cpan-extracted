#!/usr/bin/perl -w
#
# Compile Testing for Kephra:
#     looking if all expected Modules are there and do compile
#

BEGIN {
	chdir '..' if -d '../t';
	$| = 1;
	#unshift @INC, './lib', '../lib';
}

use strict;
use warnings;

use lib 'lib';
#use blib;
use Test::More;
use Test::Script;
use Test::NoWarnings;

use File::Find qw(find);
my @required_modules = qw(
	Cwd File::Find File::Spec::Functions 
	Config::General YAML::Tiny Wx Wx::Perl::ProcessStream
);
my $modules = 68;
my @kephra_modules;
find( sub {
    return if not -f $_ or $_ !~ /\.pm$/;
    my $module = $File::Find::name;
    $module =~ s{lib/}{};
    $module =~ s{\.pm}{};
    $module =~ s{/}{::}g;
    return if $module eq 'Kephra::Edit::Search::InputTarget';
    push @kephra_modules, $module;
}, 'lib'); # print "@modules"; #use Data::Dumper; # diag Dumper \@modules;

my $tests = 4 + @required_modules + @kephra_modules;
plan tests => $tests;

ok( $] >= 5.006, 'Your perl is new enough' );

require_ok($_) for @required_modules, @kephra_modules;

cmp_ok( scalar(@kephra_modules), '==', $modules, "$modules Kephra modules found" );
use_ok('Kephra', 'main module compiles');


TODO:{
	# check the starter
	local $TODO = '"todo header"'; # tells what to do
	#script_compiles_ok('bin/kephra','starter compiles');
}
exit(0);
