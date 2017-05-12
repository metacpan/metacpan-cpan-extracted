#!/usr/bin/perl

package Devel::Events::Handler;
use Moose::Role;

requires "new_event";

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Handler - An optional base role for event handlers.

=head1 SYNOPSIS

	package MyGen;
	use Moose;

	with qw/Devel::Events::Handler/;

	sub new_event {
		my ( $self, $type, %data ) = @_;

		# ...
	}


=head1 DESCRIPTION

This convenience role reminds you to add a C<new_event> method.

=head1 REQUIRED METHODS

=over 4

=item new_event @event

Handle a fired event.

=back

=cut


