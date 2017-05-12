use strict;
use warnings;

use Test::More;
use Dist::Zilla::App::Tester;

use Cwd qw(cwd);
my $cwd = cwd();

my $result = test_dzil( $cwd . '/corpus/basic_01', ['dumpphases'] );
ok( ref $result, 'self-test executed' );
is( $result->error,     undef, 'no errors' );
is( $result->exit_code, 0,     'exit = 0' );
note( $result->stdout );

done_testing;
