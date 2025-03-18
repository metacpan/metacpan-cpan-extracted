use v5.40;
use Test2::V0;
use HTTP::Request::Common;

use Minima;
use Minima::Setup;
use Plack::Test;

my $test = Minima::Setup::test;

# Basic responses
my $res = $test->request(GET '/');
is( $res->content, "hello, world\n", 'hello, world\n' );

$res = $test->request(HEAD '/');
is( length($res->content), 0, 'returns empty body for HEAD /' );

$Minima::Setup::app->set_config({ automatic_head => 0 });
$res = $test->request(HEAD '/');
ok( length($res->content), 'respects config for auto HEAD' );

# Move to the complex example in eg/
{
    chdir 'eg';
    $Minima::Setup::config->{base_dir} .= '/eg';
    $test = Plack::Test->create(Minima::init);

    local @INC = ( 'lib', @INC );
    local %ENV = %ENV;
    $ENV{PLACK_ENV} = 'development';

    $res = $test->request(GET '/html');
    like( $res->content, qr/<html>/, 'outputs html' );

    $res = $test->request(GET '/ThisURIDoesNotExist');
    is( $res->code, 404, 'handles not found' );
}

done_testing;
