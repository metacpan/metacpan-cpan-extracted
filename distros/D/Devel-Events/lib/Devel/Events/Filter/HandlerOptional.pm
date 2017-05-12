#!/usr/bin/perl

package Devel::Events::Filter::HandlerOptional;
use Moose::Role;

with 'Devel::Events::Filter' => { excludes => [qw(send_filtered_event)] };

has handler => (
	# does => "Devel::Events::Handler", # we like duck typing
	isa => "Object",
	is  => "rw",
	required => 0,
);

sub send_filtered_event {
	my ( $self, @filtered ) = @_;

	if ( my $handler = $self->handler ) {
		$handler->new_event(@filtered);
	} else {
		$self->no_handler_error(@filtered);
	}
}

sub no_handler_error {
	my ( $self, @event ) = @_;

	# silently drop events if we don't have a receiver
}



__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Filter::HandlerOptional - A role for filters that are useful
even without a handler.

=head1 SYNOPSIS

	package MyFilter;
	use Moose;

	with qw/Devel::Events::Filter::HandlerOptional/;

	sub filter_event {
		# do something
	}

=head1 DESCRIPTION

This is just like L<Devel::Events::Filter> except it won't complain if
C<handler> is unset, but instead just drop events.

=head1 SEE ALSO

L<Deve::Events::Filter::Warn>

=cut


