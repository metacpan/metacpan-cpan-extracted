package Test::Google::RestApi;

use FindBin;
use Storable qw(dclone);
use Test::Most;

use Utils qw(:all);

use aliased 'Google::RestApi';

use parent 'Test::Class';

sub class { 'Google::RestApi' }

sub startup : Tests(startup => 1) {
  my $self = shift;
  use_ok $self->class();
}

sub constructor : Tests(9) {
  my $self = shift;

  my $class = $self->class();
  can_ok $class, 'new';

  my %auth = (
    auth => {
      class         => 'OAuth2Client',
      client_id     => 'x',
      client_secret => 'x',
      token_file    => 'x',
    },
  );

  my $api;
  isa_ok $api = $class->new(%{ dclone(\%auth) }), RestApi, 'Constructor with bad token file';
  throws_ok sub { $api->auth()->token_file() }, qr/not found or is not readable/, 'Bad token file should fail';

  $auth{auth}->{token_file} = token_file();
  $api = $class->new(%{ dclone(\%auth) });
  like $api->auth()->token_file(), qr/token$/, 'Proper token file should be found';

  throws_ok sub { $class->new(config_file => 'x'); },
    qr/Unable to load/, 'Bad config file should fail';

  ok $api = $class->new(config_file => config_file()),
    'Constructor from config_file should succeed';
  isa_ok $api, $class, '... and the object it returns';

  %auth = (
    auth => {
      class        => 'ServiceAccount',
      account_file => 'x',
      scope        => ['x'],
    },
  );

  isa_ok $api = $class->new(%{ dclone(\%auth) }), RestApi, 'Constructor with bad account file';
  throws_ok sub { $api->auth()->account_file() }, qr/not found or is not readable/, 'Bad account file should fail';

  return;
}

sub config_file { "$FindBin::RealBin/etc/rest_config.yaml"; }
sub token_file { "$FindBin::RealBin/etc/rest_config.token"; }

1;
