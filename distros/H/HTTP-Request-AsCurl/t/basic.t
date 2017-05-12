use Test::Most;

use HTTP::Request::Common;
use HTTP::Request::AsCurl qw/as_curl/;


my @tests = ({
    request => GET("example.com"),
    array   => [qw|curl --request GET example.com --dump-header -|],
    win32   => qq|curl ^\n--request GET example.com ^\n--dump-header - ^\n|,
    bourne  => qq|curl \\\n--request GET example.com \\\n--dump-header - \\\n|,
},{
    request => GET("example.com/boop?answer=42"),
    array   => [qw|curl --request GET example.com/boop?answer=42 --dump-header -|],
    win32   => qq|curl ^\n--request GET example.com/boop?answer=42 ^\n--dump-header - ^\n|,
    bourne  => qq|curl \\\n--request GET 'example.com/boop?answer=42' \\\n--dump-header - \\\n|,
},{
    request => POST("example.com"),
    array   => [qw|curl --request POST example.com --dump-header -|],
    win32   => qq|curl ^\n--request POST example.com ^\n--dump-header - ^\n|,
    bourne  => qq|curl \\\n--request POST example.com \\\n--dump-header - \\\n|,
},{
    name     => 'POST example.com with form data',
    request  => POST("example.com", [mars => 'invades', 'venus' => 'peaceful']),
    array => [qw/ curl --request POST example.com --dump-header - /,
        "--data", 'mars=invades',
        "--data", 'venus=peaceful',
    ],
    win32   => qq|curl ^\n--request POST example.com ^\n--dump-header - ^\n| .
        qq|--data mars=invades ^\n| .
        qq|--data venus=peaceful ^\n|,
    bourne  => qq|curl \\\n--request POST example.com \\\n--dump-header - \\\n| . 
        qq|--data mars=invades \\\n| .
        qq|--data venus=peaceful \\\n|,
},{
    name     => 'POST example.com with form data and basic authorization header',
    request  => sub { 
        my $headers = HTTP::Headers->new;
        $headers->authorization_basic('username', 'p@ssw0rd');

        my $request = POST 'example.com', { mars  => 'invades"', venus => 'peaceful' },
            Authorization => $headers->header('Authorization');

        $request->headers($headers);

        return $request;
    },
    array => [qw/curl --request POST example.com --dump-header -/,
        '--user', 'username:p@ssw0rd',
        '--data', 'mars=invades%22',
        '--data', 'venus=peaceful',
    ],
    win32   => qq|curl ^\n--request POST example.com ^\n--dump-header - ^\n| .
        qq|--user username:p\@ssw0rd ^\n| .
        qq|--data mars=invades\^%22 ^\n| .
        qq|--data venus=peaceful ^\n|,
    bourne  => qq|curl \\\n--request POST example.com \\\n--dump-header - \\\n| . 
        qq|--user username:p\@ssw0rd \\\n| .
        qq|--data mars=invades\%22 \\\n| .
        qq|--data venus=peaceful \\\n|,
});

for my $test (@tests) {

    my $request = ref $test->{request} eq 'CODE' 
        ? $test->{request}->()
        : $test->{request};

    # Do not use // operator which is only available in perl v5.10+
    my $name = defined $test->{name} 
        ? $test->{name}
        : $request->method . " " . $request->uri;

    subtest $name => sub {
        is_deeply [as_curl($request)], $test->{array};
        is as_curl($request, pretty => 1, shell => 'bourne'), $test->{bourne};
        is as_curl($request, pretty => 1, shell => 'win32'),  $test->{win32};
    };

}

done_testing;
