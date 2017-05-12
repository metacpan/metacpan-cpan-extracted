=head1 NAME

Konstrukt::Event - Event management

=head1 SYNOPSIS

	#Register for an event:
	#register an object method:
	$Konstrukt::Event->register("eventname", $object, \&sub_reference);
	#note that duplicate entries will be ignored
	
	#deregister from an event:
	#only deregister this method from the specified event:
	$Konstrukt::Event->deregister("eventname", $object, \&sub_reference);
	#deregister all registered method for a specified object:
	$Konstrukt::Event->deregister_all_by_object("eventname", $object);
	
	#fire an event:
	#the optional arguments will be passed to the registered methods
	$Konstrukt::Event->trigger("eventname"[, arg1[, arg2[, ...]]]);

=head1 DESCRIPTION

This module provides event handling within the Konstrukt framework.
You may register object methods for events and you may also fire events,
on which the registered methods are called.
This will help synchonizing some parts/plugins of the framework without glueing
them together too tightly.
 
For a detailed description of the usage of this module see L</SYNOPSIS>

=cut

package Konstrukt::Event;

use strict;
use warnings;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless { events => {} }, $class;
}
#= /new

=head2 init

Initialization of this class

=cut
sub init {
	my ($self) = @_;
	$self->{events} = {};
	return 1;
}
#= /init

=head2 register

Registers an object method for a specified event

B<Parameters>:

=over

=item * $eventname - The name of the event.

=item * $objectref - Reference to the object, whose method should be called

=item * $methodref - Reference to the method, which should be called

=back

=cut
sub register {
	my ($self, $event, $object, $method) = @_;
	
	$Konstrukt::Debug->debug_message("Event = $event, Object = $object, Method = $method") if Konstrukt::Debug::DEBUG;
	if (defined($event) and defined($object) and defined($method)) {
		#save object reference
		$self->{events}->{$event}->{$object}->{object} = $object;
		#save method reference
		$self->{events}->{$event}->{$object}->{$method}->{method} = $method;
		
		return 1;
	} else {
		$Konstrukt::Debug->error_message("At least one of the arguments 'eventname', 'object' or 'method' is not defined! Registration failed.") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /register

=head2 deregister

Deregisters an object method for a specified event

B<Parameters>:

=over

=item * $eventname - The name of the event.

=item * $objectref - Reference to the object, whose method should be deregistered

=item * $methodref - Reference to the method, which should be deregistered

=back

=cut
sub deregister {
	my ($self, $event, $object, $method) = @_;
	
	$Konstrukt::Debug->debug_message("Event = $event, Object = $object, Method = $method") if Konstrukt::Debug::DEBUG;
	if (defined($event) and defined($object) and defined($method)) {
		delete $self->{events}->{$event}->{$object}->{$method};
		if (scalar(keys(%{$self->{events}->{$event}->{$object}})) == 1) {
			#only one item left: {object}-><reference>. delete this hash entry
			delete $self->{events}->{$event}->{$object};
		}
		return 1;
	} else {
		$Konstrukt::Debug->error_message("At least one of the arguments 'eventname', 'object' or 'method' is not defined! Deregistration failed.") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /deregister

=head2 deregister_all_by_object

Deregisters all registered methods of an object from a specified event

B<Parameters>:

=over

=item * $eventname - The name of the event.

=item * $objectref - Reference to the object, whose method should be deregistered

=back

=cut
sub deregister_all_by_object {
	my ($self, $event, $object) = @_;
	
	$Konstrukt::Debug->debug_message("Event = $event, Object = $object)") if Konstrukt::Debug::DEBUG;
	if (defined($event) and defined($object)) {
		delete $self->{events}->{$event}->{$object};
		return 1;
	} else {
		$Konstrukt::Debug->error_message("At least one of the arguments 'eventname' or 'object' is not defined! Deregistration failed.") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /deregister_all_by_object

=head2 trigger

Triggers an event with the specified name and the passed arguments.

B<Parameters>:

=over

=item * $eventname          - The name of the event.

=item * ($arg1, $arg2, ...) - Optional: Arguments that should be passed to the methods

=back

=cut
sub trigger {
	my ($self, $event, @args) = @_;
	
	if ($event) {
		$Konstrukt::Debug->debug_message("Event = $event, Args = \"" . join('", "', @args) . "\"") if Konstrukt::Debug::DEBUG;
		foreach my $object (keys %{$self->{events}->{$event}}) {
			foreach my $method (keys %{$self->{events}->{$event}->{$object}}) {
				if ($method ne 'object') {
					my $o = $self->{events}->{$event}->{$object}->{object};
					my $m = $self->{events}->{$event}->{$object}->{$method}->{method};
					$Konstrukt::Debug->debug_message("Executing " . ref($o) . "->$m(\"" . join('", "', @args) . "\")") if Konstrukt::Debug::DEBUG;
					eval { $o->$m(@args); };
					#errors
					if ($@) {
						chomp($@);
						$Konstrukt::Debug->error_message("Error while executing event '$event'! $@") if Konstrukt::Debug::ERROR;
					}
				}
			}
		}
		return 1;
	} else {
		$Konstrukt::Debug->error_message("The event name is not defined! Trigger failed.") if Konstrukt::Debug::ERROR;
	}
}
#= /trigger

#create global object
sub BEGIN { $Konstrukt::Event = __PACKAGE__->new() unless defined $Konstrukt::Event; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
