#!perl

use v5.26;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;
use Test::DZil;
use List::Util 'first';

plan tests => 4 + 2 + 3 + 1;


my $tzil = Builder->from_config(
	{ dist_root => "t/corpus" },
	{ add_files => { 'source/dist.ini' => simple_ini( {},
		[ 'GatherDir' => {} ],
		[ 'PruneAliases' => {} ],
		[ 'Manifest' => {} ],
	)}},
);

lives_and { ok $tzil->build } 'build';

my $meta;
lives_and { ok $meta = $tzil->distmeta } 'distmeta';

my @plugins;
lives_ok { @plugins = $tzil->plugins->@* } 'plugins';
ok scalar(grep { $_->isa('Dist::Zilla::Plugin::PruneAliases') } @plugins), 'plugin PruneAliases';

my @files;
lives_ok { @files = $tzil->files->@* } 'files';
my @expected_files = qw(
	book
	empty
	file
	lib/DZT.pm
	dist.ini
	MANIFEST
);
is_filelist \@files, \@expected_files, 'alias not in filelist';

my $manifest_file = first { $_->name eq 'MANIFEST' } @files;
ok $manifest_file, 'manifest file';
my $manifest = $manifest_file->encoded_content;
like $manifest, qr{^file$}m, 'manifest has content';
ok $manifest !~ m{alias}, 'alias not in manifest';

done_testing;
