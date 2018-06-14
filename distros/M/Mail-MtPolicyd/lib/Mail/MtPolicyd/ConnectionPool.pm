package Mail::MtPolicyd::ConnectionPool;

use strict;
use warnings;
use MooseX::Singleton;

our $VERSION = '2.03'; # VERSION
# ABSTRACT: a singleton to hold all configure connections

has 'pool' => (
  is => 'ro',
  isa => 'HashRef[Mail::MtPolicyd::Connection]',
  lazy => 1,
  default => sub { {} },
  traits => [ 'Hash' ],
  handles => {
    'get_connection' => 'get',
    'add_connection' => 'set',
  }
);

sub get_handle {
  my ( $self, $name ) = @_;
  if( defined $self->pool->{$name} ) {
    return $self->pool->{$name}->handle;
  }
  return;
}

has 'plugin_prefix' => ( is => 'ro', isa => 'Str',
  default => 'Mail::MtPolicyd::Connection::');

sub load_config {
  my ( $self, $config ) = @_;
  foreach my $name ( keys %$config ) {
    $self->load_connection( $name, $config->{$name} );
  }
  return;
}

sub load_connection {
	my ( $self, $name, $params ) = @_;
	if( ! defined $params->{'module'} ) {
		die('no module defined for connection '.$name.'!');
	}
	my $module = $params->{'module'};
	my $class = $self->plugin_prefix.$module;
	my $conn;

	my $code = "require ".$class.";";
	eval $code; ## no critic (ProhibitStringyEval)
	if($@) {
    die('could not load connection '.$name.': '.$@);
  }

	eval {
    $conn = $class->new(
      name => $name,
      %$params,
    );
    $conn->init();
  };
  if($@) {
    die('could not initialize connection '.$name.': '.$@);
  }
	$self->add_connection( $name => $conn );
	return;
}

sub shutdown {
  my $self = shift;

  foreach my $conn ( values %{$self->pool} ) {
    $conn->shutdown(@_); # cascade
  }

  return;
}

sub reconnect {
  my $self = shift;

  foreach my $conn ( values %{$self->pool} ) {
    $conn->reconnect(@_); # cascade
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::MtPolicyd::ConnectionPool - a singleton to hold all configure connections

=head1 VERSION

version 2.03

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Markus Benning <ich@markusbenning.de>.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
