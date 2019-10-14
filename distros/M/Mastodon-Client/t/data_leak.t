use Test2::V0;
use Test2::Tools::Spec;

use Mastodon::Client;

# Incorrect use of Type::Params coercions for setting defaults caused
# some methods to leak data across instances. This regression test is
# here to make sure that is never again the case.

describe 'Data leaks' => sub {
  tests 'authorization_url' => sub {
    my $alpha = Mastodon::Client->new(
      instance      => 'alpha.botsin.space',
      client_id     => 'alpha_id',
      client_secret => 'alpha_secret',
    );

    my $beta  = Mastodon::Client->new(
      instance      => 'beta.botsin.space',
      client_id     => 'beta_id',
      client_secret => 'beta_secret',
    );

    is $alpha->authorization_url->host, $alpha->instance->uri->host;
    is $beta->authorization_url->host, $beta->instance->uri->host;
  };

  tests 'authorization_url' => sub {
    my $data;

    my $alpha = Mastodon::Client->new(
      name     => 'alpha',
      instance => 'alpha.botsin.space',
    );

    my $beta  = Mastodon::Client->new(
      name     => 'beta',
      instance => 'beta.botsin.space',
    );

    my $mock = mock 'Mastodon::Client', override => [
      post => sub {
        ( undef, undef, $data ) = @_;
        return { client_id => 'id', client_secret => 'secret' };
      },
    ];

    $alpha->register;
    is $data, {
      client_name   => $alpha->name,
      redirect_uris => $alpha->redirect_uri,
      scopes        => join( ' ', sort @{ $alpha->scopes } ),
    };

    $beta->register;
    is $data, {
      client_name   => $beta->name,
      redirect_uris => $beta->redirect_uri,
      scopes        => join( ' ', sort @{ $beta->scopes } ),
    };
  };
};

done_testing();
