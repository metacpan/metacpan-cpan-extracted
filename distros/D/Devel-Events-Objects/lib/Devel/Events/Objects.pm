#!/usr/bin/perl

package Devel::Events::Objects;

use strict;
use warnings;

our $VERSION = "0.05";

__PACKAGE__;

__END__

=pod

=head1 NAME

Devel::Events::Objects - Object tracking support for L<Devel::Events>

=head1 SYNOPSIS

	use Devel::Cycle;
	use Data::Dumper;

	use Devel::Events::Handler::ObjectTracker;
	use Devel::Events::Filter::RemoveFields;
	use Devel::Events::Generator::Objects;

	my $tracker = Devel::Events::Handler::ObjectTracker->new();

	my $gen = Devel::Events::Generator::Objects->new(
		handler => Devel::Events::Filter::RemoveFields->new(
			fields => [qw/generator/], # don't need to have a ref to $gen in each event
			handler => $tracker,
		),
	);

	$gen->enable(); # start generating events

	$code->(); # check for leaks in this code

	$gen->disable();

	# live_objects is a Tie::RefHash::Weak hash

	my @leaked_objects = keys %{ $tracker->live_objects };

	print "leaked ", scalar(@leaked_objects), " objects\n";

	foreach my $object ( @leaked_objects ) {
		print "Leaked object: $object\n";

		# the event that generated it
		print Dumper( $object, $tracker->live_objects->{$object} );

		find_cycle( $object );
	}

=head1 DESCRIPTION

This package provides an event generator and a handler for L<Devel::Events>,
that facilitate leak checking.

There are two components of this module: L<Devel::Events::Generator::Objects>,
and L<Devel::Events::Handler::ObjectTracker>.

The first one uses some trickery to generate events for every object creation
and destruction in code loaded after it was loaded.

The second one will listen on these events, and track all currently living
objects.

See the L</SYOPSIS> for how to write your own leak tracker, and
L<Catalyst::Plugin::LeakTracker> for a real world application of these classes.

=head1 SEE ALSO

L<Devel::Events>, L<Devel::Events::Filter::Size>,
L<Catalyst::Plugin::LeakTracker>, L<Devel::Cycle>, L<Devel::Leak::Object>

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT & LICENSE

	Copyright (c) 2007 Yuval Kogman. All rights reserved
	This program is free software; you can redistribute it and/or modify it
	under the terms of the MIT license or the same terms as Perl itself.

=cut


