package Mail::MtPolicyd::Connection::Memcached;

use Moose;

our $VERSION = '2.04'; # VERSION
# ABSTRACT: a memcached connection plugin for mtpolicyd

extends 'Mail::MtPolicyd::Connection';


use Cache::Memcached;

has 'servers' => ( is => 'ro', isa => 'Str', default => '127.0.0.1:11211' );
has '_servers' => (
  is => 'ro', isa => 'ArrayRef[Str]', lazy => 1,
  default => sub {
    my $self = shift;
    return [ split(/\s*,\s*/, $self->servers) ];
  },
);

has 'debug' => ( is => 'ro', isa => 'Bool', default => 0 );
has 'namespace' => ( is => 'ro', isa => 'Str', default => '');

sub _create_handle {
  my $self = shift;
  return Cache::Memcached->new( {
    'servers' => $self->_servers,
    'debug' => $self->debug,
    'namespace' => $self->namespace,
  } );
}

has 'handle' => (
  is => 'rw', isa => 'Cache::Memcached', lazy => 1,
  default => sub {
    my $self = shift;
    $self->_create_handle
  },
);

sub reconnect {
  my $self = shift;
  $self->handle( $self->_create_handle );
  return;
}

sub shutdown {
  my $self = shift;
  $self->handle->disconnect_all;
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::Connection::Memcached - a memcached connection plugin for mtpolicyd

=head1 VERSION

version 2.04

=head1 SYNOPSIS

  <Connection memcached>
    module = "Memcached"
    servers = "127.0.0.1:11211"
    # namespace = "mt-"
  </Connection>

=head1 PARAMETERS

=over

=item servers (default: 127.0.0.1:11211)

Comma separated list for memcached servers to connect.

=item debug (default: 0)

Enable to debug memcached connection.

=item namespace (default: '')

Set a prefix used for all keys of this connection.

=back

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
