#!perl
use 5.010;
use strict;
use warnings;
use File::Find ();
use Test::More;

# Every module loads, every version agrees, and the list of modules is CHECKED
# AGAINST THE TREE rather than maintained by hand. A hand-kept list is a list
# that silently stops covering the module somebody added last week.

my @MODULES;
File::Find::find({
	no_chdir => 1,
	wanted   => sub {
		return unless /\.pm\z/;
		my $module = $File::Find::name;
		$module =~ s{\Alib/}{};
		$module =~ s{\.pm\z}{};
		$module =~ s{/}{::}g;
		push @MODULES, $module;
	},
}, 'lib');

@MODULES = sort @MODULES;

plan tests => 4;

subtest 'every module under lib loads' => sub {
	plan tests => scalar @MODULES;
	for my $module (@MODULES) {
		use_ok($module) or BAIL_OUT("$module does not load");
	}
};

subtest 'and the tree holds what it should' => sub {
	cmp_ok(scalar @MODULES, '>=', 11, 'eleven modules or more');
	ok((grep { $_ eq 'Game::Oware' } @MODULES), 'the facade is one of them');
	ok((grep { $_ eq 'Game::Oware::Terminal' } @MODULES), 'and so is the terminal');
};

subtest 'every version is defined, and they all agree' => sub {
	my %seen;
	for my $module (@MODULES) {
		no strict 'refs';
		my $version = ${ $module . '::VERSION' };
		ok(defined $version, "$module has a version") or next;
		$seen{$version}++;
	}
	is(scalar keys %seen, 1, 'and there is exactly one of them: '
		. join(', ', sort keys %seen));
};

# THE ONE THAT CAUGHT Game::Cribbage. Its POD claimed a version one ahead of the
# code, so the documentation on metacpan described a release that did not exist.
subtest 'the POD version matches the code version' => sub {
	plan tests => scalar @MODULES;

	for my $module (@MODULES) {
		my $path = 'lib/' . $module . '.pm';
		$path =~ s{::}{/}g;
		$path =~ s{lib/lib/}{lib/};

		open my $fh, '<', $path or do {
			fail("$module: cannot read $path");
			next;
		};
		my $source = do { local $/; <$fh> };
		close $fh;

		no strict 'refs';
		my $version = ${ $module . '::VERSION' };
		my ($documented) = $source =~ /^=head1 VERSION\s+Version\s+(\S+)\s*$/ms;

		is($documented, $version, "$module documents $version");
	}
};
