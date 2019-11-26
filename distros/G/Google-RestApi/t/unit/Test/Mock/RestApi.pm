package Test::Mock::RestApi;

use strict;
use warnings;

use aliased 'Google::RestApi';
use Test::MockObject::Extends;
 
sub new {
  my $self = RestApi->new(
    auth => {
      class         => 'OAuth2Client',
      client_id     => 'mocked_client_id',
      client_secret => 'mocked_client_secret',
      token_file    => $0,
    },
  );
  $self = Test::MockObject::Extends->new($self);
  $self->mock('token', sub { 'mocked_token'; });
  return $self;
}

1;
