package Mail::MtPolicyd::Connection::Redis;

use Moose;

our $VERSION = '2.04'; # VERSION
# ABSTRACT: a mtpolicy connection for redis databases

extends 'Mail::MtPolicyd::Connection';

use Redis;


has 'server' => ( is => 'ro', isa => 'Str', default => '127.0.0.1:6379' );
has 'sock' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'sentinels' => ( is => 'ro', isa => 'Maybe[Str]' );
has '_sentinels' => (
  is => 'ro',
  isa => 'ArrayRef[Str]',
  lazy => 1,
  default => sub { [ split(/ \s*,\s*/, shift->sentinels ) ] },
);
has 'service' => ( is => 'ro', isa => 'Maybe[Str]' );

has 'debug' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'password' => ( is => 'ro', isa => 'Maybe[Str]' );
has 'db' => ( is => 'ro', isa => 'Int', default => 0 );

sub _create_handle {
  my $self = shift;
  my %server = ( 'server' => $self->server );
  if( defined $self->sentinels && $self->service ) {
    %server = (
      'sentinels' => $self->_sentinels,
      service => $self->service
    );
  } elsif( defined $self->sock ) {
    %server = ( 'sock' => $self->sock );
  }
  my $redis = Redis->new(
    %server,
    'debug' => $self->debug,
    defined $self->password ? ( 'password' => $self->password ) : (),
  );
  $redis->select( $self->db );
  return $redis;
}

has 'handle' => (
  is => 'rw', isa => 'Redis', lazy => 1,
  default => sub {
    my $self = shift;
    return $self->_create_handle;
  },
);

sub reconnect {
  my $self = shift;
  $self->handle( $self->_create_handle );
  return;
}

sub shutdown {
  my $self = shift;
  $self->handle->wait_all_responses;
  $self->handle->quit;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Connection::Redis - a mtpolicy connection for redis databases

=head1 VERSION

version 2.04

=head1 SYNOPSIS

  <Connection redis>
    server = "127.0.0.1:6379"
    # or
    # sock = "/path/to/sock"
    # or
    # sentinels = "127.0.0.1:12345,127.0.0.1:23456"
    # service = "mymaster"

    db = 0
    # password = "secret"
  </Connection>

=head1 PARAMETERS

=over

=item server (default: '127.0.0.1:6379')

Connect to redis server with TCP/IP.

Format: <host>:<port>

=item sock (default: undef)

Connect to redis server UNIX domain socket.

Specify the path to the UNIX domain socket.

=item sentinels (default: undef)

Specify a comma separated list of sentinel instances to contact
for finding the master for the service specified by "service" below.

=item service (default: undef)

Specify the service to ask the sentinel servers for.

=item debug (default: 0)

Set to 1 to enable debugging of redis connection.

=item password (default: undef)

Set password if required for redis connection.

=item db (default: 0)

Select a redis database to use.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
