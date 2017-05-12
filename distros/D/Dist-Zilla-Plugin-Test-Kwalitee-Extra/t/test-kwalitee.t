use strict;
use warnings;

use version 0.77;
use Dist::Zilla::Tester;
use Path::Class;
use Test::More tests => 15;
use Capture::Tiny qw( capture );

require Module::CPANTS::Analyse;
my $target_ver = version->parse($Module::CPANTS::Analyse::VERSION);

sub new_cpants_analyse
{
	return $target_ver == version->parse('0.88') || $target_ver > version->parse('0.89');
}

my $tzil = Dist::Zilla::Tester->from_config( { dist_root => dir( qw( t test-kwalitee ) ), } );

my $tempdir       = $tzil->tempdir;
my $sourcedir     = $tempdir->subdir( 'source' );
my $builddir      = $tempdir->subdir( 'build' );
my $expected_file = $builddir->subdir( 'xt' )->subdir( 'release' )->file( 'kwalitee.t' );

chdir $sourcedir;

$tzil->build;

END {  # Remove (empty) dir created by building the dists
  require File::Path;
  my $tmp = $tempdir->parent;
  chdir $tmp->parent;
  File::Path::remove_tree( $tmp, { keep_root => 0 } );
}

ok( -e $expected_file, 'test created' );
chdir $builddir;

my ( $result, $output, $error, $errflags );
{
  local $@;
  local $!;
  local $?;
  ( $output, $error ) = capture {
    $result = system( $^X, $expected_file );
  };
  $errflags = { '@' => $@, '!' => $!, '?' => $? };
}
my $success = 1;
isnt  ( $result, 0, 'Test ran, and failed, as intended' ) or do { $success = 0 };
like  ( $output, qr/^not ok.*has_readme/m,         'Test dist has no README' )         or do { $success = 0 };
like  ( $output, qr/^not ok.*has_manifest/m,       'Test dist has no MANIFEST' )       or do { $success = 0 };
like  ( $output, qr/^not ok.*has_meta_yml/m,       'Test dist has no META.yml' )       or do { $success = 0 };
like  ( $output, qr/^not ok.*has_buildtool/m,      'Test dist has no build tool' )     or do { $success = 0 };
like  ( $output, qr/^not ok.*has_changelog/m,      'Test dist has no changelog' )      or do { $success = 0 };
like  ( $output, qr/^ok.*no_symlinks/m,            'Test dist lacked symlinks' )       or do { $success = 0 };
like  ( $output, qr/^not ok.*has_tests/m,          'Test dist has no tests' )          or do { $success = 0 };
if(new_cpants_analyse()) {
  unlike( $output, qr/proper_libs/m,               'No test dist has proper libs' )    or do { $success = 0 };
  unlike( $output, qr/no_pod_errors/m,             'No test dist has no pod errors' )  or do { $success = 0 };
} else {
  like( $output, qr/^ok.*proper_libs/m,            'Test dist has proper libs' )       or do { $success = 0 };
  like( $output, qr/^ok.*no_pod_errors/m,          'Test dist has no pod errors' )     or do { $success = 0 };
}
like  ( $output, qr/^not ok.*use_strict/m,         'Test dist has no use strict' )     or do { $success = 0 };
if(new_cpants_analyse()) {
  unlike( $output, qr/valid_signature/m,           'No test dist has valid signature' )or do { $success = 0 };
} else {
  like( $output, qr/^ok.*valid_signature/m,        'Test dist has valid signature' )   or do { $success = 0 };
}
unlike( $output, qr/has_human_?readable_license/m, 'No test dist has hr license' )     or do { $success = 0 };
if(new_cpants_analyse()) {
  unlike( $output, qr/has_example/m,               'No test dist has example' )        or do { $success = 0 };
} else {
  like( $output, qr/^ok.*has_example/m,            'Test dist has example' )           or do { $success = 0 };
}

if ( not $success ) {
  diag explain { 'stdout' => $output, 'stderr' => $error, 'result' => $result, 'flags' => $errflags, };
}
