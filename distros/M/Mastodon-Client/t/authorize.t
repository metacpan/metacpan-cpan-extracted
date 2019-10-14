use Test2::V0;
use Test2::Tools::Spec;

use Log::Any::Test;
use Log::Any qw( $log );

use Mastodon::Client;

describe 'authorize' => sub {
  before_each 'Clear log' => sub {
    $log->clear;
  };

  describe 'Needs a client_id and client_secret' => sub {
    my %params;

    case 'No client_id' => sub {
      %params = ( client_secret => 'secret' );
    };

    case 'No client_secret' => sub {
      %params = ( client_id => 'id' );
    };

    case 'Neither' => sub {
      %params = ();
    };

    it 'Dies' => sub {
      my $client = Mastodon::Client->new(
        %params,
        instance => 'botsin.space',
      );

      ok dies { $client->authorize }, 'It dies';

      is $log->msgs, [
        {
          level => 'critical',
          message => match(qr/without client_id and client_secret/),
          category => 'Mastodon',
        },
      ], 'Logged dying message';
    };
  };

  describe 'Warnings' => sub {
    my ( %client_params, $post_response, $warning );

    after_each 'Reset' => sub {
      %client_params = ();
      undef $post_response;
    };

    case 'Already authorized' => sub {
      %client_params = ( access_token => 'foo' );
      $warning = match qr/already authorized/;
    };

    case 'It receives an error' => sub {
      $post_response = {
        error             => 1,
        error_description => 'this is a test'
      };
      $warning = 'this is a test';
    };

    it 'Warns' => sub {
      my $mock = mock 'Mastodon::Client', override => [
        post => sub { return $post_response },
      ];

      my $client = Mastodon::Client->new(
        instance      => 'botsin.space',
        client_id     => 'id',
        client_secret => 'secret',
        %client_params,
      );

      is $client->authorize, $client, 'Method returns $self';
      is $log->msgs, [
        {
          message  => $warning,
          level    => 'warning',
          category => 'Mastodon',
        },
      ], 'Raises expected warning';
    };
  };

  it q{Dies if granted scopes don't match} => sub {
    my $client = Mastodon::Client->new(
      instance      => 'botsin.space',
      client_id     => 'id',
      client_secret => 'secret',
    );

    my $mock = mock 'Mastodon::Client', override => [
      post => sub {
        return { scope => $_[2]->{scope} . ' extra' };
      },
    ];

    ok dies { $client->authorize }, 'It dies';

    is $log->msgs, [
      {
        message  => match(qr/scopes do not match/),
        level    => 'critical',
        category => 'Mastodon',
      },
    ];
  };

  it 'Sets access token and authorization time' => sub {
    my $client = Mastodon::Client->new(
      instance      => 'botsin.space',
      client_id     => 'id',
      client_secret => 'secret',
    );

    my $mock = mock 'Mastodon::Client', override => [
      post => sub {
        return {
          scope        => $_[2]->{scope},
          created_at   => '2018-12-16T12:20:40.123Z',
          access_token => 'a token',
        };
      },
    ];

    is $client->authorize, object {
      call access_token => 'a token';
      call authorized   => '2018-12-16T12:20:40';
      etc;
    }, 'Method sets attributes';

    is $log->msgs, [], 'Nothing logged';
  };

  describe 'Accepts different credentials' => sub {
    my ( %check, %params, $data );

    before_each 'Clear data' => sub { undef $data };

    case 'No params' => sub {
      note 'This is legacy behaviour, we should probably die instead';
      %params = ();
      %check = ( username => '', password => '', grant_type => 'password' );
    };

    case 'Access code' => sub {
      %params = ( access_code => 'access_code' );
      %check = ( grant_type => 'authorization_code', code => 'access_code' );
    };

    case 'Username and password' => sub {
      %check = %params = ( username => 'username', password => 'password' );
      $check{grant_type} = 'password';
    };

    it 'Works' => sub {
      my $mock = mock 'Mastodon::Client', override => [
        post => sub {
          ( undef, undef, $data ) = @_;
          return {
            created_at   => 1,
            scope        => $data->{scope} // '',
            access_token => 'mocked_token',
          };
        },
      ];

      my $client = Mastodon::Client->new(
        instance      => 'botsin.space',
        client_id     => 'id',
        client_secret => 'secret',
      );

      $client->authorize( %params );

      is $data, hash {
        field $_             => $check{$_} for keys %check;
        field client_id      => $client->client_id;
        field client_secret  => $client->client_secret;
        field redirect_uri   => T;
        field scope          => T;
        end;
      }, 'Posted correct data payload';

      is $log->msgs, [], 'Nothing logged';
    };
  };
};

done_testing();
