package Test::Google::RestApi;

use Test::Most;
use parent 'Test::Class';

sub class { 'Google::RestApi' }

sub startup : Tests(startup => 1) {
  my $self = shift;
  use_ok $self->class();
}

sub constructor : Tests(3) {
  my $self = shift;
  my $class = $self->class();
  can_ok $class, 'new';
  ok my $api = $class->new(
    client_id     => 'x',
    client_secret => 'x',
    refresh_token => 'x',
  ), '... and the constructor should succeed';
  isa_ok $api, $class, '... and the object it returns';
}

1;
