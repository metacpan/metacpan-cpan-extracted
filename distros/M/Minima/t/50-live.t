use v5.40;
use Test2::V0;
use HTTP::Request::Common;

use Minima::Setup;

my $test = Minima::Setup::test;

my $res = $test->request(GET '/');
is( $res->content, "hello, world\n", 'hello, world\n' );

# Move to the complex example in eg/
{
    chdir 'eg';
    $Minima::Setup::app->_read_config; # refresh config in new dir

    local @INC = ( 'lib', @INC );
    local %ENV = %ENV;
    $ENV{PLACK_ENV} = 'development';

    $res = $test->request(GET '/html');
    like( $res->content, qr/<html>/, 'outputs html' );

    $res = $test->request(GET '/ThisURIDoesNotExist');
    is( $res->code, 404, 'handles not found' );
}

done_testing;
