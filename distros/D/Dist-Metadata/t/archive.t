use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'Dist::Metadata::Archive';
eval "require $mod" or die $@;

# default_file_spec
is( $mod->default_file_spec, 'Unix', 'most archive files use unix paths' );

test_constructor_errors($mod);

# test file type determination
my $base = 'corpus/Dist-Metadata-Test-NoMetaFile-0.1';
foreach my $test (
  [Zip => "$base.zip"],
  [Tar => "$base.tar.gz"],
){
  my ($type, $file) = @$test;

  my $distclass = "Dist::Metadata::$type";

  # instantiate using base 'Archive' class which will determine subclass
  my $archive = new_ok($mod => [file => $file]);

  isa_ok($archive, $distclass);
  isa_ok($archive->archive, "Archive::$type");

  # file
  is($archive->file, $file, 'dumb accessor works');

  # determine_name_and_version
  $archive->determine_name_and_version();
  is($archive->name, 'Dist-Metadata-Test-NoMetaFile', 'name from file');
  is($archive->version, '0.1', 'version from file');

  # file_content
  is(
    $archive->file_content('README'),
    qq[This "dist" is for testing Dist::Metadata.\n],
    'got file content without specifying root dir'
  );

  # perllocale says, "By default Perl ignores the current locale."

  # find_files
  is_deeply(
    [sort $archive->find_files],
    [qw(
      Dist-Metadata-Test-NoMetaFile-0.1/README
      Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile.pm
      Dist-Metadata-Test-NoMetaFile-0.1/lib/Dist/Metadata/Test/NoMetaFile/PM.pm
    )],
    'find_files'
  );

  # list_files (no root)
  is_deeply(
    [sort $archive->list_files],
    [qw(
      README
      lib/Dist/Metadata/Test/NoMetaFile.pm
      lib/Dist/Metadata/Test/NoMetaFile/PM.pm
    )],
    'files listed without root directory'
  );

  # root
  is($archive->root, 'Dist-Metadata-Test-NoMetaFile-0.1', 'root dir');

  # do this last so that successful new() has already loaded the distclass
  test_constructor_errors($distclass);
}

done_testing;

# required_attribute
# file doesn't exist
sub test_constructor_errors {
  my $mod = shift;

  my $att = 'file';
  is( $mod->required_attribute, $att, "'$att' attribute required" );
  my $ex = exception { $mod->new() };
  like($ex, qr/'$att' parameter required/, "new dies without '$att'");

  my $dist = new_ok( $mod, [ file => 'does-not._exist_' ] );
  $ex = exception { $dist->archive };
  like($ex, qr/does not exist/, 'file does not exist');
}
