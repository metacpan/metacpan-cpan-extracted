package Example::Comb::DB;
# ABSTRACT: Example Comb: a PostgreSQL database, borrowed in the examples

# The examples do not run this one: they give it an upstream, so it borrows
# the database from another layer and deploys only the bridge -- a Service
# of the same name pointing there. Its manifests are what runs in the layer
# the others borrow from. The class knows nothing about that: borrowing is
# a state of the instance, decided by whoever builds it.
#
# The password is a Secret the Comb does not create: never credentials in
# the custom resource. Create it next to the Comb:
#
#   kubectl create secret generic db-credentials --from-literal=password=...

use Moo;
extends 'Kubernetes::Comb';

use namespace::autoclean;

sub endpoints { { name => 'postgres', port => 5432 } }

sub manifests {
  my ( $self ) = @_;
  my $name = $self->name;
  my %app  = ( app => $name );
  return (
    {
      apiVersion => 'apps/v1',
      kind       => 'StatefulSet',
      metadata   => { name => $name },
      spec       => {
        serviceName => $name,
        replicas    => 1,
        selector    => { matchLabels => {%app} },
        template    => {
          metadata => { labels => {%app} },
          spec     => { containers => [ {
            name  => 'postgres',
            image => $self->config->{image} // 'postgres:16-alpine',
            env   => [
              { name => 'PGDATA', value => '/var/lib/postgresql/data/pgdata' },
              { name => 'POSTGRES_PASSWORD', valueFrom => { secretKeyRef => {
                name => $name.'-credentials',
                key  => 'password'
              } } }
            ],
            ports          => [ { name => 'postgres', containerPort => 5432 } ],
            readinessProbe => { exec => { command => [ 'pg_isready', '-U', 'postgres' ] } },
            volumeMounts   => [ { name => 'data', mountPath => '/var/lib/postgresql/data' } ]
          } ] }
        },
        volumeClaimTemplates => [ {
          metadata => { name => 'data' },
          spec     => {
            accessModes => [ 'ReadWriteOnce' ],
            resources   => { requests => { storage => $self->config->{storage} // '1Gi' } }
          }
        } ]
      }
    },
    {
      apiVersion => 'v1',
      kind       => 'Service',
      metadata   => { name => $name },
      spec       => {
        selector => {%app},
        ports    => [ { name => 'postgres', port => 5432 } ]
      }
    }
  );
}

1;
