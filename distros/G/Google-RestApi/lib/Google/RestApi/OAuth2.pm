package Google::RestApi::OAuth2;

# this was taken from Net::Google::DataAPI::Auth::OAuth2 and had
# a moose-ectomy. this will get rid of warnings about switching
# to Moo instead of Moose::Any.

use strict;
use warnings;

our $VERSION = '0.3';

use 5.010_000;

use autodie;
use Net::OAuth2::Client;
use Net::OAuth2::Profile::WebServer;
use Type::Params qw(compile compile_named);
use Types::Standard qw(Str Bool ArrayRef HashRef Object);
use URI;
use YAML::Any qw(Dump);

no autovivification;

do 'Google/RestApi/logger_init.pl';

sub new {
  my $class = shift;

  state $check = compile_named(
    client_id         => Str,
    client_secret     => Str,
    scope             => ArrayRef[Str], { optional => 1 },
    redirect_uri      => Str, { default => 'urn:ietf:wg:oauth:2.0:oob' },
    state             => Str, { default => '' },
    site              => Str, { default => 'https://accounts.google.com' },
    authorize_path    => Str, { default => '/o/oauth2/auth' },
    access_token_path => Str, { default => '/o/oauth2/token' },
    userinfo_url      => Str, { default => 'https://www.googleapis.com/oauth2/v1/userinfo' },
  );
  my $self = $check->(@_);

  $self->{scope} ||= [   # when added to default above, check silently fails to compile.
    'https://www.googleapis.com/auth/userinfo.profile',
    'https://www.googleapis.com/auth/userinfo.email',
  ];

  return bless $self, $class;
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

# not currently used
sub userinfo {
  my $self = shift;
  my $token = $self->access_token();
  my $url = URI->new($self->{userinfo_url});
  my $res = $token->get($url);
  $res->is_success or die 'userinfo request failed: ' . $res->as_string;
  my %res_params = $self->oauth2_webserver()->params_from_response($res)
    or die 'params_from_response for userinfo response failed';
  return \%res_params;
}

1;

__END__

=head1 NAME

Google::RestApi::OAuth2 - OAuth2 support for Google Rest APIs

=head1 SYNOPSIS

  use Google::RestApi::OAuth2;

  my $oauth2 = Google::RestApi::OAuth2->new(
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

Google::RestApi::OAuth2 interacts with google OAuth 2.0 service
and adds the 'Authorization' header to subsequent requests.

This was copied from Net::Google::DataAPI::Auth::OAuth2 and modified
to fit this framework. The other framework was dated and produced
constant warnings to upgrade to Moo. I removed Moose since I didn't
use Moose anywhere else in this framework.

=head1 ATTRIBUTES

=head2 sub new

=over 2

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

=head1 AUTHOR

Robin Murray E<lt>mvsjes@cpan.ork<gt>, copied and modifed from Net::Google::DataAPI::Auth::OAuth2.

=head1 SEE ALSO

L<OAuth2>

L<Google::DataAPI::Auth::OAuth2>

L<https://developers.google.com/accounts/docs/OAuth2> 

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
