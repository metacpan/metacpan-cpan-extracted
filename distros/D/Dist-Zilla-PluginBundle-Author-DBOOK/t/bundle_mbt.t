use strict;
use warnings;
use Git::Wrapper;
use Path::Tiny;
use Test::More;
use Test::DZil;

eval { Git::Wrapper->new(Path::Tiny->cwd)->version; 1 } or plan skip_all => 'git is not available for testing';

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path('source', 'dist.ini') => simple_ini({ version => undef },
        ['@Author::DBOOK' => { installer => 'ModuleBuildTiny', pod_tests => 1 }],
      ),
      path('source', 'lib', 'DZT', 'Sample.pm') => "package DZT::Sample;\nour \$VERSION = '0.001';\n1",
      path('source', 'cpanfile') => "requires 'perl' => '5.006';\ntest_requires 'Test::More' => '0.88';\n",
      path('source', 'Changes') => "{{\$NEXT}}\n  - Tested plugin bundle\n",
      path('source', '.gitignore') => "/DZT-Sample-*\n",
    },
  },
);

my $git = Git::Wrapper->new(path($tzil->tempdir)->child('source'));
$git->init;
$git->add(qw(dist.ini cpanfile Changes .gitignore lib/DZT/Sample.pm));

$tzil->build;

my @expected_files = sort qw(
  Build.PL
  Changes
  CONTRIBUTING.md
  cpanfile
  dist.ini
  lib/DZT/Sample.pm
  INSTALL
  LICENSE
  MANIFEST
  META.json
  META.yml
  README
  t/00-report-prereqs.t
  t/00-report-prereqs.dd
  xt/author/pod-syntax.t
  xt/author/pod-coverage.t
);

my $build_dir = path($tzil->tempdir)->child('build');
my @found_files;
my $iter = $build_dir->iterator({ recurse => 1 });
while (my $path = $iter->()) {
  push @found_files, $path->relative($build_dir)->stringify if -f $path;
}

is_deeply [sort @found_files], \@expected_files, 'built the correct files';

my $meta = $tzil->distmeta;

is $meta->{version}, '0.001', 'right dist version';
is_deeply $meta->{prereqs}{runtime}{requires}, { 'perl' => '5.006' }, 'right prereqs metadata';
is_deeply $meta->{prereqs}{test}{requires},
  { 'Test::More' => '0.88', 'Module::Metadata' => '0', 'File::Spec' => '0' }, 'right test prereqs metadata';
is_deeply $meta->{provides}, { 'DZT::Sample' => { file => 'lib/DZT/Sample.pm', version => '0.001' } }, 'right provides metadata';
my @expected_no_index = sort qw(eg examples inc share t xt);
is_deeply [sort @{$meta->{no_index}{directory}}], \@expected_no_index, 'right no_index metadata';
ok defined($meta->{x_Dist_Zilla}), 'dzil config included in metadata';

done_testing;
