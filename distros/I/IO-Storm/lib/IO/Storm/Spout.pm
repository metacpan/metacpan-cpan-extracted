# ABSTRACT: The base class for all IO::Storm Spout.

package IO::Storm::Spout;
$IO::Storm::Spout::VERSION = '0.17';
# Imports
use strict;
use warnings;
use v5.10;

use Moo;
use namespace::clean;

extends 'IO::Storm::Component';


sub initialize {
    my ( $self, $storm_conf, $context ) = @_;
}


sub ack {
    my ( $self, $id ) = @_;
}


sub fail {
    my ( $self, $id ) = @_;
}


sub next_tuple {
    my ($self) = @_;
}


sub emit ($$;$) {
    my ( $self, $tuple, $args ) = @_;

    my $msg = { command => 'emit', tuple => $tuple };

    if ( defined($args) ) {
        if ( defined( $args->{tup_id} ) ) {
            $msg->{id} = $args->{tup_id};
        }
        if ( defined( $args->{stream} ) ) {
            $msg->{stream} = $args->{stream};
        }
        if ( defined( $args->{direct_task} ) ) {
            $msg->{task} = $args->{direct_task};
        }
    }

    $self->send_message($msg);

    if ( defined $msg->{task} ) {
        return $msg->{task};
    }
    else {
        return $self->read_task_ids();
    }
}


sub run {
    my ($self) = @_;

    my ( $storm_conf, $context ) = $self->read_handshake();
    $self->_setup_component( $storm_conf, $context );
    $self->initialize( $storm_conf, $context );

    while (1) {
        my $msg = $self->read_command();
        if ( $msg->{command} eq 'next' ) {
            $self->next_tuple;
        }
        elsif ( $msg->{command} eq 'ack' ) {
            $self->ack( $msg->{id} );
        }
        elsif ( $msg->{command} eq 'fail' ) {
            $self->fail( $msg->{id} );
        }
        $self->sync();
    }
}

1;

__END__

=pod

=head1 NAME

IO::Storm::Spout - The base class for all IO::Storm Spout.

=head1 VERSION

version 0.17

=head1 NAME

IO::Storm::Spout - The base class for all IO::Storm Spout.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 initialize

Called immediately after the initial handshake with Storm and before the main
run loop. A good place to initialize connections to data sources.

=head2 ack

Called when a bolt acknowledges a tuple in the topology.

=head2 fail

Called when a tuple fails in the topology

A Spout can choose to emit the tuple again or ignore the fail. The default is
to ignore.

=head2 next_tuple

Implement this function to emit tuples as necessary.

This function should not block, or Storm will think the spout is dead. Instead,
let it return and streamparse will send a noop to storm, which lets it know the
spout is functioning.

=head2 emit

Emit a spout tuple message.

:param tup: the tuple to send to Storm.  Should contain only
            JSON-serializable data.
:type tup: list
:param tup_id: the ID for the tuple. Leave this blank for an
               unreliable emit.
:type tup_id: str
:param stream: ID of the stream this tuple should be emitted to.
               Leave empty to emit to the default stream.
:type stream: str
:param direct_task: the task to send the tuple to if performing a
                    direct emit.
:type direct_task: int

=head2 run

Main run loop for all spouts.

Performs initial handshake with Storm and reads tuples handing them off to
subclasses.  Any exceptions are caught and logged back to Storm prior to the
Perl process exiting.

Subclasses should **not** override this method.

=head1 AUTHORS

=over 4

=item *

Cory G Watson <gphat@cpan.org>

=item *

Dan Blanchard <dblanchard@ets.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHORS

=over 4

=item *

Dan Blanchard <dblanchard@ets.org>

=item *

Cory G Watson <gphat@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Educational Testing Service.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
