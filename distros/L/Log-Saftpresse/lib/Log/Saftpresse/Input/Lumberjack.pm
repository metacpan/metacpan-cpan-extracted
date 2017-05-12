package Log::Saftpresse::Input::Lumberjack;

use Moose;

use Log::Saftpresse::Log4perl;

# ABSTRACT: lumberjack server input plugin for saftpresse
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Input::Server';

use Net::Lumberjack::Reader;

has 'readers' => (
  is => 'ro', isa => 'HashRef[Net::Lumberjack::Reader]',
  default => sub { {} },
);

sub handle_cleanup_connection {
  my ( $self, $conn ) = @_;
  delete $self->readers->{"$conn"};
  return;
}

sub _get_reader {
  my ( $self, $conn ) = @_;
  if( ! defined $self->readers->{"$conn"} ) {
    $self->readers->{"$conn"} = Net::Lumberjack::Reader->new(
      handle => $conn,
    );
  }
  return $self->readers->{"$conn"};
}

sub handle_data {
	my ( $self, $conn ) = @_;
  my @events;
  my $reader = $self->_get_reader( $conn );
  while( my @data = $reader->read_data ) {
    push( @events, @data );
  }
  $reader->send_ack;
	return @events;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Input::Lumberjack - lumberjack server input plugin for saftpresse

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
