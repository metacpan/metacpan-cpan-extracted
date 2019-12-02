use strict;
use Test::More;
use Test::Fatal;

use Email::Sender::Transport::Mailgun;

my $transport;

$transport = Email::Sender::Transport::Mailgun->new(api_key => 'k', domain => 'd');
is(extract_api($transport->uri), 'api.mailgun.net', 'no region given');

$transport = Email::Sender::Transport::Mailgun->new(api_key => 'k', domain => 'd', region   => 'us');
is(extract_api($transport->uri), 'api.mailgun.net', 'us region set');

$transport = Email::Sender::Transport::Mailgun->new(api_key => 'k', domain => 'd', region   => 'eu');
is(extract_api($transport->uri), 'api.eu.mailgun.net', 'eu region');

my $ex = exception {
    Email::Sender::Transport::Mailgun->new(api_key => 'k', domain => 'd', region => 'at');
};

like(
    $ex,
    qr/^isa check for "region" failed: at is not any of the possible values:/,
    'exception when using unknown region'
);

done_testing;

sub extract_api {
    my $uri = shift;
    return unless defined $uri and $uri ne '';
    $uri =~ m!@(.+?)/!;
    $1;
}
