package TestComb::Mailer::Stub;
# The default stub of TestComb::Mailer: same endpoints, a Mailpit instead.

use Moo;
extends 'TestComb::Mailer';

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
        spec     => { containers => [ { name => 'mailpit', image => 'axllent/mailpit' } ] }
      }
    }
  };
}

1;
