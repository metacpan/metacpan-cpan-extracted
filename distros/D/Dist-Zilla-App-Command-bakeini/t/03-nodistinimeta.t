use strict;
use warnings;

use Test::More;
use Dist::Zilla::Util::Test::KENTNL 1.005000 qw( dztest );

# ABSTRACT: Test basic expansion

my $test = dztest;
my $result = $test->run_command( ['bakeini'] );
ok( ref $result, 'self test executed' );
isnt( $result->error,     undef, 'got errors' );
isnt( $result->exit_code, 0,     'exit != 0' );
like( $result->error, qr/dist\.ini\.meta\s+not\s+found/, 'No dist.ini.meta error' );

done_testing;

