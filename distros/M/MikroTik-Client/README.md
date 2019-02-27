# MikroTik::Client - Non-blocking interface to MikroTik API. [![Build Status](https://travis-ci.org/anparker/mikrotik-client.svg?branch=master)](https://travis-ci.org/anparker/mikrotik-client)

Blocking and non-blocking API interface with queries, command subscriptions
and Promises/A.

```perl
  my $api = MikroTik::Client->new();

  # Blocking
  my $list = $api->command(
      '/interface/print',
      {'.proplist' => '.id,name,type'},
      {type        => ['ipip-tunnel', 'gre-tunnel'], running => 'true'}
  );
  if (my $err = $api->error) { die "$err\n" }
  printf "%s: %s\n", $_->{name}, $_->{type} for @$list;


  # Non-blocking
  my $cv = AE::cv;
  my $tag = $api->command(
      '/system/resource/print',
      {'.proplist' => 'board-name,version,uptime'} => sub {
          my ($api, $err, $list) = @_;
          ...;
          $cv->send;
      }
  );
  $cv->recv;

  # Subscribe
  $tag = $api->subscribe(
      '/interface/listen' => sub {
          my ($api, $err, $res) = @_;
          ...;
      }
  );
  my $t = AE::timer 3, 0, sub { $api->cancel($tag) };

  # Errors handling
  $api->command(
      '/random/command' => sub {
          my ($api, $err, $list) = @_;

          if ($err) {
              warn "Error: $err, category: " . $list->[0]{category};
              return;
          }

          ...;
      }
  );

  # Promises
  $cv  = AE::cv;
  $api->cmd_p('/interface/print')
      ->then(sub { my $res = shift }, sub { my ($err, $attr) = @_ })
      ->finally($cv);
  $cv->recv;
```
