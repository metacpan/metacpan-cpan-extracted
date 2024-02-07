use strict;
use Test::More;
use Test::Fatal;

use Email::Sender::Transport::Mailgun;
use JSON::MaybeXS;

{
    no warnings 'redefine';
    *HTTP::Tiny::request = \&mock_request;
}

my @responses;

my %envelope = (
    from => 'sender@test.example.com',
    to   => 'recipient@test.example.com',
);

my $email = <<END_MESSAGE;
From: $envelope{from}
To: $envelope{to}
Subject: This message is going nowhere fast

Dear Recipient,
  You will never receive this.

--
sender
END_MESSAGE

my $transport = Email::Sender::Transport::Mailgun->new(
    api_key  => 'abcdef',
    domain   => 'test.example.com',
);

my $message = 'Something\'s wrong!';
my $ex;

add_response({ message => $message });
$ex = exception { $transport->send($email, \%envelope) };
isa_ok($ex, 'Email::Sender::Failure', 'Failure object');
is($ex->message, $message, 'Got json message');

add_response($message);
$ex = exception { $transport->send($email, \%envelope) };
isa_ok($ex, 'Email::Sender::Failure', 'Failure object');
is($ex->message, $message, 'Got plain message');

add_response($message = encode_json({ unexpected => 'unexpected' }));
$ex = exception { $transport->send($email, \%envelope) };
isa_ok($ex, 'Email::Sender::Failure', 'Failure object');
is($ex->message, $message, 'Got unexpected message');

done_testing;

sub mock_request {
    my ($self, $method, $uri, $data) = @_;
    return shift @responses;
}

sub add_response {
    my ($content) = @_;

    if (ref $content) {
        $content = encode_json($content);
    }
    push(@responses, { success => 0, status => 400, content => $content });
}
