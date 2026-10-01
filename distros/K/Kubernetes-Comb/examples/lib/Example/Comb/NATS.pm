package Example::Comb::NATS;
# ABSTRACT: Example Comb: a NATS server, run locally

# A Comb class as a distribution of your own would ship it: what it offers
# (endpoints) and what it consists of (manifests). Everything else --
# deploying, status, pruning, the status in the custom resource -- is
# Kubernetes::Comb. The resources are named after the Comb, so the Service
# is the one its endpoints are reached through.

use Moo;
extends 'Kubernetes::Comb';

use namespace::autoclean;

sub endpoints {
  return (
    { name => 'client',  port => 4222 },
    { name => 'monitor', port => 8222 }
  );
}

sub manifests {
  my ( $self ) = @_;
  my $name  = $self->name;
  my $image = $self->config->{image} // 'nats:2.10-alpine';
  my %app   = ( app => $name );
  return (
    {
      apiVersion => 'apps/v1',
      kind       => 'Deployment',
      metadata   => { name => $name },
      spec       => {
        replicas => 1,
        selector => { matchLabels => {%app} },
        template => {
          metadata => { labels => {%app} },
          spec     => { containers => [ {
            name  => 'nats',
            image => $image,
            args  => [ '--http_port', '8222' ],
            ports => [
              { name => 'client',  containerPort => 4222 },
              { name => 'monitor', containerPort => 8222 }
            ],
            readinessProbe => { httpGet => { path => '/healthz', port => 8222 } }
          } ] }
        }
      }
    },
    {
      apiVersion => 'v1',
      kind       => 'Service',
      metadata   => { name => $name },
      spec       => {
        selector => {%app},
        ports    => [
          { name => 'client',  port => 4222 },
          { name => 'monitor', port => 8222 }
        ]
      }
    }
  );
}

1;
