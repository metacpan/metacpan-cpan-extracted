#!perl
use 5.010;
use strict;
use warnings;
use File::Find ();
use Test::More;

# The stock Module::Starter manifest test needs Test::CheckManifest and skips
# when it is absent, which on this machine meant it had never run once. A test
# that says PASS because it could not do its job is worse than no test: the
# suite looks green and the MANIFEST rots.
#
# So this does the job with nothing but core. It is not as thorough as
# Test::CheckManifest, and it does not need to be: it answers the two questions
# that actually go wrong, which are a new file nobody listed and a listed file
# nobody shipped.
#
# make disttest catches the first of those too, but only for files the tests
# happen to load. Game::Dominoes::Bot went missing from the MANIFEST and only
# disttest noticed, because prove reads lib/ directly and never looks.

unless ($ENV{RELEASE_TESTING}) {
	plan skip_all => 'Author tests not required for installation';
}

plan tests => 2;

# Build leavings and version control, none of which belong in a MANIFEST.
my $IGNORE = qr{
	\A (?: blib/ | \.git/ | \.build/ | _build/ | Game-Dominoes-[\d.]+/ )
	| \A (?: Makefile | Makefile\.old | pm_to_blib | MYMETA\.(?:json|yml) | META\.(?:json|yml) ) \z
	| \.(?: bak | old | orig | rej | swp | tar\.gz | tgz ) \z
	| \A \. (?: DS_Store | gitignore )
	| \A MANIFEST\.(?: SKIP | bak ) \z
}x;

open my $fh, '<', 'MANIFEST' or die "MANIFEST: $!";
my %listed;
while (my $line = <$fh>) {
	chomp $line;
	$line =~ s/\s+.*\z//;            # MANIFEST allows a trailing comment
	next unless length $line;
	next if $line =~ /\A#/;
	$listed{$line} = 1;
}
close $fh;

my %present;
File::Find::find({
	no_chdir => 1,
	wanted => sub {
		return unless -f $_;
		my $path = $_;
		$path =~ s{\A\./}{};
		return if $path =~ $IGNORE;
		$present{$path} = 1;
	},
}, '.');

my @unlisted = sort grep { !$listed{$_} } keys %present;
my @missing = sort grep { !-f $_ } keys %listed;

is_deeply \@unlisted, [],
	'every file in the tree is in the MANIFEST'
	or diag("not listed, so they would not ship:\n  " . join("\n  ", @unlisted));

is_deeply \@missing, [],
	'every file in the MANIFEST is in the tree'
	or diag("listed but absent, so the tarball would fail to build:\n  "
		. join("\n  ", @missing));
