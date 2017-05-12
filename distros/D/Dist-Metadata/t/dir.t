use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;
use Test::MockObject 1.09 ();
use Path::Class 0.24 qw(file dir);
use File::Spec ();

my $tmpdir = File::Spec->tmpdir;

my $mod = 'Dist::Metadata::Dir';
eval "require $mod" or die $@;

# required_attribute
# extract_into
{
  my $att = 'dir';
  is($mod->required_attribute, $att, "'$att' attribute required");
  my $ex = exception { $mod->new() };
  like($ex, qr/'$att' parameter required/, "new dies without '$att'");

  $ex = exception { $mod->new(dir => $tmpdir)->extract_into($tmpdir) };
  like( $ex, qr/A directory doesn't need to be extracted/, 'no extraction' );
}

# default_file_spec
  is( $mod->default_file_spec, 'Native', 'default to native file spec for dir' );

# dir
# file_content
# find_files
# physical_directory

{
  # with no root dir
  my $path = dir( qw(corpus noroot) );
  my $dir  = $path->stringify;
  my $dist = new_ok( $mod, [ dir => $dir ] );

  test_phys_dir($dist, $dir, $path);

  my @files = (
    file( qw(lib Dist Metadata Test NoRoot PM.pm) )->stringify,
    file( qw(lib Dist Metadata Test NoRoot.pm) )->stringify,
    'README'
  );

  # no root, same as below
  is_deeply([sort $dist->find_files], [sort @files], 'all files listed (full paths)');
  # root stripped
  is_deeply([sort $dist->list_files], [sort @files], 'all files listed (no root)');
}
# with root dir
{
  my $path = dir( qw(corpus subdir) );
  my $dir  = $path->stringify;
  my $dist = new_ok( $mod, [ dir => $dir ] );

  test_phys_dir($dist, $dir, $path->subdir($dist->root));

  my @files = (
    file( qw(lib Dist Metadata Test SubDir PM.pm) )->stringify,
    file( qw(lib Dist Metadata Test SubDir.pm) )->stringify,
    'README'
  );

  # root present
  is_deeply([sort $dist->find_files], [sort map { file($dist->root, $_)->stringify } @files], 'all files listed (full paths)');
  # root stripped
  is_deeply([sort $dist->list_files], [sort @files], 'all files listed (no root)');
}

# determine_name_and_version
{
  my %nv = (name => 'Dist-Metadata-Test-MetaFile', version => 2.2);
  my $dir = dir( 'corpus', join('-', @nv{qw(name version)}) );
  my $dist = new_ok( $mod, [ dir => $dir ] );

  ok(!exists($dist->{$_}), "no dist $_" )
    for keys %nv;

  $dist->determine_name_and_version;

  is($dist->$_, $nv{$_}, "determined dist $_" )
    for keys %nv;
}

done_testing;

sub test_phys_dir {
  my ($dist, $dir, $subroot) = @_;
  $subroot = $subroot->absolute;

  is( $dist->dir, $dir, 'dir attribute from constructor arg' );
  is( $dist->physical_directory, $subroot, 'dir + root' );

  is_deeply(
    [$dist->physical_directory('README')],
    [$subroot,  $subroot->file('README')],
    'physical directory with adjusted file'
  );

  is(
    $dist->file_content('README'),
    qq[This "dist" is for testing Dist::Metadata.\n],
    'file content'
  );

  like(
    exception { $dist->file_content('missing.file') },
    qr{Failed to open file 'corpus.+\w+.+missing\.file':},
    'die on missing file'
  );

}
