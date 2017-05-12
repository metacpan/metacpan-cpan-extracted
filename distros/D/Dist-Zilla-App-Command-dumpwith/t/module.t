use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Path::Tiny qw( path );
use Test::TempDir::Tiny qw( tempdir );
use Dist::Zilla::App::Tester qw( test_dzil );

# FILENAME: basic.t
# CREATED: 04/13/15 11:22:34 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Test basic extraction behavior

local $ENV{ANSI_COLORS_DISABLED} = 1;
{
  note "<< Testing -VersionProvider with no plugins";
  my $wd = tempdir();
  path($wd)->child('dist.ini')->spew( simple_ini() );
  my $result = test_dzil( $wd, [ 'dumpwith', '--', '-VersionProvider' ] );
  ok( ref $result, 'self-test executed with no args' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit == 0' );
  note( $result->stdout );
}
{
  note "<< Testing -VersionProvider with AutoVersion";
  require Dist::Zilla::Plugin::AutoVersion;
  my $wd = tempdir();
  path($wd)->child('dist.ini')->spew( simple_ini( ['AutoVersion'] ) );
  my $result = test_dzil( $wd, [ 'dumpwith', '--', '-VersionProvider' ] );
  ok( ref $result, 'self-test executed with no args' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit == 0' );
  note( $result->stdout );
  like( $result->stdout, qr/AutoVersion\s*=>\s*Dist::Zilla::Plugin::AutoVersion/, "report module with version provider" );
}
{
  note "<< Testing Manually expanded -VersionProvider with AutoVersion";
  require Dist::Zilla::Plugin::AutoVersion;
  my $wd = tempdir();
  path($wd)->child('dist.ini')->spew( simple_ini( ['AutoVersion'] ) );
  my $result = test_dzil( $wd, [ 'dumpwith', 'Dist::Zilla::Role::VersionProvider' ] );
  ok( ref $result, 'self-test executed with no args' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit == 0' );
  note( $result->stdout );
  like(
    $result->stdout,
    qr/AutoVersion\s*=>\s*Dist::Zilla::Plugin::AutoVersion/,
    "report module with version provider explicitly"
  );
}

done_testing;

