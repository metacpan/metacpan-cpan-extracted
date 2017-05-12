package Message::Inform;
{
  $Message::Inform::VERSION = '1.132270';
}

use 5.006;
use strict;
use warnings FATAL => 'all';
use Carp;
use Message::Match qw(mmatch);
use Message::Transform qw(mtransform);
use Data::Dumper;

=head1 NAME

Message::Inform - Intelligently distribute messages over time

=cut

our $config = {};
our $instances = {};
our $tick = 0;
#$instances->{$instance} = {
#   message => $merged_message,
#   config => $most_recently_merged_config,
#   initial_ts => $ts_when_this_appeared
#};


=head1 SYNOPSIS

    use Message::Inform;

    sub a1 {
        my %args = @_;
        #$args{message}
        #$args{action}
        #$args{inform_instance}
        #$args{inform_instance_name}
        #$args{interval_time}
    }
    my $inform = Message::Inform->new;
    $inform->config({
        informs => [
            {   inform_name => 'i1',
                match => { x => 'y' },
                close_match => { x => 'y', level => 'OK' },
                instance => ' specials/"i1:$message->{a}"',
                intervals => {
                    '0' => [    #right away
                        {   action_type => 'open',
                            action_name => 'a1',
                        },{ action_type => 'close',
                            action_name => 'a1',
                        }
                    ],
                    '2' => [   #2 seconds
                        {   action_type => 'open',
                            action_name => 'a1',
                        },{ action_type => 'intermediate',
                            action_name => 'a1',
                        }
                    ],
                }
            }
        ],
        action_map => {
            a1 => 'main::a1',
        },
    });

    $inform->message({x => 'y', a => 'b'});
    #main::a1() calls with this message immediately.
    for (1..4) {
        $inform->message();
        sleep 1;
    }
    #main::a1() calls with the previous message as an 'open' in 2
    #seconds
    $inform->message({x => 'y', a => 'b', something => 'else'});
    #main::a1() immediately calls as an 'intermediate'
    $inform->message({x => 'y', a => 'b', level => 'OK'});
    #main::a1() immediately calls as a 'close'

=head1 DESCRIPTION

This module obviously has some 'deep' and 'subtle' behaviour; this
0.1 release won't describe that, but future releases certainly will.

=head1 SUBROUTINES/METHODS

=head2 new(state => $previous_state)

Typical constructor.  Pass in the output from get_state() to resume
operations as they were at that time.

=cut
sub new {
    my $class = shift;
    my $self = {};

    bless ($self, $class);
    return $self;
}

=head2 config($config)

Set initial config or update running config at any time.
    
=cut
sub config {
    my $self = shift;
    my $new_config = shift;
    $config = $new_config;
    return $config;
}

#select the fastest possible way to clone (and be portable too)
#For now, Storable is what I know
sub _fast_clone {
    use Storable;
    my $thing = shift;
    return Storable::dclone $thing;
}

=head2 get_message_configs($message)

Returns all of the merged configs that will apply to the passed in
message.

=cut
sub get_message_configs {
    my $self = shift;
    my $message = shift;
    my $my_configs = {
        match => {},
        close_match => {},
    };

    my $relevant_informs = $self->get_relevant_informs($message);
    foreach my $type ('match','close_match') {
        foreach my $inform (@{$relevant_informs->{$type}}) {
            mtransform($message, { inform_instance => $inform->{instance}});
            my $instance = $message->{inform_instance};
            $my_configs->{$type}->{$instance} = _fast_clone($message)
                unless $my_configs->{$type}->{$instance};
            mtransform($my_configs->{$type}->{$instance}, _fast_clone($inform));
        }
    }
    return $my_configs;
}

=head2 get_relevant_informs($message)

Returns all of the informs that would apply to the passed in message.

