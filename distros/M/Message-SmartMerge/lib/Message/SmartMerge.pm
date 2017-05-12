package Message::SmartMerge;
$Message::SmartMerge::VERSION = '1.161240';
use 5.006;
use strict;
use warnings FATAL => 'all';
use Message::Match qw(mmatch);
use Message::Transform qw(mtransform);

=head1 NAME

Message::SmartMerge - Enforce downstream transformations on message streams

=cut

=head1 SYNOPSIS

    use Message::SmartMerge;

    my $merge = Message::SmartMerge->new();
    $merge->config({
        merge_instance => 'instance',
    });

    $merge->message({
        instance => 'i1',
        x => 'y',
        this => 'whatever',
    });
    #no merges, so pass through:
    #emit sends { instance => 'i1', x => 'y', this => 'whatever' }
    
    $merge->add_merge({
        merge_id => 'm1',
        match => {x => 'y'},
        transform => {this => 'that'},
    });
    #so we've already passed through a message instance i1, and this new
    #merge matches that, so the module will send a transformed message:
        {   instance => 'i1',
            x => 'y',
            this => 'that',
        }

    #Now send another message through:
    $merge->message({
        instance => 'i1',
        x => 'y',
        this => 'not that',
        something => 'else',
    });
    #merge matches x => 'y', so transforms this => 'that':
    #emit sends:
        {   instance => 'i1',
            x => 'y',
            this => 'that',
            something => 'else'
        }

    $merge->remove_merge('m1');
    #even though we didn't send a message in, removing a merge will trigger
    #an emit to reflect that a change has occurred, specifically that the
    #previously activated transform is no longer in force.  It sends the
    #last message received, without the transform
    #emit sends:
        {   instance => 'i1',
            x => 'y',
            this => 'not that',
            something => 'else'
        }

    #Here's a way the message stream can clear a merge:
    $merge->add_merge({
        merge_id => 'm2',
        match => {
            x => 'y',
        },
        transform => {
            foo => 'bar',
        },
        toggle_fields => ['something'],
    });

    #Since m2 also matches x => 'y', we emit:
        {   instance => 'i1',
            x => 'y',
            this => 'not that',
            something => 'else',
            foo => 'bar',
        }

    $merge->message({
        instance => 'i1',
        x => 'y',
        foo => 'not bar',
        something => 'else',
        another => 'thing',
    });
    #the value of the single defined toggle field ('something') did not
    #change from the first value we saw in it ('else').  So m2 stands:
        {   instance => 'i1',
            x => 'y',
            something => 'else',
            foo => 'bar',
            another => 'thing',
        }
    #even though we passed 'not bar' in with foo, it was transformed to 'bar'

    #Now let's hit the toggle:
    $merge->message({
        instance => 'i1',
        x => 'y',
        foo => 'not bar',
        something => 'other',
        another => 'thing',
    });
    #this will 'permanently' remove the merge m2 for i1; the message passes
    #through untransformed:
        {   instance => 'i1',
            x => 'y',
            foo => 'not bar',
            something => 'other',
            another => 'thing',
        }

    #Here's another way the message stream can clear a merge:
    $merge->add_merge({
        merge_id => 'm3',
        match => {
            i => 'j',
        },
        transform => {
            a => 'b',
        },
        remove_match => {
            remove => 'match',
        },
    });
    #This causes nothing to emit, because there are no instances that match
    #i => 'j'

    $merge->message({
        instance => 'i2',
        x => 'y',
        i => 'j',
        foo => 'not bar',
        a => 'not b',
        something => 'here',
    });
    #this is fun because it matches both m2 and m3.  it would have matched
    #m1 had we not removed it
    #i2 has never been seen before, and m2 is a toggle.  The toggle
    #deallocates itself for an instance if the toggle field changes
    #from the previous to the current message.  Since there was no
    #previous message for i2, the toggle merge deallocates itself for i2
    #before it can take any action.
        {   instance => 'i2',
            x => 'y',
            i => 'j',
            foo => 'not bar',
            something => 'here',
            a => 'b', #rather than 'not b'
        }

    #and now to deallocate m3:
    $merge->message({
        instance => 'i2',
        x => 'y',
        i => 'j',
        a => 'not b',
        remove => 'match',
    });
    #which emits:
        {   instance => 'i2',
            x => 'y',
            i => 'j',
            a => 'not b', #no longer transformed
            remove => 'match',
        }

=head1 DESCRIPTION

In message based programming, we think in terms of streams of messages
flowing from one way-point to another.  Each way-point does only one thing
to messages flowing through it, independent from various other way-points.
The contract between these are required fields in the messages.

