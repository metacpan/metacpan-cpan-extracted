package Math::StochasticProcess::Event;

use warnings;
use strict;
use Carp;

=head1 NAME

Math::StochasticProcess::Event - Base class for events.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

One uses this module by deriving from it
and defining the virtual functions listed below.
For example see Math::StochasticProcess::Tuple.

=head1 FUNCTIONS

=head2 new

Uneventful constructor for Event class.
The Event instance so created must have probability() == 1.
The set of all possible Events constitutes the probability space.

=cut

sub new {
    my $class = shift;
    my $self = {};
    bless $self, $class;
    return $self;
}

=head2 probability

The probability of having arrived at this event.
Must return a number between 0 and 1 inclusive.

=cut

sub probability {
    my $self = shift;
    croak "not implemented yet";
}

=head2 isResolved

A boolean. If 1 it means that this is a terminal event,
and further iterations of this event are not required.

=cut

sub isResolved {
    my $self = shift;
    croak "not implemented yet";
}

=head2 iterate

This is the key function. It must return a list of new Event objects, that are
the possible iterands of the current event. The current Event object should not
be modified. Obviously the probabilities must add up to the probability of the
parent event.

=cut

sub iterate {
    my $self = shift;
    croak "not implemented yet";
}

=head2 randomVariable

This function must be overridden if you wish to use randomVariables as well as
probabilities. If only the object argument is presented, it must return a hash
keyed by all the random variable names in play, with their current values as the
hash value. If given an argument it must return the current value of the so
named random variable.

=cut

sub randomVariable {
    my $self = shift;
    return {};
}

=head2 signature

A string that uniquely identifies the event. This is used to merge up events
that have been arrived at by different routes.

=cut

sub signature {
    my $self = shift;
    croak "not implemented yet";
}

=head2 merge

This method merges the second Event into the object. It is a requirement
that the two Events have identical signatures. The probability of the combined
Event should equal the sum of the two original Events.

=cut

sub merge {
    my $self = shift;
    croak "not implemented yet";
}

=head2 debug

A string that provides full debug information.

=cut

sub debug {
    my $self = shift;
    return "not implemented yet";
}

=head1 EXAMPLE

Suppose you roll a six-sided die and keep a running total of the results.
You stop rolling when the running total reaches a predetermined goal. What is
the expected number of times that you roll the die, and what is the probability
distribution?

    #!/usr/bin/perl -w
    use strict;
    use warnings;

    use Math::StochasticProcess;
    use Math::StochasticProcess::Event;
    use FileHandle;

    my $goal = $ARGV[0];

    my $seed_event = Math::StochasticProcess::Event::d6->new($goal);
    my $logfh = undef;


    my $analysis = undef;
    if (defined($ARGV[1])) {
        $logfh = FileHandle->new;
        open($logfh, ">$ARGV[1].log") or croak "could not open log file";
        $analysis = Math::StochasticProcess->new
                                        (
                                            seed_event=>$seed_event,
                                            tolerance=>0.0000000000000001,
                                            hard_sanity_level=>0.0000001,
                                            log_file_handle=>$logfh
                                        );
    }
    else {
        $analysis = Math::StochasticProcess->new
                                        (
                                            seed_event=>$seed_event,
                                            tolerance=>0.0000000000000001,
                                            hard_sanity_level=>0.0000001
                                        );
    }
    $analysis->run();
    my %event = $analysis->event();
    my $expectedValue = $analysis->expectedValue('rounds');
    print "Goal: $goal\n";
    print "Expected number of rounds: $expectedValue\n";
    my @keys = sort {(split(/\|/,$a))[0] <=> (split(/\|/,$b))[0]} keys %event;
    foreach my $d (@keys) {
        my $rounds = $event{$d}->randomVariable('rounds');
        my $probability = $event{$d}->probability();
        print "Rounds: $rounds; Probability: $probability\n";
    }

    exit(0);
    package Math::StochasticProcess::Event::d6;
    use base qw(Math::StochasticProcess::Event);

    sub new {
        my $class = shift;
        my $self = Math::StochasticProcess::Event->new();
        $self->{d6_goal} = shift;
        $self->{d6_probability} = 1.0;
        $self->{d6_value} = 0;
        $self->{d6_rounds} = 0;
        bless $self, $class;
        return $self;
    }

    sub probability {
        my $self = shift;
        return $self->{d6_probability};
    }

    sub signature {
        my $self = shift;
        if ($self->isResolved()) {
            return "$self->{d6_rounds}|T";
        }
        return "$self->{d6_rounds}|$self->{d6_value}";
    }

    sub iterate {
        my $self = shift;
        my @new_events;
        for(my $i =1; $i <= 6; $i++) {
            my $e = Math::StochasticProcess::Event->new();
            $e->{d6_probability} = $self->{d6_probability}/6;
            $e->{d6_value} = $self->{d6_value}+$i;
            $e->{d6_rounds} = $self->{d6_rounds}+1;
            $e->{d6_goal} = $self->{d6_goal};
            bless $e, ref($self);
            push @new_events, $e;
        }
        return @new_events;
    }

    sub isResolved {
        my $self = shift;
        return $self->{d6_value} >= $self->{d6_goal} ? 1 : 0;
    }

    sub merge {
        my $self = shift;
        my $other = shift;
        $self->{d6_probability} += $other->{d6_probability};
    }

    sub debug {
        my $self = shift;
        my $status = $self->isResolved();
        return "Status: $status Round: $self->{d6_rounds}; \
                Value: $self->{d6_value};\
                Probability: $self->{d6_probability}\n";
    }

    sub randomVariable {
        my $self = shift;
        my %rv = (rounds=>$self->{d6_rounds});
        if (scalar(@_) > 0) {
            return $rv{$_[0]};
        }
        else {
            return %rv;
        }
    }


    1

=head1 AUTHOR

Nicholas Bamber, C<< <theabbot at silasthemonk.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-stochasticprocess-event at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-StochasticProcess>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::StochasticProcess

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-StochasticProcess>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-StochasticProcess>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-StochasticProcess>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-StochasticProcess>

=back

=head1 ACKNOWLEDGEMENTS

=head1 COPYRIGHT & LICENSE

Copyright 2008 Nicholas Bamber, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Math::StochasticProcess::Event
