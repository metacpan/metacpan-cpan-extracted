#!perl

use 5.026;
use warnings;
use lib 'lib';

use Test::More;
use Test::Exception;
use Test::Warnings;
use Test::DZil;
use List::Util 1.33 qw(any first);

plan tests => 5 + 1 + 3 + 1 + 2 + 1;

my $tzil;


sub has_plugin {
	my ($tzil, $plugin) = @_;
	$plugin = "Dist::Zilla::Plugin::$plugin";
	return unless $tzil;
	return any { $_->isa($plugin) } $tzil->plugins->@*;
}

lives_and {
	$tzil = Builder->from_config(
		{ dist_root => "t/corpus" },
		{ add_files => { 'source/dist.ini' => simple_ini( {},
			[ '@Author::AJNN' => {
				'-remove' => ['CheckChangeLog', 'MetaJSON', 'MetaYAML'],
			}],
		)}},
	);
	ok $tzil->build;
} '-remove lives';

ok ! has_plugin($tzil, 'CheckChangeLog'), 'no plugin CheckChangeLog';
ok ! has_plugin($tzil, 'MetaJSON'), 'no plugin MetaJSON';
ok ! has_plugin($tzil, 'MetaYAML'), 'no plugin MetaYAML';
ok has_plugin($tzil, 'Manifest'), 'plugin Manifest';


dies_ok {
	Builder->from_config(
		{ dist_root => "t/corpus" },
		{ add_files => { 'source/dist.ini' => simple_ini( {},
			[ '@Author::AJNN' => {
				'-remove' => ['CheckChangeLog'],
				'cpan_release' => ['1', '0'],
			}],
		)}},
	)->build;
} 'cpan_release dies';


lives_and {
	$tzil = Builder->from_config(
		{ dist_root => "t/corpus" },
		{ add_files => { 'source/dist.ini' => simple_ini( {},
			[ '@Author::AJNN' => {
				'-remove' => ['CheckChangeLog'],
				'GatherDir.exclude_match' => ['foo', 'bar'],
			}],
		)}},
	);
	ok $tzil->build;
} 'GatherDir.exclude_match lives';

my $gather_dir = first { $_->isa('Dist::Zilla::Plugin::GatherDir') } $tzil->plugins->@*;
ok( (any { $_ eq 'foo' } $gather_dir->exclude_match->@*), 'exclude foo' );
ok( (any { $_ eq 'bar' } $gather_dir->exclude_match->@*), 'exclude bar' );


dies_ok {
	Builder->from_config(
		{ dist_root => "t/corpus" },
		{ add_files => { 'source/dist.ini' => simple_ini( {},
			[ '@Author::AJNN' => {
				'-remove' => ['CheckChangeLog'],
				'Test::MinimumVersion.max_target_perl' => ['v5.16', 'v5.36'],
			}],
		)}},
	)->build;
} 'max_target_perl dies';


lives_and {
	$tzil = Builder->from_config(
		{ dist_root => "t/corpus" },
		{ add_files => { 'source/dist.ini' => simple_ini( {},
			[ '@Author::AJNN' => {
				'-remove' => ['CheckChangeLog'],
				'PodWeaver.skip' => ['DZT', 'foo'],
			}],
		)}},
	);
	ok $tzil->build;
} 'PodWeaver.skip lives';
my $dzt_pod = ( first {$_->name eq 'lib/DZT.pm'} $tzil->files->@* )->content;
ok $dzt_pod !~ m/=head1 VERSION/, 'PodWeaver skipped';


done_testing;
