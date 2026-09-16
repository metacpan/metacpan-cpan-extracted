#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# Everything loads, and every module agrees with itself and with the others
# about what version this is.
#
# THE VERSION ASSERTION EXISTS BECAUSE SOMETHING SHIPPED BROKEN. Game::Cribbage
# went to CPAN with a POD version one ahead of its actual $VERSION, and nothing
# in its suite could tell. A number in prose and a number in code drift the
# moment a release is made in a hurry, and only a test that reads both notices.

my @MODULES = qw(
	Game::Reversi
	Game::Reversi::Board
	Game::Reversi::Move
	Game::Reversi::Notation
	Game::Reversi::Opening
	Game::Reversi::Rules
	Game::Reversi::Scoring
	Game::Reversi::Result
	Game::Reversi::Error
	Game::Reversi::Bot
	Game::Reversi::Terminal
);

use_ok($_) for @MODULES;

subtest 'the module list is the whole of lib, with nothing left out' => sub {
	# A module added to lib and not to this file would never be loaded by this
	# test at all, so the list has to be checked against the tree rather than
	# maintained by hand and hoped over.
	my @found;
	File::Find::find({
		no_chdir => 1,
		wanted   => sub {
			return unless /\.pm\z/;
			my $module = $File::Find::name;
			$module =~ s{\Alib/}{};
			$module =~ s{\.pm\z}{};
			$module =~ s{/}{::}g;
			push @found, $module;
		},
	}, 'lib');

	is_deeply([ sort @found ], [ sort @MODULES ],
		'every .pm under lib is in the list above, and nothing else is');
	done_testing();
};

subtest 'every module declares a version, and they are all the same one' => sub {
	my %version;
	for my $module (@MODULES) {
		no strict 'refs';
		my $version = ${ $module . '::VERSION' };
		ok(defined $version && length $version, "$module has a \$VERSION");
		$version{$module} = $version;
	}

	my %distinct = map { $_ => 1 } values %version;
	is(scalar keys %distinct, 1, 'and all of them are the same version')
		or diag(join "\n", map { "$_ = " . ($version{$_} // 'undef') }
		        sort keys %version);
	done_testing();
};

subtest 'the POD version matches the code version, module by module' => sub {
	# The one that Game::Cribbage needed and did not have.
	for my $module (@MODULES) {
		(my $path = $module) =~ s{::}{/}g;
		$path = "lib/$path.pm";

		open my $fh, '<', $path or do {
			fail("$module: cannot read $path");
			next;
		};
		my $source = do { local $/; <$fh> };
		close $fh;

		my ($pod) = $source =~ /^=head1 VERSION\s*\n+\s*Version\s+(\S+?)\s*$/ms;
		ok(defined $pod, "$module: POD names a version") or next;

		no strict 'refs';
		is($pod, ${ $module . '::VERSION' },
			"$module: the POD version and \$VERSION agree");
	}
	done_testing();
};

subtest 'every module has a name, an author and a licence in its POD' => sub {
	for my $module (@MODULES) {
		(my $path = $module) =~ s{::}{/}g;
		$path = "lib/$path.pm";
		open my $fh, '<', $path or next;
		my $source = do { local $/; <$fh> };
		close $fh;

		like($source, qr/^=head1 NAME\s*\n+\Q$module\E\s+-\s+\S/m,
			"$module: NAME names it and says what it is");
		like($source, qr/^=head1 AUTHOR/m, "$module: has an author");
		like($source, qr/^=head1 LICENSE AND COPYRIGHT/m, "$module: and a licence");
	}
	done_testing();
};

diag("Testing Game::Reversi $Game::Reversi::VERSION, Perl $], $^X");

done_testing();
