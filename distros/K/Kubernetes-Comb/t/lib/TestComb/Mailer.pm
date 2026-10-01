package TestComb::Mailer;
# A Comb class for the unit tests, loaded at runtime by from_crd.

use Moo;
extends 'Kubernetes::Comb';

sub endpoints {
  return (
    { name => 'smtp', port => 25 },
    { name => 'http', port => 8025, service => 'mailer-web' }
  );
}

sub manifests {
  my ( $self ) = @_;
  return {
    apiVersion => 'apps/v1',
    kind       => 'Deployment',
    metadata   => { name => 'mailer' },
    spec       => {
      selector => { matchLabels => { app => 'mailer' } },
      template => {
        metadata => { labels => { app => 'mailer' } },
        spec     => { containers => [ { name => 'postfix', image => 'postfix' } ] }
      }
    }
  };
}

1;
