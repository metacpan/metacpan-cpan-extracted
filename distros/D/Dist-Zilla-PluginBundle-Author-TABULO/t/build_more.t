use strict;
use warnings;

# use Dist::Zilla::App::Tester;
use Git::Wrapper;
use Path::Tiny;
use Test::More;
use Test::DZil;

use File::chdir;
use Data::Printer qw(p np);

eval { Git::Wrapper->new(Path::Tiny->cwd)->version; 1 } or plan skip_all => 'git is not available for testing';

my $tzil = Builder->from_config(
  { dist_root => 'does-not-exist' },
  {
    add_files => {
      path('source', 'dist.ini') => simple_ini({ version => undef },
        ['@Author::TABULO' => {   regenerate => 'LICENSE', no_sanitize_version =>1, no_git_commit_build => 1, no_git_push=>1, } ],
        [Prereqs => { 'perl' => '5.006' }],
      ),
      path('source', 'lib', 'DZT', 'Sample.pm') => "package DZT::Sample;\nour \$VERSION = '0.001';\n1",
      path('source', 'lib', 'DZT', 'Sample2.pm') => "package DZT::Sample2;\nour \$VERSION = '0.050';\n1",
      path('source', 'lib', 'DZT', 'Sample3.pm') => "package DZT::Sample3;\n1",
      path('source', 'prune-me') => "",
      path('source', '.gitignore') => "prune-me\n",
      path('source', '.git', 'this-should-get-pruned') => "",
      path('source', 'README.pod') => "prune me\n",
      path('source', 'Changes') => "{{\$NEXT}}\n  - Initial version\n",
    },
  },
);
my $tempdir = $tzil->tempdir;
my $srcdir  =  path($tempdir)->child('source');
my $git = Git::Wrapper->new($srcdir);
$git->init;
$git->add('*');

$tzil->build;

my @expected_files = sort qw(
  Makefile.PL
  cpanfile
  dist.ini
  lib/DZT/Sample.pm
  lib/DZT/Sample2.pm
  lib/DZT/Sample3.pm
  LICENSE
  INSTALL
  MANIFEST
  META.json
  META.yml
  README
  README.md
  Changes
  t/00-report-prereqs.t
  t/00-report-prereqs.dd
  xt/author/00-compile.t
  xt/author/critic.t
  xt/author/distmeta.t
  xt/author/eol.t
  xt/author/minimum-version.t
  xt/author/mojibake.t
  xt/author/pod-coverage.t
  xt/author/pod-spell.t
  xt/author/pod-syntax.t
  xt/author/portability.t
  xt/author/test-version.t
  xt/release/check-manifest.t
  xt/release/consistent-version.t
  xt/release/kwalitee.t
);

my $build_dir = path($tzil->tempdir)->child('build');
my @found_files;
my $iter = $build_dir->iterator({ recurse => 1 });
while (my $path = $iter->()) {
  push @found_files, $path->relative($build_dir)->stringify if -f $path;
}
@found_files=sort @found_files;
# say STDERR "$0: \@found_files: "; p @found_files;

is_deeply [sort @found_files], \@expected_files, 'built the correct files';

my $meta = $tzil->distmeta;
my $version = $ENV{V} // '0.001';

like $meta->{version}, qr/\Q$version\E(000)?/, 'right dist version';
is_deeply $meta->{prereqs}{runtime}{requires}, { 'perl' => '5.006' }, 'right prereqs metadata';
is_deeply $meta->{provides}, {
  'DZT::Sample' => { file => 'lib/DZT/Sample.pm', version => $version },
  'DZT::Sample2' => { file => 'lib/DZT/Sample2.pm', version => $version },
  'DZT::Sample3' => { file => 'lib/DZT/Sample3.pm', version => $version },
}, 'right provides metadata';
# my @expected_no_index = sort qw(eg examples inc share t xt);  # @Starter::Git
my @expected_no_index = sort(qw(t xt), qw(corpus demo eg examples fatlib local inc perl5 share)); # @Author::TABULO
is_deeply [sort @{$meta->{no_index}{directory}}], \@expected_no_index, 'right no_index metadata';
ok !defined($meta->{x_Dist_Zilla}), 'dzil config not included in metadata';

my $changes = $build_dir->child('Changes')->slurp;
unlike $changes, qr/\{\{\$NEXT\}\}/, 'no marker in Changes';
like $changes, qr/\Q$version\E(000)?/, 'version in Changes';

## [TAU]: Disabling the following test,
## because we may wish to copy LICENSE back to root.
# my $license_in_root = path($tzil->tempdir)->child('source', 'LICENSE');
# ok !-f $license_in_root, 'LICENSE not in root after build';

done_testing;


#COPYRIGHT
#CREDITS: # [TAU]: Adopted from @Starter::Git/t/bundle_revision_5.t