=cut
sub get_relevant_informs {
    my $self = shift;
    my $message = shift;
    my $informs = {
        match => [],
        close_match => [],
    };
    foreach my $inform (@{$config->{informs}}) {
        push @{$informs->{match}}, $inform
            if  $inform->{match} and
                mmatch $message, $inform->{match};
        push @{$informs->{close_match}}, $inform
            if  $inform->{close_match} and
                mmatch $message, $inform->{close_match};
    }
    return $informs;
}

#housekeeping for timing
{
my $last_tick_ts;
sub _handle_tick {
    my $self = shift;
    $last_tick_ts = time unless $last_tick_ts;
    my $tick_delta = time - $last_tick_ts;
    $tick+=$tick_delta;
    #now we need to handle all of the intervals scheduled from
    #$tick-$tick_delta until now ($tick)

    #for now, we do it dumb: full-blown iteration
    foreach my $instance_name (keys %{$instances}) {
        my $instance = $instances->{$instance_name};
        my $previous_instance_tick_offset = $instance->{last_update_tick} - $instance->{initial_tick};
        my $new_instance_tick_offset = $previous_instance_tick_offset + $tick_delta;
        #so we need to fire all of the opens between
        #$previous_instance_tick_offset and $new_instance_tick_offset
        #exclusive to inclusive
        #meaning we do NOT fire anything at $previous_instance_tick_offset
        #and we DO fire anything at $new_instance_tick_offset
        
        my $local_config = _fast_clone($instance->{config});
        foreach my $interval_time (sort {$a <=> $b} keys %{$local_config->{intervals}}) {
            next if $interval_time <= $previous_instance_tick_offset;
            next if $interval_time > $new_instance_tick_offset;
            my $interval = $local_config->{intervals}->{$interval_time};
            $instance->{last_update_tick} = $new_instance_tick_offset;
            foreach my $action (@{$interval}) {
                next unless $action->{action_type};
                next if $action->{action_type} ne 'open';
                eval {
                    my $ret = $self->fire_action($instance->{message}, $action,
                        inform_instance => $instances->{$instance_name},
                        inform_instance_name => $instance_name,
                        interval_time => $interval_time,
                    );
                };
                if($@) {
                    print "Exception: $@\n";
                }
            }
        }
    }
}
}

=head2 message($message)

Send a message into Inform.  This can be called with no arguments
to trigger timed Inform fires if there's no other messages to be
sent.

