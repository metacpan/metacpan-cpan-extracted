use strict;
use Test::More;
use Test::Fatal;
use Test::Differences;

use DateTime;
use Email::Sender::Transport::Mailgun;

{
    no warnings 'redefine';
    *HTTP::Tiny::request = \&mock_request;
}

my $proto   = 'http';
my $host    = 'mailgun.example.com';
my $api_key = 'abcdef';
my $domain  = 'test.example.com';
my $id      = '<return value>';
my $error   = 'Send failed';

my %envelope = (
    from => 'sender@test.example.com',
    to   => 'recipient@test.example.com',
);

my $message = <<END_MESSAGE;
From: $envelope{from}
To: $envelope{to}
Subject: this message is going nowhere fast

Dear Recipient,

  You will never receive this.

--
sender
END_MESSAGE

my $transport = Email::Sender::Transport::Mailgun->new(
    api_key             => $api_key,
    domain              => $domain,
    base_uri            => "$proto://$host",
    retry_delay_seconds => 0, # no need to wait around
);

my $next_mock_request_fails = 0;
for my $failures_before_success (0 .. $transport->retry_count+2) {

    # Set the mock user agent to fail N times before succeeding.
    $next_mock_request_fails = $failures_before_success;


    my $result;
    my $ex = exception { $result = $transport->send($message, \%envelope) };

    my $should_succeed = $failures_before_success <= $transport->retry_count;
    if ($should_succeed) {
        is_deeply($ex, undef,
            "Mail sent ok after $failures_before_success failures");
        isa_ok($result, 'Email::Sender::Success::MailgunSuccess',
            'Return value type correct');
        is($result->id, $id, 'Return id correct');
    }
    else {
        my $failure_count = $transport->retry_count + 1;
        isa_ok($ex, 'Email::Sender::Failure',
            "Mail failed after $failure_count of $failures_before_success failures");
        is($ex->message, $error, 'Got error message');
    }
}

done_testing;

# Simulate N failing requests before a successful request.
sub mock_request {
    return $next_mock_request_fails-- > 0
        ? { success => 0, content => qq({"message":"$error"}), status => 599 }
        : { success => 1, content => qq({"id":"$id"}),         status => 200 };
}
