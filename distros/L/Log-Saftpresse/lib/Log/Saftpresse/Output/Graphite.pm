package Log::Saftpresse::Output::Graphite;

use Moose;

# ABSTRACT: plugin to write events to carbon line reciever
our $VERSION = '1.6'; # VERSION

extends 'Log::Saftpresse::Output';

use Time::Piece;
use IO::Socket::INET;

has 'prefix' => ( is => 'rw', isa => 'Str',
	default => 'saftpresse-metric',
);

has 'type' => ( is => 'rw', isa => 'Str',
	default => 'metric',
);

has '_handle' => (
	is => 'rw', isa => 'IO::Socket::INET', lazy => 1,
	default => sub {
		my $self = shift;
		my $handle = IO::Socket::INET->new(
			PeerAddr => $self->{'host'} || '127.0.0.1',
			PeerPort => $self->{'port'} || '2003',
			Proto => 'tcp',
		) or die('error opening connection to graphite line reciever: '.$@);
		return $handle;
	},
);

sub output {
	my ( $self, @events ) = @_;

	foreach my $event (@events) { 
		if( ! defined $event->{'type'} || $event->{'type'} ne $self->type ) {
			next;
		}
		$self->send_event( $event );
	}

	return;
}

sub send_event {
	my ( $self, $event ) = @_;
	if( ! defined $event->{'path'} || ! defined $event->{'value'} ) {
		return;
	}
	my $ts = $event->{'timestamp'};
	if( ! defined $ts ) {
		$ts = Time::Piece->new->epoch;
	}
	my $host = $event->{'host'};

	my $path = join('.',
		$self->prefix,
		defined $host ? ( 'host', $host ) : ( 'global' ),
		$event->{'path'}
	);

	$self->_handle->print( $path.' '.$event->{'value'}.' '.$ts."\n" );

	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Output::Graphite - plugin to write events to carbon line reciever

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
