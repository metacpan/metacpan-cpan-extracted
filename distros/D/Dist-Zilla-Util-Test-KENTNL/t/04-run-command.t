use strict;
use warnings;

use Test::More;
use Test::DZil qw( simple_ini );
use Dist::Zilla::Util::Test::KENTNL qw( dztest );
use Dist::Zilla::App::Command::authordeps;

# FILENAME: 02-basic-dztest.t
# ABSTRACT: Make sure dztest works

my $test = dztest;
$test->add_file( 'dist.ini', simple_ini( ['GatherDir'] ) );
{
  my $result = $test->run_command( ['authordeps'] );
  ok( ref $result, 'listdeps executed' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit = 0' );
  note( $result->stdout );
}
{
  my $result = $test->run_command( ['build'] );
  ok( ref $result, 'build executed' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit = 0' );
  note( $result->stdout );
}
{
  my $result = $test->run_command( ['build'] );
  ok( ref $result, 'build executed' );
  is( $result->error,     undef, 'no errors' );
  is( $result->exit_code, 0,     'exit = 0' );
  note( $result->stdout );
}

done_testing;

