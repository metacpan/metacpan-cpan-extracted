use Mojolicious::Lite; # strict and warnings
use Test::More 0.98;
BEGIN {
  plan skip_all => 'TEST_REDIS=redis://localhost' unless $ENV{TEST_REDIS};
  $ENV{MOJO_MODE}    = 'testing';
  $ENV{MOJO_REACTOR} = 'Mojo::Reactor::Poll';
}
use Test::Mojo;
use Mojo::Redis;
use GraphQL::Type::Scalar qw($String);
use JSON::MaybeXS ();

my $redis = Mojo::Redis->new($ENV{TEST_REDIS});
plugin GraphQL => {
  convert => [
    'MojoPubSub',
    {
      username => $String->non_null,
      message => $String->non_null,
    },
    $redis,
  ],
};
my $t = Test::Mojo->new;

my $true = JSON::MaybeXS::true;
subtest 'status' => sub {
  $t->post_ok('/graphql', json => {
    query => '{ status }',
  })->json_is({ data => { status => $true } })
    ->or(sub { diag explain $t->tx->res->body })
    ;
};

my $wsp = Mojolicious::Plugin::GraphQL->ws_protocol;
my $query_sub = <<'EOF';
subscription s($channels: [String!]) {
  subscribe(channels: $channels) {
    channel
    message
    username
  }
}
EOF
my $init = { type => $wsp->{GQL_CONNECTION_INIT} };
my $ack = { type => $wsp->{GQL_CONNECTION_ACK} };
my $t_sub1 = Test::Mojo->new;
subtest 'subscribe1' => sub {
  my $start1 = {
    payload => {
      query => $query_sub,
      variables => { channels => ['testing'] },
    },
    type => $wsp->{GQL_START},
    id => 1,
  };
  $t_sub1->websocket_ok('/graphql')
    ->send_ok({json => $init})
    ->message_ok->json_message_is($ack)
    ->or(sub { diag explain $t->message })
    ->send_ok({json => $start1});
};
my $t_sub2 = Test::Mojo->new;
subtest 'subscribe2' => sub {
  my $start2 = {
    payload => {
      query => $query_sub,
#      variables => { channels => ['testing'] },
    },
    type => $wsp->{GQL_START},
    id => 2,
  };
  $t_sub2->websocket_ok('/graphql')
    ->send_ok({json => $init})
    ->message_ok->json_message_is($ack)
    ->or(sub { diag explain $t->message })
    ->send_ok({json => $start2});
};
my @messages = (
  { channel => "testing", message => "yo", username => "bob" },
  { channel => "other", message => "hi", username => "bill" },
);
subtest 'publish' => sub {
  $t->post_ok('/graphql', json => {
    query => <<'EOF',
mutation m($messages: [MessageInput!]!) {
  publish(input: $messages)
}
EOF
    variables => { messages => \@messages },
  })->json_like('/data/publish' => qr/\d/)
    ->or(sub { diag explain $t->tx->res->body })
    ;
};
subtest 'notification1' => sub {
  my $data1 = {
    payload => { data => { subscribe => $messages[0] } },
    type => $wsp->{GQL_DATA},
    id => 1,
  };
  $t_sub1->message_ok->json_message_is($data1)
    ->or(sub { diag explain $t->message })
    ;
};
subtest 'notification2' => sub {
  my $data21 = {
    payload => { data => { subscribe => $messages[0] } },
    type => $wsp->{GQL_DATA},
    id => 2,
  };
  my $data22 = {
    payload => { data => { subscribe => $messages[1] } },
    type => $wsp->{GQL_DATA},
    id => 2,
  };
  $t_sub2->message_ok->json_message_is($data21)
    ->or(sub { diag explain $t->message })
    ->message_ok->json_message_is($data22)
    ->or(sub { diag explain $t->message })
    ;
};

done_testing;