This module is designed to modify the state of a stream of messages in a
powerful and configurable way.

Conceptually, it will enforce certain transformations on certain message
streams.  If the nature of the transformation changes, (for instance, if
it expires, or is deallocated some other way), the module will send a
'corrective' message.

We call these configurations 'merges'.  Part of a merge is a transformation.

For example, when a new merge is configured, all of the matching message
instances will be re-sent with the new transform in force.  And when
the merge is removed or expires, all of the matching message instances
are re-sent with their last received values.  This effectively causes the
downstream receiver to be aware of stateful changes, but in a fully
message-oriented fashion.

Merges can be added and removed explicitly with add_merge and remove_merge.
They can also expire, with expire and expire_at.

More interestingly, merges can be deallocated for a given message stream
using one or two configurations: remove_match and toggle_fields.

remove_match is simplest: if a message instance is under the influence of a
given merge that contains a remove_match config, and that message matches
the remove_match, then the merge is, for that instance, deallocated.  The
message passes through that merge unchanged.

toggle_fields is more tricky: it is an array of fields in the message to
consider.  The toggle_fields configured merge will continue to be in force
as long as the value of all of the fields in toggle_fields is un-changed.
As soon as any of those values changes, the merge is, for that instance,
deallocated.

This is pretty abstract stuff; more concrete examples will be forthcoming
in subsequent releases.

=head1 SUBROUTINES/METHODS

=head2 new

    my $merge = Message::SmartMerge->new(state => $previous_state);

=over 4

=item * state (optional)

The hashref returned by a previous invocation of C<get_state>

=back

=cut

sub new {
    my $class = shift;
    my $self = {};
    die "Message::SmartMerge::new: even number of argument required\n"
        if scalar @_ % 2;
    my %args = @_;
    bless ($self, $class);

    $self->{keep_only} = $args{keep_only}
        if $args{keep_only};
    $self->{merges} = $args{state}->{merges} || {};
    $self->{instances} = $args{state}->{instances} || {};
    $self->config($args{state}->{config})
        if  $args{state} and
            $args{state}->{config};
    return $self;
}


=head2 get_state

    my $state_to_save = $merge->get_state();

This method takes no arguments; it returns a hashref to all of the data
necessary to re-create the current behaviour of this library.

Simply put, before your process exits, gather the return value of
get_state, and save it somewhere.  When your process comes up, take that
information and pass it into the state key in the constructor.  The library
will continue functioning as before.

=cut
sub get_state {
    my $self = shift;
    return {
        merges => $self->{merges},
        instances => $self->{instances},
        config => $self->{config},
    };
}

=head2 emit

    $merge->emit(%args)

This method is designed to be over-ridden; the default implementation simply
adds the passed message to the package global
@Message::SmartMerge::return_messages and returns all of the arguments

=over 4

=item * message

The message being sent out, which is a HASHref.

=item * matching_merge_ids

A HASHref whose keys are the merge IDs that were applied, and values are 1.

=item * other: things (TODO)

=back

=cut
our @return_messages = ();
sub emit {
    my $self = shift;
    my %args = @_;
    push @return_messages, $args{message};
    return \%args;
}

=head2 config

    $merge->config({
        merge_instance => 'instance_key',
    });

=over 4

=item * config_def (positional, required)

HASHref of configuration

=over 4

=item * merge_instance (required)

This is a scalar must exist as a key to every incoming message.  The value
of this key must also be a scalar, and represent the 'instance' of a message
stream.  That is, all messages of the same instance are considered a unified
stream.

=back

=back

=cut
sub config {
    my $self = shift;
    my $new_config = shift or die "Message::SmartMerge::config: at least one argument is required\n";
    die "Message::SmartMerge::config: required config attribute 'merge_instance' must be a scalar\n"
        if  not $new_config->{merge_instance} or
            ref $new_config->{merge_instance};
    $self->{config} = $new_config;
    return $new_config;
}

sub _expire_merges {
    my $self = shift;
    my $ts = time;
    foreach my $merge_id (keys %{$self->{merges}}) {
        my $merge = $self->{merges}->{$merge_id};
        if($merge->{expire} < $ts) {
            $self->remove_merge($merge_id);
        }
    }
}

sub _get_only {
    my $self = shift;
    my $message = shift;
    if(not $self->{config} or not $self->{config}->{keep_only}) {
        return $message;
    }
    my $ret = {};
    $ret->{$_} = $message->{$_} for @{$self->{config}->{keep_only}};
    return $ret;
}

