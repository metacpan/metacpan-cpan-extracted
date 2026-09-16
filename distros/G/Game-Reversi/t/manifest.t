#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Find ();

# MANIFEST lists everything in the tree, and everything in MANIFEST is in the
# tree.
#
# WRITTEN WITHOUT Test::CheckManifest ON PURPOSE. The stock Module::Starter
# version of this file is guarded twice, once on RELEASE_TESTING and once on
# whether Test::CheckManifest is installed, and the second guard is the problem:
# on a machine without that module the file plans skip_all and reports PASS. It
# is not that the test is skipped loudly; it is that a green suite looks
# identical whether the check ran or not.
#
# Game-Dominoes shipped exactly this file and it had never once executed. It was
# only found when a module was left out of MANIFEST and `make disttest`, not the
# suite, caught it.
#
# So this one has no optional dependency and no second guard. It runs whenever
# author tests run, on every machine.

unless ($ENV{RELEASE_TESTING}) {
	plan skip_all => 'author test: set RELEASE_TESTING to check MANIFEST';
}

# What the tree holds, minus the things a build leaves behind.
my @SKIP_DIRS  = qw(blib _build .git cover_db Game-Reversi-0.01);
my @SKIP_FILES = qw(Makefile pm_to_blib MYMETA.json MYMETA.yml META.json META.yml
                    .DS_Store MANIFEST.bak MANIFEST.SKIP);

my %skip_dir  = map { $_ => 1 } @SKIP_DIRS;
my %skip_file = map { $_ => 1 } @SKIP_FILES;

my @tree;
File::Find::find({
	no_chdir => 1,
	preprocess => sub { return grep { !$skip_dir{$_} } @_ },
	wanted => sub {
		return if -d $File::Find::name;
		my $path = $File::Find::name;
		$path =~ s{\A\./}{};
		return if $skip_file{ (split m{/}, $path)[-1] };
		return if $path =~ /\.(?:old|bak|tar\.gz|tmp)\z/;
		return if $path =~ /\AGame-Reversi-[\d.]+/;
		push @tree, $path;
	},
}, '.');

open my $fh, '<', 'MANIFEST' or do {
	plan skip_all => 'there is no MANIFEST to check';
};
my @manifest;
while (my $line = <$fh>) {
	# CHOMP FIRST. MakeMaker writes a comment after the filename in a generated
	# MANIFEST, as in "META.json    Module JSON meta-data (added by MakeMaker)",
	# and s/\s.*\z// will not strip it while the newline is still attached:
	# "." does not match a newline, so ".*\z" cannot reach the end of the
	# string. The substitution silently does nothing and the whole comment
	# becomes part of the filename.
	chomp $line;
	next if $line =~ /\A\s*#/;
	$line =~ s/\s.*\z//;
	next unless length $line;
	# The same generated files the tree scan skips. A built distribution has
	# them and a working tree does not, so they must be ignored on both sides
	# or this test passes in one place and fails in the other.
	next if $skip_file{ (split m{/}, $line)[-1] };
	push @manifest, $line;
}
close $fh;

plan tests => 3;

my %in_manifest = map { $_ => 1 } @manifest;
my %in_tree     = map { $_ => 1 } @tree;

my @missing = sort grep { !$in_manifest{$_} } @tree;
is_deeply(\@missing, [],
	'every file in the tree is listed in MANIFEST')
	or diag("not listed, so `make dist` would leave them out:\n  "
		. join "\n  ", @missing);

my @ghosts = sort grep { !$in_tree{$_} } @manifest;
is_deeply(\@ghosts, [],
	'and every file MANIFEST lists is really there')
	or diag("listed but absent:\n  " . join "\n  ", @ghosts);

# The check that would have caught the Game-Dominoes fault directly: a module or
# a test that exists and is not going to be shipped.
my @unshipped = sort grep { m{\A(?:lib/.*\.pm|t/.*\.t|xt/.*\.t|bin/)} && !$in_manifest{$_} } @tree;
is_deeply(\@unshipped, [],
	'no module, test or program is left out of the distribution')
	or diag("would not be shipped:\n  " . join "\n  ", @unshipped);
