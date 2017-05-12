use strict;

use Test::More;

BEGIN {
    # Plack 0.9913 brings us Plack::Middleware::HTTPExceptions
    eval "use Plack 0.9913";
    plan skip_all => "Plack 0.9913 or newer required for this test" if $@;

    eval "use HTTP::Request::Common";
    plan skip_all => "HTTP::Request::Common required for this test" if $@;
}

use HTTP::Exception;
use Plack::Test;
use HTTP::Status;
use HTTP::Request::Common;

{
    package My::HTTP::Exception;
    use base 'HTTP::Exception::405';

    sub code    { 404 }
    sub my_info { 'Interesting Info' }
}

{
    package My::HTTP::Exception::WithStatusMessage;
    use base 'HTTP::Exception::405';

    sub code    { 404 }
    sub status_message { 'Nothing here' }
}


my @tests = ({
    path                => '/ok',
    exception           => sub { HTTP::Exception::UNAUTHORIZED->throw; },
    expected_code       => 401,
},{
    path                => '/secret',
    exception           => sub { HTTP::Exception::402->throw; },
    expected_code       => 402,
},{
    path                => '/not_found',
    exception           => sub { HTTP::Exception->throw(403); },
    expected_code       => 403,
},{
    path                => '/custom',
    exception           => sub { My::HTTP::Exception->throw; },
    expected_code       => 404,
    expected_content    => HTTP::Status::status_message(405),
},{
    path                => '/custom/with/message',
    exception           => sub { My::HTTP::Exception::WithStatusMessage->throw; },
    expected_code       => 404,
    expected_content    => 'Nothing here',
});

my $app = sub {
    my $env = shift;
    my ($found_test) = grep { $_->{path} eq $env->{PATH_INFO} } @tests;
    HTTP::Exception::500->throw unless ($found_test);
    $found_test->{exception}->();
};

use Plack::Middleware::HTTPExceptions;
$app = Plack::Middleware::HTTPExceptions->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code,      500;
    is $res->content,   'Internal Server Error';

    for my $test (@tests) {
        my $res = $cb->(GET ($test->{path}));
        is $res->code,    $test->{expected_code};
        is $res->content, $test->{expected_content} || HTTP::Status::status_message($test->{expected_code});
    }

};


done_testing;