=head2 add_merge

    $merge->add_merge({
        merge_id => 'm1',
        match => {x => 'y'},
        transform => {this => 'to that'},
        expire => 120, #expire in two minutes
        expire_at => 1465173300, #expire in June 2016 (TODO)
    });

=over 4

=item * merge_def (first positional, required)

=over 4

=item * merge_id (required)

Unique scalar identifying this merge

=item * match (required)

Message::Match object (HASHref); defines messages this merge applies to

=item * transform (required)

Message::Transform object (HASHref); what changes to make
NOTE: considering not making transform required

=item * expire (optional)

How many seconds (integer) before this merge expires

=item * expire_at (optional) (TODO)

Epoch time (integer) this merge will expire

=back

=back

=head3 exceptions

=over 4

=item * must have at least one argument, a HASH reference

=item * passed merge must have a scalar merge_id

=item * passed merge_id '$merge_id' is already defined

=back

=cut
sub add_merge {
    my $self = shift or die "Message::SmartMerge::add_merge: must be called as a method\n";
    my $merge = shift;
    die "Message::SmartMerge::add_merge: must have at least one argument, a HASH reference\n"
        if  not $merge or
            not ref $merge or
            ref $merge ne 'HASH';
    die "Message::SmartMerge::add_merge: even number of argument required\n"
        if scalar @_ % 2;
    my %args = @_;

    my $merge_id = $merge->{merge_id};
    die "Message::SmartMerge::add_merge: passed merge must have a scalar merge_id\n"
        if  not $merge_id or
            ref $merge_id;
    die "Message::SmartMerge::add_merge: passed merge_id '$merge_id' is already defined\n"
        if $self->{merges}->{$merge_id};
    if($merge->{expire}) {
        $merge->{expire} = time + $merge->{expire};
    } else {
        $merge->{expire} = 2147483647;  #2^31 - 1 job security!
    }
    $self->{merges}->{$merge_id} = $merge;
    #1. iterate through all of the message instances
    #2. for each one that matches the new merge:
    #   a. n/a
    #   b. make a note of the message instance
    #3. for each of the noted message instances,
    #   a. run the transforms
    #   b. emit the message
    my @matched_instances = ();
    foreach my $instance_name (sort keys %{$self->{instances}}) {
        my $instance = $self->{instances}->{$instance_name};
        next unless mmatch $instance->{message}, $merge->{match};

        #this instance matches the new merge
        push @matched_instances, $instance_name;
    }

    #for section 3 above, can I not simply call $self->message() on all of
    #the matched messages?
    $self->message($self->{instances}->{$_}->{message}) for @matched_instances;
    return $merge;
}

=head2 message

    $merge->message({
        instance_key => 'instance1',
        x => 'y',
    });

