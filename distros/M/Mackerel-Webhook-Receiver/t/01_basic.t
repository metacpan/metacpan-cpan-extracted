use strict;
use warnings;
use utf8;

use Test::More 0.98;
use Plack::Test;
use HTTP::Request::Common;

use Mackerel::Webhook::Receiver;

my $counter;

my $receiver = Mackerel::Webhook::Receiver->new;

$receiver->on(sub {
    $counter++;
});

$receiver->on(alert => sub {
    $counter++;
});

my $app = $receiver->to_app;

test_psgi $app => sub {
    my $cb  = shift;

    my $req = POST '/',
        Content_Type => 'application/json',
        Content => <<'...'
{
  "event": "alert",
  "host": {
    "id": "22D4...",
    "name": "app01",
    "url": "https://mackerel.io/orgs/.../hosts/...",
    "type": "unknown",
    "status": "working",
    "memo": "",
    "isRetired": false,
    "roles": [
      {
        "fullname": "Service: role",
        "serviceUrl": "https://mackerel.io/orgs/.../services/...",
        "roleUrl": "https://mackerel.io/orgs/.../services/..."
      }
    ]
  },
  "alert": {
    "url": "https://mackerel.io/orgs/.../alerts/2bj...",
    "createdAt": 1409823378983,
    "status": "critical",
    "isOpen": true,
    "trigger": "monitor",
    "monitorName": "unreachable"
  }
}
...
    ;
    my $res = $cb->($req);
    is $res->content, 'OK';
    is $counter, 2;

    $req = POST '/',
        Content_Type => 'application/json',
        Content => '{"event":"hoge", "hoge":"fuga"}';
    $res = $cb->($req);
    is $res->content, 'OK';
    is $counter, 3;

    $req = POST '/',
        Content => '{"hoge":"fuga"';
    $res = $cb->($req);
    is $res->content, 'BAD REQUEST';
    is $counter, 3;
};

done_testing;
