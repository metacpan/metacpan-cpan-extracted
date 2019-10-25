package Test::Mock::RestApi;

use strict;
use warnings;

use aliased 'Google::RestApi';
use Test::MockObject::Extends;
 
sub new {
  my $self = RestApi->new(
    client_id     => 'mocked_client_id',
    client_secret => 'mocked_client_secret',
    refresh_token => 'mocked_refresh_token',
  );
  $self = Test::MockObject::Extends->new($self);
  $self->mock('token', sub { 'mocked_token'; });
  return $self;
}

1;
