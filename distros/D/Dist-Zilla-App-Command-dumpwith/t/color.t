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

delete local $ENV{ANSI_COLORS_DISABLED};
{
  note "<< Testing -VersionProvider with AutoVersion + --color-theme";
  require Dist::Zilla::Plugin::AutoVersion;
  my $wd = tempdir('colored-green');
  path($wd)->child('dist.ini')->spew( simple_ini( ['AutoVersion'] ) );
  my $result = test_dzil( $wd, [ 'dumpwith', '--color-theme=basic::green', '--', '-VersionProvider' ] );
  ok( ref $result, 'self-test executed with no args' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit == 0' );
  note( 'stderr:' . $result->stderr );
  note( 'stdout:' . $result->stdout );
  like( $result->stdout, qr/AutoVersion.*?=>.*?Dist::Zilla::Plugin::AutoVersion/, "report module with version provider" );
}
{
  note "<< Testing invalid --color-theme";
  require Dist::Zilla::Plugin::AutoVersion;
  my $wd = tempdir('invalid-color');
  path($wd)->child('dist.ini')->spew( simple_ini( ['AutoVersion'] ) );
  my $result = test_dzil( $wd, [ 'dumpwith', '--color-theme=FAKE::FAKE' ] );
  ok( ref $result, 'self-test executed with no args' );
  isnt( $result->error, undef, 'errors found' ) and note explain $result->error;
  isnt( $result->exit_code, 0, 'exit != 0' );
  like( $result->error, qr/available themes are/, "reports avail themes" );
}
done_testing;