Coupled with the above defined merge, this message method will call the emit
method thusly: (Assuming it's still before the merge expired)

    (   message => {
            instance_key => 'instance1',
            x => 'y',
            this => 'to that',
        },
        matching_merge_ids => {
            m1 => 1,
        },
    )

=over 4

=item * message (first positional, required)

=back

=head3 exceptions

=over 4

=item * must have at least one argument, a HASH reference

=item * passed message did not have instance field

=back

=cut
sub message {
    my $self = shift or die "Message::SmartMerge::message: must be called as a method\n";
    my $message = shift;
    die "Message::SmartMerge::message: must have at least one argument, a HASH reference\n"
        if  not $message or
            not ref $message or
            ref $message ne 'HASH';
    die "Message::SmartMerge::message: even number of argument required\n"
        if scalar @_ % 2;
    my %args = @_;

    $self->_expire_merges();    #hideously inefficient; have this run at most
                                #once per second TODO

    #1. find message instance
    #2. gather all of the merges that match
    #   a. identify any merges that should be cleared for this instance
    #       aa. check toggle_fields
    #       bb. check remove_match
    #3. eliminate all of the merges that have toggled off or have cleared
    #4. run the transforms
    #5. emit the message
    my $config = $self->{config};
    my $instance_name = $message->{$config->{merge_instance}}
        or die "Message::SmartMerge::message: passed message did not have instance field '$config->{merge_instance}'\n";

    my $instances = $self->{instances};
    my $previous_message;
    if(not $instances->{$instance_name}) {
        $instances->{$instance_name} = {
            cleared_merges => {},
            initial_ts => time,
            message => $self->_get_only($message),
        };
    } else {
        $previous_message = $instances->{$instance_name}->{message};
        $instances->{$instance_name}->{message} = $self->_get_only($message);
    }
    my $instance = $instances->{$instance_name};
    my $matching_merge_ids = {};
    foreach my $merge_id (keys %{$self->{merges}}) {
        next if $instance->{cleared_merges}->{$merge_id};
        my $merge = $self->{merges}->{$merge_id};
        if(mmatch $message, $merge->{match}) {
            my $include = 1;
            #so we have a matching merge that hasn't been previously
            #eliminated
            #figure out if it needs to be eliminated
            if($merge->{toggle_fields}) {   #section 2.a.aa
                foreach my $toggle_field (@{$merge->{toggle_fields}}) {
                    my $toggle_field_value = $message->{$toggle_field};
                    my $previous_toggle_field_value = $previous_message->{$toggle_field};
                    if(     not defined $toggle_field_value or
                            not defined $previous_toggle_field_value or
                            $toggle_field_value ne $previous_toggle_field_value) {
                        #toggles are different; remove this merge
                        $include = 0;
                        $instance->{cleared_merges}->{$merge_id} = 1;
                    }
                }
            }

            if($merge->{remove_match}) { #section 2.a.bb
                if(mmatch $message, $merge->{remove_match}) {
                    $include = 0;
                    $instance->{cleared_merges}->{$merge_id} = 1;
                }
            }

            $matching_merge_ids->{$merge_id} = 1 if $include;
        }
    }
    #at this point, $matching_merge_ids contains all of the merges we need

    my $emit_message = _fast_clone($message);
    #4b: transform any remaining merges
    foreach my $merge_id (keys %{$matching_merge_ids}) {
        my $merge = $self->{merges}->{$merge_id};
        mtransform $emit_message, $merge->{transform};
    }

    $self->emit(message => $emit_message, matching_merge_ids => $matching_merge_ids);
}

sub _fast_clone {
    use Storable;
    my $thing = shift;
    return Storable::dclone $thing;
}



=head2 remove_merge

    $merge->remove_merge('m1');

=over 4

=item * merge_id (first positional, required)

The merge_id to be removed.

=back

=head3 exceptions

=over 4

=item * passed merge_id does not reference an existing merge

=item * must have at least one argument, a scalar

=back

=cut
sub remove_merge {
    my $self = shift or die "Message::SmartMerge::remove_merge: must be called as a method\n";
    my $merge_id = shift;
    die "Message::SmartMerge::remove_merge: must have at least one argument, a scalar\n"
        if  not $merge_id or
            ref $merge_id;
    die "Message::SmartMerge::remove_merge: even number of argument required\n"
        if scalar @_ % 2;
    my %args = @_;

    die "Message::SmartMerge::remove_merge: passed merge_id does not reference an existing merge\n"
        unless $self->{merges}->{$merge_id};
    #should be about the same as add_merge, but 'in reverse'
    #1. iterate through all of the message instances
    #2. for each one that matches the to be deleted merge:
    #   a. skip and remove cleared_merges if cleared_merges matches this merge
    #   b. make a note of the message instance
    #3. for each of the marked message instances,
    #   a. run the transforms
    #   b. emit the message
    my $merge = $self->{merges}->{$merge_id};
    my @matched_instances = ();
    foreach my $instance_name (sort keys %{$self->{instances}}) {
        my $instance = $self->{instances}->{$instance_name};
        if($instance->{cleared_merges}->{$merge_id}) {
            delete $instance->{cleared_merges}->{$merge_id};
            next;
        }
        next unless mmatch $instance->{message}, $merge->{match};

        #this instance matches the new merge
        push @matched_instances, $instance_name;
    }
    delete $self->{merges}->{$merge_id};
    $self->message($self->{instances}->{$_}->{message}) for @matched_instances;
    return $merge;
}

=head1 AUTHOR

Dana M. Diederich, <diederich@gmail.com>

=head1 BUGS

Please report any bugs or feature requests to C<bug-message-smartmerge at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Message-SmartMerge>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SEE ALSO

http://c2.com/cgi/wiki?AlanKayOnMessaging
http://spin.atomicobject.com/2012/11/15/message-oriented-programming/



=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Message::SmartMerge


You can also look for information at:

=over 4

=item * Report bugs and feature requests here

L<https://github.com/dana/perl-Message-SmartMerge/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Message-SmartMerge>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Message-SmartMerge>

=item * Search CPAN

L<https://metacpan.org/module/Message::SmartMerge>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2013 Dana M. Diederich.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Message::SmartMerge

__END__

Notes:

Algo: keep a list of all of the instances.
When a message arrives, 







... other notes...

we need to be able to send a message when there's any expiration.

