use Mojo::Base -strict;

use Test::More;

use GuacLite::Client::Guacd;
use Mojo::IOLoop;
use Mojolicious;
use Test::Mojo;

our (@send, @received);
my $id = Mojo::IOLoop->server({address => '127.0.0.1'}, sub {
  my (undef, $stream, $id) = @_;
  $stream->on(read => sub {
    my ($stream, $bytes) = @_;
    my @instructions = split /;/, $bytes;
    for my $instruction (@instructions) {
      next unless $instruction;
      push @received, "$instruction;";
      my $send = shift @send;
      $stream->write($send) if defined $send;
    }
  });
});
my $port = Mojo::IOLoop->acceptor($id)->port;

subtest 'successful handshake' => sub {
  local @send = (
    '4.args,13.VERSION_1_3_0,8.hostname,4.port;',
    undef, undef, undef,
    '5.ready,5.$1234;',
  );
  local @received;
  my $client = GuacLite::Client::Guacd->new(
    host => '127.0.0.1',
    port => $port,
    connection_args => {
      hostname => 'myhost',
      port => '5900',
    },
  );

  my $err;
  $client->on(error => sub { $err = pop });

  my $app = Mojolicious->new;
  $app->plugin('GuacLite::Plugin::Guacd');
  $app->routes->websocket('/socket' => sub { shift->guacd->tunnel($client) });

  my $t = Test::Mojo->new($app);
  $t->websocket_ok('/socket');
  $t->message_ok('0.,4.1234;');

  # test echo and filtering out of 0-length commands
  $t->send_ok('0.,4.ping;');
  $t->message_ok('0.,4.1234;');

  is_deeply \@received, [
    '6.select,3.vnc;',
    '4.size,4.1024,3.768,2.96;',
    '5.audio;',
    '5.image;',
    '5.video;',
    '7.connect,13.VERSION_1_3_0,6.myhost,4.5900;'
  ];
  ok ! defined $err;
};

done_testing;
