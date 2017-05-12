#!/usr/bin/perl

package Devel::Events::Handler::Callback;
use Moose;

with qw/Devel::Events::Handler/;

has callback => (
	isa => "CodeRef",
	is  => "rw",
	required => 1,
);

around new => sub {
	my $next = shift;
	my ( $class, @args ) = @_;
	@args = ( callback => @args ) if @args == 1;
	$class->$next(@args);
};

sub new_event {
	my ( $self, @event ) = @_;
	$self->callback->( @event );
}


__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Handler::Callback - An event handler that delegates to code references.

=head1 SYNOPSIS

	use Devel::Events::Handler::Callback;

	my $h = Devel::Events::Handler::Callback->new(
		callback => sub {
			my ( $type, %data ) = @_;
			# ...
		},
	);

=head1 DESCRIPTION

This object will let you easily create handlers that are callbacks. This is
used extensively in the test suites.

=head1 ATTRIBUTES

=over 4

=item callback

Accepts a code reference.

Required.

=back

=head1 METHODS

=over 4

=item new

This method is overridden so that when it is passed only one parameter that
parameter will be used for the C<callback> attribute.

=item new_event @event

Delegates to C<callback>.

=back

=cut


