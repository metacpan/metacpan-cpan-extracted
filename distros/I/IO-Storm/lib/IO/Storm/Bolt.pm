# ABSTRACT: The base class for all IO::Storm Bolts.

package IO::Storm::Bolt;
$IO::Storm::Bolt::VERSION = '0.17';
# Imports
use strict;
use warnings;
use v5.10;
use Try::Tiny;

# Setup Moo for object-oriented niceties
use Moo;
use namespace::clean;

extends 'IO::Storm::Component';

# A boolean indicating whether or not the bolt should automatically
# anchor emits to the incoming tuple ID. Tuple anchoring is how Storm
# provides reliability, you can read more about tuple anchoring in Storm's
# docs:
# https://storm.incubator.apache.org/documentation/Guaranteeing-message-processing.html#what-is-storms-reliability-api
has 'auto_anchor' => (
    is      => 'rw',
    default => 1
);

# A boolean indicating whether or not the bolt should automatically
# acknowledge tuples after ``process()`` is called.
has 'auto_ack' => (
    is      => 'rw',
    default => 1
);

# A boolean indicating whether or not the bolt should automatically fail
# tuples when an exception occurs when the ``process()`` method is called.
has 'auto_fail' => (
    is      => 'rw',
    default => 1
);

# Using a list so Bolt and subclasses can have more than one current_tup
has '_current_tups' => (
    is       => 'rw',
    default  => sub { [] },
    init_arg => undef
);

sub initialize {
    my ( $self, $storm_conf, $context ) = @_;
}

sub process {
    my ( $self, $tuple ) = @_;
}

sub emit ($$;$) {
    my ( $self, $tuple, $args ) = @_;

    $args = $args // {};
    my $msg = { command => 'emit', tuple => $tuple };

    my $anchors = [];
    if ( $self->auto_anchor ) {
        $anchors = $self->_current_tups // [];
    }
    unless ( defined( $args->{anchors} ) ) {
        $args->{anchors} = $anchors;
    }

    for my $a ( @{ $args->{anchors} } ) {
        if ( ref($a) eq "IO::Storm::Tuple" ) {
            $a = $a->id;
        }
        push( @$anchors, $a );
    }

    if ( defined( $args->{stream} ) ) {
        $msg->{stream} = $args->{stream};
    }

    if ( defined( $args->{direct_task} ) ) {
        $msg->{task} = $args->{direct_task};
    }

    $msg->{anchors} = $anchors;

    $self->send_message($msg);

    if ( defined $msg->{task} ) {
        return $msg->{task};
    }
    else {
        return $self->read_task_ids();
    }
}

sub ack {
    my ( $self, $tuple ) = @_;
    my $tup_id;
    if ( ref($tuple) eq "IO::Storm::Tuple" ) {
        $tup_id = $tuple->id;
    }
    else {
        $tup_id = $tuple;
    }
    $self->send_message( { command => 'ack', id => $tup_id } );
}

sub fail {
    my ( $self, $tuple ) = @_;
    my $tup_id;
    if ( ref($tuple) eq "IO::Storm::Tuple" ) {
        $tup_id = $tuple->id;
    }
    else {
        $tup_id = $tuple;
    }

    $self->send_message( { command => 'fail', id => $tup_id } );
}

sub run {
    my ($self) = @_;
    my $tup;

    my ( $storm_conf, $context ) = $self->read_handshake();
    $self->_setup_component( $storm_conf, $context );
    $self->initialize( $storm_conf, $context );

    try {
        while (1) {
            $tup = $self->read_tuple();
            $self->_current_tups( [$tup] );
            if ( $tup->{task} == -1 && $tup->{stream} eq '__heartbeat' ) {
                $self->send_message( { command => 'sync' } );
            }
            else {
                $self->process($tup);
                if ( $self->auto_ack ) {
                    $self->ack($tup);
                }

            }

            # reset so that we don't accidentally fail the wrong tuples
            # if a successive call to read_tuple fails
            $self->_current_tups( [] );
        }
    }
    catch {
        my $error = $_;
        if ( scalar( @{ $self->_current_tups } ) == 1 ) {
            $tup = $self->_current_tups->[0];
            if ( $self->auto_fail ) {
                $self->fail($tup);
            }
        }
        $self->log("Bolt encountered exception: $_");
        die("Encounter exception in Bolt: $_");
    };
}

1;

__END__

=pod

=head1 NAME

IO::Storm::Bolt - The base class for all IO::Storm Bolts.

=head1 VERSION

version 0.17

=head1 NAME

IO::Storm::Bolt - The base class for all IO::Storm Bolts.

=head1 VERSION

version 0.06

=head1 METHODS

=head2 initialize

Called immediately after the initial handshake with Storm and before the main
run loop. A good place to initialize connections to data sources.

=head2 process

Process a single tuple of input. This should be overriden by subclasses

=head2 emit

Emit a tuple to a stream.

:param tuple: the Tuple payload to send to Storm, should contain only
            JSON-serializable data.
:type tuple: arrayref
:param stream: the ID of the stream to emit this tuple to. Specify
               ``undef`` to emit to default stream.
:type stream: scalar
:param anchors: IDs of the tuples (or the <IO::Storm::Tuple> instances) which
                the emitted tuples should be anchored to. If ``auto_anchor`` is
                set and you have not specified ``anchors``, ``anchors`` will be
                set to the incoming/most recent tuple ID(s).
:type anchors: arrayref
:param direct_task: the task to send the tuple to.
:type direct_task: scalar

=head2 ack

Acknowledge a tuple. Argument can be either a Tuple or an ID.

=head2 fail

Fail a tuple. Argument can be either a Tuple or an ID.

=head2 run

Main run loop for all bolts.

Performs initial handshake with Storm and reads tuples handing them off
to subclasses.  Any exceptions are caught and logged back to Storm
prior to the Perl process exiting.

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
