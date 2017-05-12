package Grimlock::Web::Controller::API;
{
  $Grimlock::Web::Controller::API::VERSION = '0.11';
}

use Moose;
use namespace::autoclean;
use Data::Dumper;
BEGIN { extends 'Catalyst::Controller::REST' };

__PACKAGE__->config(
 'default'                              => 'text/html',
  map => {
    'text/html'                         => [ 'View', 'HTML' ],
    'application/json'                  => [ 'View', 'JSON' ],
    'text/x-data-dumper'                => [ 'Data::Serializer', 'Data::Dumper' ],
  }
);

sub base : Chained('/') PathPart('') CaptureArgs(0) {
  my ( $self, $c ) = @_;
  if ( $c->debug ){
    $c->log->debug("***** ENVIRONMENT INFO *****");
    $c->log->debug("Config: " . $ENV{'CATALYST_CONFIG'});
    $c->log->debug("Database connection: " . Dumper $c->model('Database')->schema->storage->connect_info);
  }
}


__PACKAGE__->meta->make_immutable;
1;
