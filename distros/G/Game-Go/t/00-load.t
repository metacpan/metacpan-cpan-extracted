#!perl

# Every module loads, every $VERSION is identical, and every module's POD says
# the same version its code does.
#
# The module list is DERIVED with File::Find rather than maintained by hand, so
# that a module added without a test cannot pass by not being looked at. The
# scaffolding this file replaced listed exactly one module and would have gone
# on passing for the life of the distribution.

use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

my @MODULES;
File::Find::find(sub {
	return unless -f && /\.pm\z/;
	(my $mod = $File::Find::name) =~ s{^lib/}{};
	$mod =~ s{\.pm\z}{};
	$mod =~ s{/}{::}g;
	push @MODULES, $mod;
}, 'lib');

@MODULES = sort @MODULES;

ok(scalar @MODULES, 'lib holds at least one module') or BAIL_OUT('no modules found under lib');

# Game::Go first, because it is the one that loads the XS and nothing else
# works until it has.
@MODULES = ('Game::Go', grep { $_ ne 'Game::Go' } @MODULES);

for my $mod (@MODULES) {
	use_ok($mod) or BAIL_OUT("$mod does not load");
}

subtest 'every $VERSION is identical' => sub {
	my $want = Game::Go->VERSION;
	ok(defined $want && length $want, "Game::Go has a version ($want)");
	for my $mod (@MODULES) {
		is($mod->VERSION, $want, "$mod is at $want");
	}
	done_testing();
};

subtest 'every POD =head1 VERSION matches the code' => sub {
	for my $mod (@MODULES) {
		(my $file = "lib/$mod.pm") =~ s{::}{/}g;
		open my $fh, '<', $file or do { fail("$file: $!"); next };
		my $pod = do { local $/; <$fh> };
		close $fh;
		my ($stated) = $pod =~ /^=head1 VERSION\s+^Version\s+(\S+)\s*$/ms;
		is($stated, $mod->VERSION, "$mod documents the version it is at");
	}
	done_testing();
};

subtest 'the ABI version is the one the Perl side expects' => sub {
	# The rule is >= and never ==, so this asserts the floor rather than a
	# number. A consumer pinned to == stops loading the moment the table
	# grows one member, which is what happened to a sibling distribution.
	my $v = Game::Go->abi_version;
	ok($v >= 1, "the C table reports ABI version $v, at or above the 1 this suite was written against");
	done_testing();
};

diag("Testing Game::Go $Game::Go::VERSION, ABI " . Game::Go->abi_version . ", Perl $], $^X");

done_testing();
