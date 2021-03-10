package GuacLite::Plugin::Guacd;

use Mojo::Base 'Mojolicious::Plugin';

sub register {
  my ($plugin, $app, $conf) = @_;
  $app->helper('guacd.tunnel' => \&_tunnel);
}

sub _tunnel {
  my ($c, $client) = @_;

  my $tx = $c->tx;
  $tx->with_protocols('guacamole');
  $tx->with_compression;
  $tx->max_websocket_size(10485760);

  $c->on(finish => sub { $client->close; undef $c; undef $tx; undef $client });
  $client->on(close => sub { $c->finish });

  return $client->connect_p
    ->then(sub { $client->handshake_p })
    ->then(sub {
      my $id = shift;

      my $ws_stream = Mojo::IOLoop->stream($c->tx->connection);
      my $guacd_stream = $client->stream;

      $client->on(instruction => sub {
        $c->send({text => $_[1]});

        return if $ws_stream->can_write;
        _backpressure($guacd_stream => $ws_stream);
      });
      $c->on(text => sub {
        my (undef, $bytes) = @_;

        # OOB messages are sent with empty instruction, for now assume its a ping
        if(substr($bytes, 0, 2) eq '0.') {
          return $c->send({text => $bytes});
        }

        $client->write($bytes);

        return if $guacd_stream->can_write;
        _backpressure($ws_stream => $guacd_stream);
      });
      # initiate by sending the id, except the frontend doesn't want the $
      $id =~ s/^\$//;
      $c->send({text => GuacLite::Client::Guacd::encode(['', $id])});
    });
}

# handle backpressure, but it assumes there already is some don't call unles
# you've checked can_write, that said, don't put it in here for efficiency's sake
sub _backpressure {
  my ($in, $out) = @_;
  $in->stop;
  $out->once(drain => sub { $in->start });
}

1;

