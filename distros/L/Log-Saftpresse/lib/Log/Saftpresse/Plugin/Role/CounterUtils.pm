package Log::Saftpresse::Plugin::Role::CounterUtils;

use Moose::Role;

# ABSTRACT: role for plugins to gather statistics/counters
our $VERSION = '1.6'; # VERSION

has 'per_host_counters' => ( is => 'rw', isa => 'Bool', default => 1 );

sub _get_event_host {
	my ( $self, $event ) = @_;
	if( ! $self->per_host_counters ) {
		return;
	}
	if( defined $event->{'host'} ) {
		return( $event->{'host'});
	}
	return 'empty';
}

sub incr_host {
	my ( $self, $event, @params ) = @_;
	return $self->incr( ($self->_get_event_host($event)), @params );
}

sub incr_host_one {
	my ( $self, $event, @params ) = @_;
	return $self->incr_one( ($self->_get_event_host($event)), @params );
}

sub incr_host_max {
	my ( $self, $event, @params ) = @_;
	return $self->incr_max( ($self->_get_event_host($event)), @params );
}

sub count_array_field_values {
	my ( $self, $stash, $field ) = @_;
	if( ! defined $stash->{$field} || ref($stash->{$field}) ne 'ARRAY' ) {
		return;
	}
	foreach my $test ( @{$stash->{$field}} ) {
		$self->incr_host_one($stash, $field, $test );
	}
	return;
}

sub count_fields_value {
	my ( $self, $stash, @fields ) = @_;
	foreach my $field ( @fields ) {
		if( ! defined $stash->{$field} ) { next; }
		$self->incr_host($stash, $field, $stash->{$field} );
	}
	return;
}

sub count_fields_occur {
	my ( $self, $stash, @fields ) = @_;
	foreach my $field ( @fields ) {
		if( ! defined $stash->{$field} ) { next; }
		$self->incr_host_one($stash, $field, $stash->{$field} );
	}
	return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Role::CounterUtils - role for plugins to gather statistics/counters

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
