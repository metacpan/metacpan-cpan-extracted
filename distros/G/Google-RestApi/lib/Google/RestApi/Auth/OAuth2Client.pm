package Google::RestApi::Auth::OAuth2Client;

our $VERSION = '0.7';

use Google::RestApi::Setup;

# this was taken from Net::Google::DataAPI::Auth::OAuth2 and had
# a moose-ectomy. this will get rid of warnings about switching
# to Moo instead of Moose::Any.

use Net::OAuth2::Client;
use Net::OAuth2::Profile::WebServer;
use Storable qw(retrieve);
use URI;

use parent 'Google::RestApi::Auth';

sub new {
  my $class = shift;

  my $self = config_file(@_);
  state $check = compile_named(
    config_file        => Str, { optional => 1 },
    parent_config_file => Str, { optional => 1 },
    client_id          => Str,
    client_secret      => Str,
    token_file         => Str, { optional => 1 },
    scope              => ArrayRef[Str], { optional => 1 },
    state              => Str, { default => '' },
    redirect_uri       => Str, { default => 'urn:ietf:wg:oauth:2.0:oob' },
    site               => Str, { default => 'https://accounts.google.com' },
    authorize_path     => Str, { default => '/o/oauth2/auth' },
    access_token_path  => Str, { default => '/o/oauth2/token' },
    userinfo_url       => Str, { default => 'https://www.googleapis.com/oauth2/v1/userinfo' },
  );
  $self = $check->(%$self);

  $self->{scope} ||= [   # when added to default above, check silently fails to compile.
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  return bless $self, $class;
}

sub headers {
  my $self = shift;
  return $self->{headers} if $self->{headers};

  $self->access_token(
    refresh_token => retrieve($self->token_file())->{refresh_token},
    auto_refresh  => 1,
  );
  $self->refresh_token();
  my $access_token = $self->access_token()->access_token();
  INFO("Successfully attained access token");

  $self->{headers} = [ Authorization => "Bearer $access_token" ];

  return $self->{headers};
}

sub authorize_url {
  my $self = shift;
  my $server = $self->oauth2_webserver();
  return $server->authorize(
    scope => join(' ', @{ $self->{scope} }), @_
  );
}

sub access_token {
  my $self = shift;

  if (scalar @_ == 1) {
    state $check = compile(Str);
    my ($code) = $check->(@_);
    my $server = $self->oauth2_webserver();
    $self->{access_token} = $server->get_access_token($code);
    DEBUG("Created access token:\n", Dump($self->{access_token}));
  } elsif (@_) {
    state $check = compile_named(
      refresh_token => Str,
      auto_refresh  => Bool,
    );
    my $p = $check->(@_);
    $p->{profile} = $self->oauth2_webserver();
    # DEBUG("Building access token from:\n", Dump($p)); # shows secret in the logs.
    $self->{access_token} = Net::OAuth2::AccessToken->new(%$p);
  }

  return $self->{access_token};
}

sub refresh_token {
  my ($self, $refresh_token) = @_;
  DEBUG("About to refresh token");
  my $server = $self->oauth2_webserver();
  $server->update_access_token($self->access_token());
  return $self->access_token()->refresh();
}

sub oauth2_client {
  my $self = shift;
  if (!$self->{oauth2_client}) {
    DEBUG("Creating OAuth2 client");
    $self->{oauth2_client} = Net::OAuth2::Client->new(
      $self->{client_id},
      $self->{client_secret},
      site               => $self->{site},
      authorize_path     => $self->{authorize_path},
      access_token_path  => $self->{access_token_path},
      refresh_token_path => $self->{access_token_path},
    );
  }
  return $self->{oauth2_client};
}

sub oauth2_webserver {
  my $self = shift;
  if (!$self->{oauth2_webserver}) {
    DEBUG("Creating OAuth2 web server");
    my $client = $self->oauth2_client();
    $self->{oauth2_webserver} = $client->web_server(
      redirect_uri => $self->{redirect_uri},
      state        => $self->{state},
    );
  }
  return $self->{oauth2_webserver};
}

sub token_file {
  my $self = shift;
  $self->{_token_file} = resolve_config_file('token_file', $self)
    if !$self->{_token_file};
  return $self->{_token_file};
}

# not currently used
sub userinfo {
  my $self = shift;
  my $token = $self->access_token();
  my $url = URI->new($self->{userinfo_url});
  my $res = $token->get($url);
  $res->is_success or LOGDIE 'userinfo request failed: ' . $res->as_string;
  my %res_params = $self->oauth2_webserver()->params_from_response($res)
    or LOGDIE 'params_from_response for userinfo response failed';
  return \%res_params;
}

1;

__END__

=head1 NAME

Google::RestApi::Auth::OAuth2Client - OAuth2 support for Google Rest APIs

=head1 SYNOPSIS

  use Google::RestApi::Auth::OAuth2Client;

  my $oauth2 = Google::RestApi::Auth::OAuth2Client->new(
    client_id      => 'xxxxxxxxxxxxxxxxxxxxxx.apps.googleusercontent.com',
    client_secret  => 'mys3cr33333333333333t',
    scope          => ['http://spreadsheets.google.com/feeds/'],

    # with web apps, redirect_uri is needed:
    # redirect_uri => 'http://your_app.sample.com/callback',
  );
  my $url = $oauth2->authorize_url();

  # you can add optional parameters:
  my $url = $oauth2->authorize_url(
    access_type     => 'offline',
    approval_prompt => 'force',
  );

  # generate an access token from the code returned from Google:
  my $token = $oauth2->access_token($code);

=head1 DESCRIPTION

Google::RestApi::Auth::OAuth2Client interacts with google OAuth 2.0 service
and creates the 'Authorization' header for use in Furl or LWP::UserAgent.

This was copied from Net::Google::DataAPI::Auth::OAuth2 and modified
to fit this framework. The other framework was dated and produced
constant warnings to upgrade from Moose to Moo. I removed Moose since I
didn't use Moose anywhere else in this framework.

=head1 ATTRIBUTES

=head2 sub new

=over 2

 config_file: Optional YAML configuration file that can specify any
   or all of the following args:
 client_id: The OAuth2 client id you got from Google.
 client_secret: The OAuth2 client secret you got from Google.
 token_file: The file path to the previously saved token (see OAUTH2
   SETUP below). If a config_file is passed, the dirname of the config
   file is tried to find the token_file (same directory) if only the
   token file name is passed.

You can specify any of the arguments in the optional YAML config file.
Any passed in arguments will override what is in the config file.

=item * client_id

client id. You can get it at L<https://code.google.com/apis/console#access>.

=item * client_secret

The client secret paired with the client id.

=item * scope

URL identifying the service(s) to be accessed. You can see the list
of the urls to use at: L<http://code.google.com/intl/en-US/apis/gdata/faq.html#AuthScopes>

=item * redirect_url

OAuth2 redirect url. 'urn:ietf:wg:oauth:2.0:oob' will be used if you don't specify it.

=back

See L<https://developers.google.com/accounts/docs/OAuth2> for details.

=head1 OAUTH2 SETUP

This class depends on first creating an OAuth2 token session file
that you point to via the 'token_file' config param passed via 'new'.
See bin/google_restapi_session_creator and follow the instructions to
save your token file.

=head1 AUTHOR

Robin Murray E<lt>mvsjes@cpan.ork<gt>, copied and modifed from Net::Google::DataAPI::Auth::OAuth2.

=head1 SEE ALSO

L<OAuth2>

L<Google::DataAPI::Auth::OAuth2>

L<https://developers.google.com/accounts/docs/OAuth2> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
