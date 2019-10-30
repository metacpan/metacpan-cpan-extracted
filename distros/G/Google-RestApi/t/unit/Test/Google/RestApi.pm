package Test::Google::RestApi;

use FindBin;
use Test::Most;
use parent 'Test::Class';

sub class { 'Google::RestApi' }

sub startup : Tests(startup => 1) {
  my $self = shift;
  use_ok $self->class();
}

sub constructor : Tests(8) {
  my $self = shift;

  my $class = $self->class();
  can_ok $class, 'new';

  throws_ok sub { $class->new(
    client_id     => 'x',
    client_secret => 'x',
    token_file    => 'x',
  ) }, qr/Token file not found/, 'Bad token file should fail';

  throws_ok sub { $class->new(config_file => 'x'); },
    qr/Unable to load/, 'Bad config file should fail';

  throws_ok sub { $class->new(
    config_file => config_file(),
    token_file  => 'x',
  ), }, qr/Token file not found/, 'Overridden token file should fail';

  ok my $api = $class->new(config_file => config_file()),
    'Constructor from config_file should succeed';
  isa_ok $api, $class, '... and the object it returns';

  ok $api = $class->new(
    client_id     => 'x',
    client_secret => 'x',
    token_file    => token_file(),
  ), 'Constructor from named args should succeed';
  isa_ok $api, $class, '... and the object it returns';

  return;
}

sub config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub token_file { "$FindBin::RealBin/etc/rest_config.token"; }

1;
