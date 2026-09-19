#!perl

# Every method this distribution ships is documented.
#
# The module list is DERIVED FROM lib/ rather than from blib, and that is not a
# style choice. all_pod_coverage_ok() walks blib, which by then holds the
# Install/Files.pm that ExtUtils::Depends generates on every configure, so the
# stock version of this file failed on a file nobody wrote and nobody ships.
# Deriving from lib/ also means a module added without documentation cannot
# pass by not being in a hardcoded list.

use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

unless ($ENV{RELEASE_TESTING}) {
	plan(skip_all => 'Author tests not required for installation');
}

my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage" if $@;

my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage" if $@;

my @modules;
File::Find::find(sub {
	return unless -f && /\.pm\z/;
	(my $mod = $File::Find::name) =~ s{^lib/}{};
	$mod =~ s{\.pm\z}{};
	$mod =~ s{/}{::}g;
	push @modules, $mod;
}, 'lib');
@modules = sort @modules;

plan tests => scalar(@modules) + 1;

ok(scalar @modules, 'lib holds modules to cover');

# new, prototype and set_prototype are installed into every class by
# Object::Proto::Sugar, and BUILD is the constructor hook it calls: none is this
# distribution's to document. DESTROY is perl's.
pod_coverage_ok(
	$_,
	{ also_private => [qr/\A(?:new|prototype|set_prototype|BUILD|DESTROY)\z/] },
	"$_ is covered, less what Object::Proto::Sugar and perl install"
) for @modules;
