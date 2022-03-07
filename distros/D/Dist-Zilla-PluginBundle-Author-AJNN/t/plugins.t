#!perl

use 5.026;
use warnings;

use Test::More;
use Test::Exception;
use Test::Warnings;
use Test::DZil;

plan tests => 3 + 3+6+4+3+1+3 + 1;


my $tzil = Builder->from_config(
	{ dist_root => "t/corpus" },
	{ add_files => { 'source/dist.ini' => simple_ini( {},
		[ '@Filter' => {
			'-bundle' => '@Author::AJNN',
			'-remove' => 'CheckChangeLog',
		}],
	)}},
);

lives_and { ok $tzil->build } 'build';

my $meta;
lives_and { ok $meta = $tzil->distmeta } 'distmeta';

my @plugins;
lives_ok { @plugins = $tzil->plugins->@* } 'plugins';

sub has_plugin {
	my $plugin = shift;
	$plugin = "Dist::Zilla::Plugin$plugin";
	return scalar grep { $_->isa($plugin) } @plugins;
}

ok has_plugin('::GatherDir'), 'plugin GatherDir';
ok has_plugin('::PruneCruft'), 'plugin PruneCruft';
is !! has_plugin('Bundle::Author::AJNN::PruneAliases'), $^O eq 'darwin', 'plugin PruneAliases';

ok has_plugin('::CPANFile'), 'plugin CPANFile';
ok has_plugin('::MetaJSON'), 'plugin MetaJSON';
ok has_plugin('::MetaYAML'), 'plugin MetaYAML';
ok has_plugin('::MetaProvides::Package'), 'plugin MetaProvides::Package';
ok has_plugin('::PkgVersion'), 'plugin PkgVersion';
ok has_plugin('::GithubMeta'), 'plugin GithubMeta';

ok has_plugin('::Git::Check'), 'plugin Git::Check';
ok has_plugin('::TestRelease'), 'plugin TestRelease';
ok has_plugin('::ConfirmRelease'), 'plugin ConfirmRelease';
ok has_plugin('::Git::Tag'), 'plugin Git::Tag';

ok has_plugin('::MakeMaker'), 'plugin MakeMaker';
ok has_plugin('Bundle::Author::AJNN::Readme'), 'plugin Readme';
ok has_plugin('::Manifest'), 'plugin Manifest';

ok has_plugin('::PodWeaver'), 'plugin PodWeaver';

ok ! has_plugin('::Test::MinimumVersion'), 'no plugin Test::MinimumVersion';
ok has_plugin('::PodSyntaxTests'), 'plugin PodSyntaxTests';
ok has_plugin('::RunExtraTests'), 'plugin RunExtraTests';

done_testing;
