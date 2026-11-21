use strict;
use warnings;
use Test::More;

use HTTP::API::Core;
use HTTP::API::Core::Error;

my $secret = 'secret-credential-abc123';

{
    my $error = HTTP::API::Core::Error->new(
        category   => 'transport',
        method     => 'GET',
        url        => "https://api.example.test/private?token=$secret",
        message    => "failed to connect: $secret",
        request_id => "req-$secret",
        retryable  => 1,
    );

    is $error->log_summary,
        'HTTP API error category=transport method=GET retryable=1',
        'transport logs expose only allowlisted metadata';
    unlike $error->log_summary, qr/\Q$secret\E/,
        'routine summary never includes secret-bearing raw fields';
    is $error->url, "https://api.example.test/private?token=$secret",
        'existing structured URL accessor remains unchanged';
    is $error->message, "failed to connect: $secret",
        'existing diagnostic message remains available';
    like "$error", qr/\Q$secret\E/,
        'existing stringification remains unchanged';
}

{
    my $error = HTTP::API::Core::Error->new(
        category  => 'http',
        method    => 'POST',
        status    => 422,
        message   => "malformed content: $secret",
        retryable => 0,
    );
    is $error->log_summary,
        'HTTP API error category=http method=POST status=422 retryable=0',
        'HTTP error summary includes validated HTTP status and safe method';
}

{
    # Constructor metadata may be supplied by a custom transport/application.
    # Do not copy arbitrary values into application logs, even in these fields.
    my $error = HTTP::API::Core::Error->new(
        category  => "transport-$secret",
        method    => "GET $secret",
        status    => "400 $secret",
        message   => "raw error: $secret",
        retryable => 1,
    );
    is $error->log_summary,
        'HTTP API error category=unknown method=OTHER retryable=1',
        'unexpected metadata is replaced with fixed safe labels';
    unlike $error->log_summary, qr/\Q$secret\E/,
        'no attacker-controlled metadata escapes the allowlist';
}

{
    my $error = HTTP::API::Core::Error->new();
    is $error->log_summary,
        'HTTP API error category=unknown method=OTHER retryable=0',
        'missing metadata does not trigger warnings or leak uninitialized values';
}

{
    my $api = HTTP::API::Core->new(
        base_url => 'https://api.example.test',
        retry => { attempts => 1 },
        transport => sub { die "TLS exception: $secret\n" },
    );
    my $error;
    eval { $api->get("/users?token=$secret"); 1 } or $error = $@;
    isa_ok $error, 'HTTP::API::Core::Error';
    is $error->category, 'transport',
        'real transport exceptions keep the original error category';
    is $error->log_summary,
        'HTTP API error category=transport method=GET retryable=1',
        'real transport errors can be logged without raw exception content';
    unlike $error->log_summary, qr/\Q$secret\E/,
        'real transport exception secret is absent from routine log summary';
}

done_testing;