=cut
sub message {
    my $self = shift;
    my $message = shift;
    if(not $message) { #special case; just keep the pump primed
        $self->_handle_tick();
        return 1;
    }
    my $message_configs = $self->get_message_configs($message);

    my $closed_instances = {}; #so we can skip these if we see any opens
    foreach my $instance_name (keys %{$message_configs->{close_match}}) {
        $closed_instances->{$instance_name} = $message_configs->{close_match}->{$instance_name};
        my $local_config = _fast_clone($message_configs->{close_match}->{$instance_name});
        #now we iterate on the intervals backwards
        #TODO: start on our current interval
        foreach my $interval_time (sort {$a <=> $b} keys %{$local_config->{intervals}}) {
            my $interval = $local_config->{intervals}->{$interval_time};
            foreach my $action (@{$interval}) {
                next unless $action->{action_type};
                next if $action->{action_type} ne 'close';
                eval {
                    my $ret = $self->fire_action($message, $action,
                        inform_instance => $instances->{$instance_name},
                        inform_instance_name => $instance_name,
                        interval_time => $interval_time,
                    );
                };
                if($@) {
                    print "exception: $@";
                }
            }
            delete $instances->{$instance_name};
        }
    }

    foreach my $instance_name (keys %{$message_configs->{match}}) {
        next if $closed_instances->{$instance_name}; #this was closed before; that trumps
        my $local_config = _fast_clone($message_configs->{match}->{$instance_name});
        if(not $instances->{$instance_name}) {  #this is an 'open'
            $instances->{$instance_name} = {
                message => _fast_clone($message),
                config => $local_config,
                initial_ts => time,
                initial_tick => $tick,
                last_message_ts => time,
                last_message_tick => $tick,
                last_update_ts => time,
                last_update_tick => $tick,
            };
            #Here we look for any intervals at '0', and fire them
            if($local_config->{intervals}->{'0'}) {
                foreach my $action (@{$local_config->{intervals}->{'0'}}) {
                    next unless $action->{action_type};
                    next if $action->{action_type} ne 'open';
                    eval {
                        my $ret = $self->fire_action($message, $action,
                            inform_instance => $instances->{$instance_name},
                            inform_instance_name => $instance_name,
                            interval_time => 0,
                        );
                    };
                    if($@) {
                        print "exception: $@";
                    }
                }
            }
        } else {    #this is an 'intermediate'
            my $instance = $instances->{$instance_name};
            $instance->{last_message_ts} = time;
            $instance->{last_message_tick} = $tick;
            $instance->{last_update_ts} = time;
            $instance->{last_update_tick} = $tick;
            $instance->{config} = $local_config;
            mtransform($instance->{message}, $message);
            #Here we fire any defined 'intermediates' at the current interval
            my $instance_tick_offset = $instance->{last_update_tick} - $instance->{initial_tick};
            my $local_config = _fast_clone($instance->{config});
            my $interval;
            my $run_interval_time;
            foreach my $interval_time (sort {$a <=> $b} keys %{$local_config->{intervals}}) {
                next if $interval_time > $instance_tick_offset;
                $interval = $local_config->{intervals}->{$interval_time};
                $run_interval_time = $interval_time;
            }
            $instance->{last_update_tick} = $tick; ##????
            foreach my $action (@{$interval}) {
                next unless $action->{action_type};
                next if $action->{action_type} ne 'intermediate';
                eval {
                    my $ret = $self->fire_action($instance->{message}, $action,
                        inform_instance => $instances->{$instance_name},
                        inform_instance_name => $instance_name,
                        interval_time => $run_interval_time,
                    );
                };
                if($@) {
                    print "Exception: $@\n";
                }
            }
        }
    }
    $self->_handle_tick();
    return $message;
}

=head2 get_state()

Called with no argument, this returns the necessary state to be passed
into a future constructor.  The module will then continue to function
in exactly the same state as it was when get_state() was called.
=cut
sub get_state {
    return {
        tick => $tick,
        config => $config,
        instances => $instances,
    };
}

=head2 fire_action($message, $action)

This might not want to be a public method, but it is for now.

=cut
sub fire_action {
    my ($self, $message, $action, @args) = @_;
    croak 'first argument must be message, a HASH reference'
        if  not $message or
            not ref $message or
            ref $message ne 'HASH';
    croak 'even number of arguments required'
        if scalar @args % 2;
    my %args = @args;
    croak 'passed action must be a HASH reference'
        if  not $action or
            not ref $action or
            ref $action ne 'HASH';
    croak 'passed action must have "action_name" as a defined scalar'
        if  not $action->{action_name} or
            ref $action->{action_name};
    croak "passed action had 'action_name' $action->{action_name} did not have defined action_map"
        unless $config->{action_map}->{$action->{action_name}};
    my $action_message = _fast_clone($message);
    if($action->{transform}) {
        mtransform($action_message, $action->{transform});
    }
    my $ret;
    eval {
        no strict 'refs';
        $ret = &{$config->{action_map}->{$action->{action_name}}}(
            message => $action_message,
            action => $action,
            %args
        );
        if($@) {
            croak "action '$action->{action_name}' failed: $@";
        }
    };
    return $ret;
}

=head1 AUTHOR

Dana M. Diederich, C<diederich@gmail.com>

=head1 BUGS

Please report any bugs or feature requests through L<https://github.com/dana/perl-Message-Inform/issues>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Message::Inform

You can also look for information at:

=over 4

=item * Report bugs here:

L<https://github.com/dana/perl-Message-Inform/issues>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Message-Inform>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Message-Inform>

=item * Search CPAN

L<https://metacpan.org/module/Message::Inform>

=back


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

1; # End of Message::Inform


