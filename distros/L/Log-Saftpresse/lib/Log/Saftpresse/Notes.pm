package Log::Saftpresse::Notes;

use Moose;

# ABSTRACT: object to hold informations across log events
our $VERSION = '1.6'; # VERSION

has 'data' => ( is => 'rw', isa => 'HashRef', lazy => 1,
	traits => [ 'Hash' ],
	default => sub { {} },
	handles => {
		'reset_data' => 'clear',
	},
);

has 'ring' => ( is => 'rw', isa => 'ArrayRef', lazy => 1,
	traits => [ 'Array' ],
	default => sub { [] },
	handles => {
		'size' => 'count',
		'reset_ring' => 'clear',
	},
);

has 'max_entries' => ( is => 'rw', isa => 'Int', default => 10000 );

sub reset {
	my $self = shift;
	$self->reset_data;
	$self->reset_ring;
	return;
}

sub get {
	my ( $self, $key ) = @_;
	return( $self->data->{$key} );
}

sub set {
	my ( $self, $key, $value ) = @_;

	if( defined $self->data->{$key} ) {
		$self->remove( $key );
	}

	push( @{$self->ring}, $key );
	$self->data->{$key} = $value;

	$self->expire;

	return;
}

sub remove {
	my ( $self, $key ) = @_;

	if( ! defined $self->data->{$key} ) {
		return;
	}
	delete $self->data->{$key};

	# search the array for the key and remove it
	# iterating may be slow, but remove should be rare
	for( my $i = 0 ; $i < scalar(@{$self->ring}) ; $i++ ) {
		if( $self->ring->[$i] eq $key ) {
			splice(@{$self->ring}, $i, 1);
			last;
		}
	}

	return;
}

sub is_full {
	my $self = shift;
	if( $self->size >= $self->max_entries ) {
		return 1;
	}
	return 0;
}

sub expire {
	my $self = shift;
	if( $self->size <= $self->max_entries ) {
		return;
	}
	my $num = $self->size - $self->max_entries;
	foreach my $i ( 1..$num ) {
		my $key = shift @{$self->ring};
		delete $self->data->{$key};
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Notes - object to hold informations across log events

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
