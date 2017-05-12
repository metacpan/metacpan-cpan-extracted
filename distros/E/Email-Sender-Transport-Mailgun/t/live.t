use strict;
use Test::More;
use Test::Fatal;

use Email::Sender::Transport::Mailgun;

my @required_vars = qw(
    TEST_MAILGUN_API_KEY
    TEST_MAILGUN_DOMAIN
);

my @missing = grep { !exists $ENV{$_} } @required_vars;

if (@missing) {
    plan skip_all => 'Live test credentials missing',
}

my $api_key = $ENV{TEST_MAILGUN_API_KEY};
my $domain  = $ENV{TEST_MAILGUN_DOMAIN};

my %envelope = (
    from => 'sender@' . $domain,
    to   => $ENV{TEST_MAILGUN_RECIPIENT} || 'recipient@' . $domain,
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
    api_key  => $ENV{TEST_MAILGUN_API_KEY},
    domain   => $ENV{TEST_MAILGUN_DOMAIN},
    testmode => exists $ENV{TEST_MAILGUN_RECIPIENT} ? 'no' : 'yes',
);

my $result;
is(exception { $result = $transport->send($message, \%envelope) },
    undef, 'Mail sent ok');

done_testing;
