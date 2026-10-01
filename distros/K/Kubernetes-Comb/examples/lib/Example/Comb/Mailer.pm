package Example::Comb::Mailer;
# ABSTRACT: Example Comb: an SMTP relay, replaced by its stub in the examples

# The real mailer relays through a mail provider, whose credentials are a
# Secret the Comb does not create. check says what is missing, which makes
# the Comb NeedsConfig instead of deploying something that cannot work.
# In the examples it never gets that far: they build its stub,
# Example::Comb::Mailer::Stub, found by the default stub_class.

use Moo;
extends 'Kubernetes::Comb';

use Future;
use namespace::autoclean;

sub endpoints { { name => 'smtp', port => 25 } }

# The Secret with the relay credentials, next to the Comb.
sub relay_secret { shift->name.'-relay' }

sub check {
  my ( $self ) = @_;
  my @missing = defined $self->config->{relay_host} ? () : ('config.relay_host, the provider to relay through');
  my $secret = $self->relay_secret;
  # Any failure counts as missing here; a real class would tell a 404 from
  # a failing API server and fail the Future for the latter.
  return $self->k8s->get( 'Secret', $secret, namespace => $self->namespace )->then(
    sub { Future->done(@missing) },
    sub { Future->done( @missing, 'Secret '.$secret.' with the keys username and password' ) }
  );
}

sub manifests {
  my ( $self ) = @_;
  my $name   = $self->name;
  my $secret = $self->relay_secret;
  my %app    = ( app => $name );
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
            name  => 'postfix',
            image => 'boky/postfix',
            env   => [
              { name => 'RELAYHOST', value => $self->config->{relay_host} },
              { name => 'ALLOW_EMPTY_SENDER_DOMAINS', value => 'true' },
              map { +{
                name      => 'RELAYHOST_'.uc($_),
                valueFrom => { secretKeyRef => { name => $secret, key => $_ } }
              } } qw( username password )
            ],
            ports => [ { name => 'smtp', containerPort => 587 } ]
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
        ports    => [ { name => 'smtp', port => 25, targetPort => 587 } ]
      }
    }
  );
}

1;
