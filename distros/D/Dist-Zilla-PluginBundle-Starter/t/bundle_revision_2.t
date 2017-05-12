use strict;
use warnings;
use Path::Tiny;
use Test::More;
use Test::DZil;

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path('source', 'dist.ini') => simple_ini({},
        ['@Starter' => { revision => 2 }],
        [Prereqs => { 'perl' => '5.006' }],
      ),
      path('source', 'lib', 'DZT', 'Sample.pm') => "package DZT::Sample;\nour \$VERSION = '0.001';\n1",
      path('source', 'lib', 'DZT', 'Sample2.pm') => "package DZT::Sample2;\nour \$VERSION = '0.050';\n1",
      path('source', 'lib', 'DZT', 'Sample3.pm') => "package DZT::Sample3;\n1",
      path('source', '.git', 'this-should-get-pruned') => "",
    },
  },
);

$tzil->build;

my @expected_files = sort qw(
  Makefile.PL
  dist.ini
  lib/DZT/Sample.pm
  lib/DZT/Sample2.pm
  lib/DZT/Sample3.pm
  LICENSE
  MANIFEST
  META.json
  META.yml
  README
  t/00-report-prereqs.t
  t/00-report-prereqs.dd
  xt/author/00-compile.t
  xt/author/pod-syntax.t
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
is_deeply $meta->{provides}, {
  'DZT::Sample' => { file => 'lib/DZT/Sample.pm', version => '0.001' },
  'DZT::Sample2' => { file => 'lib/DZT/Sample2.pm', version => '0.050' },
  'DZT::Sample3' => { file => 'lib/DZT/Sample3.pm', version => '0.001' },
}, 'right provides metadata';
my @expected_no_index = sort qw(eg examples inc share t xt);
is_deeply [sort @{$meta->{no_index}{directory}}], \@expected_no_index, 'right no_index metadata';
ok defined($meta->{x_Dist_Zilla}), 'dzil config included in metadata';

done_testing;
