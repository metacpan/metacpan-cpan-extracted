package GoogleApps;
use Moose;
use Modern::Perl;
use VUser::Google::ApiProtocol::V2_0;
use VUser::Google::Provisioning::V2_0;
use Config::Auto;
extends qw(MooseX::App::Cmd);
# ABSTRACT: Base class for all commands

our $VERSION = '0.002';

has api => (
   isa => 'VUser::Google::Provisioning::V2_0',
   is => 'ro',
   lazy => 1,
   builder => '_start_api_session',
);

has config => (
   isa => 'HashRef',
   is => 'ro',
   lazy => 1,
   builder => '_parse_config_file',
);

sub _start_api_session {
   my $self = shift;
   my $google = VUser::Google::ApiProtocol::V2_0->new(
      domain   => $self->config->{domain},
      admin    => $self->config->{admin},
      password => $self->config->{password},
      debug    => $self->config->{debug},
   );
   $google->Login();
   die "Authentication failed!" unless $google->IsAuthenticated;
   my $api = VUser::Google::Provisioning::V2_0->new(google => $google);
   say STDERR "Google session started!";
   return $api;
}

sub _parse_config_file {
   return Config::Auto::parse("google-apps.conf");
}

1;
