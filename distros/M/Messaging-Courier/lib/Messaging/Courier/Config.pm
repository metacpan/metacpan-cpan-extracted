package Messaging::Courier::Config;

use strict;
use warnings;

use EO::File;
use EO::Singleton;
use base qw( EO::Singleton );
use File::HomeDir;

sub filefor {
  my $self = shift;
  my $name = shift;
  return EO::File->new( path => [home(),'.courier', $name] );
}

sub getvalue {
  my $self = shift;
  my $key  = shift;
  my $file = $self->filefor( $key );
  my $val = eval { $file->load->content; };
  if ($@) {
    return '';
  } else {
    chomp $val;
    return $val;
  }
}

sub group {
  my $self = Messaging::Courier::Config->new();
  $self->{ group } ||= $self->getvalue('group');
}

sub host {
  my $self = Messaging::Courier::Config->new();
  $self->{ host } ||= $self->getvalue('host');
}

sub port {
  my $self = Messaging::Courier::Config->new();
  $self->{ port } ||= $self->getvalue('port');
}

1;

__END__

=head1 NAME

Courier::Config - configuration module for Courier

=head1 SYNOPSIS

  use Messaging::Courier::Config;

  my $c = Courier->new()

=head1 DESCRIPTION

Courier::Config is an EO::Singleton class that provides a simple disk based
configuration system for Courier.  Its interface from the user perspective is
excessively simple.

=head1 CONFIGURATION

Courier::Config looks for a .courier directory in the users home directory.
It it finds one then it looks for the three possible configuration files:

  group
  port
  host

These files should simply contain the name of the group you want courier to
join on startup, the port of the spread daemon, or the host of the spread
daemon.

If they are not present then Courier drops to acceptable defaults.

=head1 AUTHOR

James A. Duncan <jduncan@fotango.com>

=cut
