#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;

BEGIN {
    eval "require Dancer2";
    plan skip_all => 'Dancer2 is not installed'
        if $@;

    plan skip_all => "Dancer2 is too old: $Dancer2::VERSION"
        if $Dancer2::VERSION <= 0.166001;   # for to_app()

    warn "Dancer2 version $Dancer2::VERSION\n";

    eval "require Plack::Test";
    $@ and plan skip_all => 'Unable to load Plack::Test';

    eval "require HTTP::Cookies";
    $@ and plan skip_all => 'Unable to load HTTP::Cookies';

    eval "require HTTP::Request::Common";
    $@ and plan skip_all => 'Unable to load HTTP::Request::Common';
    HTTP::Request::Common->import;

    plan tests => 3;
}

{
    package TestApp;
    use Dancer2;

     # Import options can be passed to Log::Report.
     use Dancer2::Plugin::LogReport 'test_app', import => 'dispatcher';
     # or you can just use the plugin to get syntax => 'LONG'
     # use Dancer2::Plugin::LogReport;

    set session => 'Simple';
    set logger  => 'LogReport';

    dispatcher close => 'default';

    get '/write_message/:level/:text' => sub {
        my $level = param('level');
        my $text  = param('text');
        eval qq($level "$text");
    };

    get '/read_message' => sub {
        my $all = session 'messages';
        my $message = pop @$all
            or return '';
        "$message";
    };

    get '/process' => sub {
        process(sub { error "Fatal error text" });
    };

    # Route to add custom handlers during later tests
    get '/add_fatal_handler/:type' => sub {

        my $type = param 'type';

        if ($type eq 'json') {
            fatal_handler sub {
                my ($dsl, $msg, $reason) = @_;
                return unless $dsl->app->request->uri =~ /api/;
                $dsl->send_as(JSON => {message => $msg->toString});
            };
        }
        elsif ($type eq 'html')
        {
            fatal_handler sub {
                my ($dsl, $msg, $reason) = @_;
                return unless $dsl->app->request->uri =~ /html/;
                $dsl->send_as(html => "<p>".$msg->toString."</p>");
            };
        }
    };

}

my $url = 'http://localhost';
my $jar  = HTTP::Cookies->new();
my $test = Plack::Test->create( TestApp->to_app );

# Basic tests to log messages and read from session
subtest 'Basic messages' => sub {

    # Log a notice message
    {
        my $req = GET "$url/write_message/notice/notice_text";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        $jar->extract_cookies($res);

        # Get the message
        $req = GET "$url/read_message";
        $jar->add_cookie_header($req);
        $res = $test->request( $req );
        is ($res->content, 'notice_text');
    }

    # Log a trace message
    {
        my $req = GET "$url/write_message/trace/trace_text";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        $jar->extract_cookies($res);

        # This time it shouldn't make it to the messages session
        $req = GET "$url/read_message";
        $jar->add_cookie_header($req);
        $res = $test->request( $req );
        is ($res->content, '');
    }
};

# Tests to check fatal errors, and catching with process()
subtest 'Throw error' => sub {

    # Throw an uncaught error. Should redirect.
    {
        my $req = GET "$url/write_message/error/error_text";
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
    }

    # The same, this time caught and displayed
    {
        my $req = GET "$url/process";
        $jar->add_cookie_header($req);
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '0';

        # Check caught message is in session
        $jar->extract_cookies($res);
        $req = GET "$url/read_message";
        $jar->add_cookie_header($req);
        $res = $test->request( $req );
        is ($res->content, 'Fatal error text');
    }
};

# Tests to check custom fatal error handlers
subtest 'Custom handler' => sub {

    # Add 2 custom fatal handlers - shoudl only match relevant URLs
    $test->request(GET "$url/add_fatal_handler/json");
    $test->request(GET "$url/add_fatal_handler/html");

    # Throw uncaught errors to see if correct handlers are called.
    # JSON (for API)
    {
        my $req = GET "$url/write_message/error/api_text";
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '{"message":"api_text"}';
    }

    # HTML without redirect
    {
        my $req = GET "$url/write_message/error/html_text";
        my $res = $test->request( $req );
        ok $res->is_success, "get /write_message";
        is $res->content, '<p>html_text</p>';
    }

    # And default (redirect)
    {
        my $req = GET "$url/write_message/error/error_text";
        my $res = $test->request( $req );
        ok $res->is_redirect, "get /write_message";
    }
};

done_testing;

