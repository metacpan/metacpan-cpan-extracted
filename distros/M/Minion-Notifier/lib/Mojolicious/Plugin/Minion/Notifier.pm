package Mojolicious::Plugin::Minion::Notifier;

use Mojo::Base 'Mojolicious::Plugin';

use Minion::Notifier;
use Mojo::IOLoop;
use Scalar::Util ();

my $isa = sub {
  my ($obj, $class) = @_;
  return $obj && Scalar::Util::blessed($obj) && $obj->isa($class);
};

sub register {
  my ($plugin, $app, $config) = @_;
  $config->{minion} ||= eval { $app->minion } || die 'A minion instance is required';

  my $transport = $config->{transport} || '';
  unless ($transport->$isa('Minion::Notifier::Transport')) {
    if($transport =~ /^wss?:/) {
      require Minion::Notifier::Transport::WebSocket;
      $config->{transport} = Minion::Notifier::Transport::WebSocket->new(url => $transport);
    } elsif ($transport =~ /^redis:/) {
      require Mojo::Redis2;
      require Minion::Notifier::Transport::Redis;
      my $redis = Mojo::Redis2->new(url => $transport);
      $config->{transport} = Minion::Notifier::Transport::Redis->new(redis => $redis);
    } elsif ($config->{minion}->backend->isa('Minion::Backend::Pg')) {
      require Minion::Notifier::Transport::Pg;
      $config->{transport} = Minion::Notifier::Transport::Pg->new(pg => $config->{minion}->backend->pg);
    }
  }

  my $notifier = Minion::Notifier->new($config);
  $app->helper(minion_notifier => sub { $notifier });

  $notifier->setup_worker;
  Mojo::IOLoop->next_tick(sub{ $notifier->setup_listener });

  return $notifier;
}

1;

