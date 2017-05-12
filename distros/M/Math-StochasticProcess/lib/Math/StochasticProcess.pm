package Math::StochasticProcess;

use warnings;
use strict;
use Params::Validate qw(:all);
use Carp;

=head1 NAME

Math::StochasticProcess - Stochastic Process

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

    use Math::StochasticProcess;

    my $analysis = Math::StochasticProcess->new(seed_event=>It_all_started_here=>new,
                                            tolerance=>0.0001);
    $analysis->run();
    print $analysis->event("Dont_worry_It_might_never_happen")->probability();
    ...

=head1 DESCRIPTION

One defines a stochastic process by inheriting from the
L<Math::StochasticProcess::Event> class and implementing the virtual
functions. The process can be run until all events have become
resolved (or else have probabilities that have dipped below a
tolerance parameter).

As an added convenience one may use the L<Math::StochasticProcess::Event::Tuple>
class which derives from the Event class. This represents a tuple of random
variables. This defines all undefined base functions, apart from "iterate" which
actually defines what how an Event moves to the next iteration.

For theoretical background, see wikipedia articles: L<http://en.wikipedia.org/wiki/Stochastic_matrix>
and L<http://en.wikipedia.org/wiki/Stochastic_processes>.

=head1 FUNCTIONS

=head2 new

This is a standard constructor function. The arguments are as follows:

=over

=item seed_event

This mandatory argument must be an instance of the L<Math::StochasticProcess::Event>
class and its probability must be 1.

=item tolerance

This defaults to 0.00001. It specifies the probability below which
we just throw events away.

=item soft_sanity_level

If specified this determines how far we allow the sum of all probabilities
to diverge from 1, before warning.

=item hard_sanity_level

If specified this determines how far we allow the sum of all probabilities
to diverge from 1, before dieing.

=item log_file_handle

If specified this should be a FileHandle object to which we write our debug statements.

=back

=cut

sub new {
    my $class = shift;
    my %options = validate
    (
        @_,
        {
            seed_event =>
            {
                isa=>'Math::StochasticProcess::Event',
                callbacks=>{'probability must be 1 initially'=>sub {$_[0]->probability() == 1}}
            },
            tolerance=>
            {
                type=>SCALAR,
                callbacks=>{'tolerance must be between 0 and 1'=>sub {$_[0] > 0 and $_[0] < 1}},
                default=>0.00001
            },
            soft_sanity_level=>
            {
                type=>SCALAR,
                callbacks=>{'soft_sanity_level must be between 0 and 1'=>sub {$_[0] > 0 and $_[0] < 1}},
                optional=>1
            },
            hard_sanity_level=>
            {
                type=>SCALAR,
                callbacks=>{'hard_sanity_level must be between 0 and 1'=>sub {$_[0] > 0 and $_[0] < 1}},
                optional=>1
            },
            log_file_handle=>
            {
                isa=>'FileHandle',
                optional=>1
            }
        }
    );
    my $self = \%options;
    bless $self, $class;
    return $self;
}

=head2 run

This is the core function of the whole package.
It iterates from the seed event until no unresolved events remain.
Once it completes the object can be queried for the results.

=cut

sub run {
    my $self = shift;

    my $current_state =
    {
        $self->{seed_event}->signature() => $self->{seed_event}
    };
    while ($self->_numUnresolved($current_state)) {
        $current_state = $self->_iterate($current_state);
    }
    $self->{terminal_events} = $current_state;

    if (exists $self->{log_file_handle}) {
        my %rv = $self->expectedValue();
        foreach my $e (keys %rv) {
            print {$self->{log_file_handle}} "RV: $e -> $rv{$e}\n";
        }
    }
    return;
}

=head2 event

This returns the result of the run. With no additional parameters it runs a list
of signatures and events which can be put in a hash. Otherwise it takes as a
single non-object parameter a signature and returns the corresponding event.

=cut

sub event {
    my $self = shift;
    if (scalar(@_) > 0) {
        return $self->{terminal_events}->{shift};
    }
    return %{$self->{terminal_events}};
}

=head2 expectedValue

This is another function returning the result of the run. With no additional
parameters it runs a list of random variable names and their expected terminal
values. This list can be put into a hash. Otherwise it takes as a single
non-object parameter a random variable name and returns the corresponding
expected value.

=cut

sub expectedValue {
    my $self = shift;
    my %rv = $self->{seed_event}->randomVariable();
    if (scalar(@_) > 0) {
        croak "no such random variable: $_[0]" unless exists $rv{$_[0]};
        return $self->_calculateExpectedValue($_[0]);
    }
    foreach my $r (keys %rv) {
        $rv{$r} = $self->_calculateExpectedValue($r);
    }
    return %rv;
}

=head2 _calculateExpectedValue

Internal function. Used by C<expectedValue>.

=cut

sub _calculateExpectedValue {
    my $self = shift;
    my $name = shift;
    my $value = 0.0;
    foreach my $r (keys %{$self->{terminal_events}}) {
        my $e = $self->{terminal_events}->{$r};
        $value += $e->probability()*$e->randomVariable($name);
    }
    return $value;
}

=head2 _numUnresolved

The number of unresolved events.

=cut

sub _numUnresolved {
    my $self = shift;
    my $state = shift;
    my $num = 0;
    foreach my $k (keys %$state) {
        $num++ unless $state->{$k}->isResolved();
    }
    return $num;
}

=head2 _sanityCheck

Ideally should always be zero, but must at least be close.

=cut

sub _sanityCheck {
    my $self = shift;
    my $state = shift;
    my $check = 1.0;
    foreach my $k (keys %$state) {
        $check -= $state->{$k}->probability();
    }
    return $check;
}

=head2 _iterate

Internal function. Essentially one round in the "run" function.

=cut

sub _iterate {
    my $self = shift;
    my $old_state = shift;
    my $new_state = {};

    foreach my $k (keys %$old_state) {

        my $old_event = $old_state->{$k};

        # We have to have this condition to prevent infinite,
        # or at least very, very, very long looping.
        # It seems to be a lot more robust doing the check
        # here than deeper -- it means less checks
        # and marginal events get a chance to be merged into bigger events
        # and so rescued from this fate.
        next if $old_event->probability() < $self->{tolerance};

        if ($old_event->isResolved()) {
            $self->_merge($new_state, $k, $old_event)
        }
        else {
            my @new_events = $old_event->iterate();
            foreach my $e (@new_events) {

                if (exists $self->{log_file_handle}) {
                    my $p = $e->probability()/$old_event->probability();
                    my $old_sig = $old_event->signature();
                    my $new_sig = $e->signature();
                    print {$self->{log_file_handle}} "$old_sig --> $new_sig : $p \n";
                }

                $self->_merge($new_state, $e->signature(), $e);
            }

        }
    }

    if (exists $self->{soft_sanity_level}) {
        my $sanityCheck = $self->_sanityCheck($new_state);
        carp "sanity check negative: $sanityCheck" if $sanityCheck < -$self->{soft_sanity_level};
        carp "sanity check too big: $sanityCheck" if $sanityCheck > $self->{soft_sanity_level};
    }

    if (exists $self->{hard_sanity_level}) {
        my $sanityCheck = $self->_sanityCheck($new_state);
        croak "sanity check negative: $sanityCheck" if $sanityCheck < -$self->{hard_sanity_level};
        croak "sanity check too big: $sanityCheck" if $sanityCheck > $self->{hard_sanity_level};
    }

    if (exists $self->{log_file_handle}) {
        foreach my $e (keys %$new_state) {
            print {$self->{log_file_handle}} $new_state->{$e}->debug();
        }
        print {$self->{log_file_handle}} "---------------------------------\n";
    }

    return $new_state;
}

=head2 _merge

Internal function. Called inside "run" function when in case two
events are essentially the same.

=cut

sub _merge {
    my $self = shift;
    my $state = shift;
    my $signature = shift;
    my $event = shift;

    if (exists $state->{$signature}) {
        $state->{$signature}->merge($event);
    }
    else {
        $state->{$signature} = $event;
    }
    return;
}

=head1 AUTHOR

Nicholas Bamber, C<< <theabbot at silasthemonk.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-stochasticprocess at rt.cpan.org>, or through the web interface at
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

1; # End of Math::StochasticProcess
