package Math::StochasticProcess::Event::Tuple;

use warnings;
use strict;
use base qw(Math::StochasticProcess::Event);
use Params::Validate qw(:all);
use Carp;
use Exporter qw(import);

use vars qw(@EXPORT_OK);
@EXPORT_OK = qw(RESOLVED_VAR_NAME);

=head1 NAME

Math::StochasticProcess::Event::Tuple - Boilerplate code deriving from Math::StochasticProcess::Event.

=head1 VERSION

Version 0.04

=cut

our $VERSION = '0.04';

=head1 SYNOPSIS

A L<Math::StochasticProcess::RandomVariable> represents a numerical random
variable, a Tuple is a named set of such variables. See below for a worked
example.

=head1 EXPORT

The only function that cab be exported is RESOLVED_VAR_NAME. This is a constant
function returning the name of the special internal random variable, which tracks the state
of the Events. You can also derive from this class and override it in a derived class,
in which case it should not be exported.

=head1 FUNCTIONS

=head2 new

=cut

sub new {
    my $class = shift;
    my %options = validate
    (
        @_,
        {
            random_variables =>
            {
                type=>HASHREF,
                callbacks=>
                {
                    'Hashref of RandomVariables'=>
                    sub
                    {
                        my %randomVariables = %{$_[0]};
                        foreach my $rv (keys %randomVariables) {
                            return 0 unless $randomVariables{$rv}->isa("Math::StochasticProcess::RandomVariable");
                        }
                        return 1;
                    }
                }
            },
            iterate_cb =>
            {
                type=>CODEREF,
                optional=>1
            },
            sig_separator =>  # Define this if your signatures can contain '|'
            {
                type=>SCALAR,
                default=>'|'
            },
            sig_terminator =>  # Define this if your signatures can contain 'T'
            {
                type=>SCALAR,
                default=>'T'
            }
        }
    );
    my $self = \%options;

    # Constructors are used for seed event so set the probability to 1.0.
    $self->{tuple_probability} = 1.0;

    bless $self, $class;

    # We have a special random variable to track whether an Event is resolved.
    $self->{random_variables}->{$self->RESOLVED_VAR_NAME()} =
        Math::StochasticProcess::RandomVariable->new
                                    (
                                        value=>0,
                                        internal=>1,
                                        validate_cb=>sub
                                            {
                                                return $_[0] == 0 || $_[0] == 1;
                                            }
                                    );

    return $self;
}

=head2 probability

The probability of having arrived at this event.
Must return a number between 0 and 1 inclusive.

=cut

sub probability {
    my $self = shift;
    return $self->{tuple_probability};
}

=head2 isResolved

A resolved event requires no further analysis and can ignore its internal
variables.

=cut

sub isResolved {
    my $self = shift;
    return $self->randomVariable($self->RESOLVED_VAR_NAME());
}

=head2 iterate

As per L<Math::StochasticProcess::Event> this is the key function. It must
return a list of new Event objects, that are the possible iterands of the
current event. The current Event object should not be modified. Obviously the
probabilities must add up to the probability of the parent event. In this
context it should use the copy method to generate new Events. So the code should
look something like:

    sub iterate {
        my $self = shift;
        my @results;
        if ($self->condition1()) {
            push @results, $self->copy(0.3, var1=>4);
            push @results, $self->copy(0.7, var1=>sub {return $_[0]+1;});
        }
        elsif ($self->condition2()) {
            push @results, $self->copy(0.6, var1=>5);
            push @results, $self->copy(0.2, var1=>sub {return $_[0]-1;});
            push @results, $self->copy(0.2, var1=>8);
        }
        else {
            push @results, $self->copy(0.6, RESOLVED_VAR_NAME()=>1);
            push @results, $self->copy(0.4, var2=>7);
        }
        return @results;
    }

It also has a particular responsibility to set the RESOLVED_VAR_NAME() random
variable as appropriate. You can either redefine the iterate function in a
derived class (as above) or specify it as a callback in the constructor.

=cut

sub iterate {
    my $self = shift;
    if (exists $self->{iterate_cb}) {
        return $self->{iterate_cb}($self);
    }
    croak "not implemented yet";
}

=head2 copy

This is effectively another constructor as it makes a modified copy of the
object. The first argument is the conditional probability of transitioning from
the parent event to the copy. The rest of the arguments are assumed to be a HASH
mapping variables to their fate. If the value is a CODEREF then that is applied
to the old value of the variable and the returned value becomes the new value of
that random variable.

=cut

sub copy {
    my $self = shift;
    my $probability = shift;
    my %changes = @_;

    my $copy = Math::StochasticProcess::Event->new();

    $copy->{tuple_probability} = $self->{tuple_probability}*$probability;

    $copy->{iterate_cb} = $self->{iterate_cb} if (exists $self->{iterate_cb});
    $copy->{sig_separator} = $self->{sig_separator};
    $copy->{sig_terminator} = $self->{sig_terminator};

    foreach my $rv (keys %{$self->{random_variables}}) {
        if (exists $changes{$rv}) {
            $copy->{random_variables}->{$rv} =
                $self->{random_variables}->{$rv}->copy($changes{$rv});
        }
        else {
            $copy->{random_variables}->{$rv} =
                $self->{random_variables}->{$rv}->copy();
        }
    }

    bless $copy, ref $self;
    return $copy;
}

=head2 randomVariable

This is straightforward implementation of the inherited function, for which see
L<Math::StochasticProcess::Event>. It excludes internal random variables from
the argument-less form, because they are internal. We allow them when asked for
explicitly because it is useful.

=cut

sub randomVariable {
    my $self = shift;
    if (scalar(@_) > 0) {
        my $name = $_[0];
        if (exists $self->{random_variables}->{$name}) {
            my $rv = $self->{random_variables}->{$name};
            return $rv->value();
        }
        croak "$name is not a random variable";
    }
    my %rv = ();
    foreach my $r (keys %{$self->{random_variables}}) {
        $rv{$r} = $self->{random_variables}->{$r}->value() unless
            $self->{random_variables}->{$r}->isInternal();
    }
    return %rv;
}

=head2 RESOLVED_VAR_NAME

This function returns the name of the special RandomVariable used to track when
an Event is resolved. You can either export it or use it an object-oriented way.

=cut

sub RESOLVED_VAR_NAME {
    return "__RESOLVED__";
}

=head2 signature

A string that uniquely identifies the event. This is used to merge up equivalent
events that have been arrived at by different routes. In this implementation,
internal random variables do not figure in the signature if the Event is
resolved.

=cut

sub signature {
    my $self = shift;
    my $result = "";
    my $resolved = $self->isResolved();
    foreach my $r (keys %{$self->{random_variables}}) {
        next if $r eq $self->RESOLVED_VAR_NAME();
        my $rv = $self->{random_variables}->{$r};
        $result .= $rv->signature().$self->{sig_separator} unless $resolved and $rv->isInternal();
    }
    if ($resolved) {
        $result .= $self->{sig_terminator};
    }
    return $result;
}

=head2 merge

This method merges the second Event into the object. It is a requirement that
the two Events have identical signatures. The probability of the combined Event
should equal the sum of the two original Events.

=cut

sub merge {
    my $self = shift;
    my $other = shift;
    croak "cannot merge on account of class" unless ref $self eq ref $other;
    if ($self->signature() ne $other->signature()) {
        croak "cannot merge on account of signature";
    }
    croak "cannot merge on account of signature" unless $self->signature() eq $other->signature();
    $self->{tuple_probability} += $other->{tuple_probability};
    foreach my $r (keys %{$self->{random_variables}}) {
        $self->{random_variables}->{$r}->merge(
                        $other->{random_variables}->{$r},
                        $self->{tuple_probability},
                        $other->{tuple_probability});
    }
    return;
}

=head2 debug

A string that provides full debug information.

=cut

sub debug {
    my $self = shift;
    my $resolved = $self->isResolved() ? "Resolved" : "Unresolved";
    my $probability = $self->probability();
    my $signature = $self->signature();
    my $result = "Signature: $signature; State: $resolved; Probability: $probability\n";
    return $result;
}

=head1 EXAMPLE

This is the same example as in L<Math::StochasticProcess::Event> but redone
using the Tuple class.

    #!/usr/bin/perl -w
    use strict;
    use warnings;

    use Math::StochasticProcess;
    use Math::StochasticProcess::Event;
    use Math::StochasticProcess::Event::Tuple;
    use Math::StochasticProcess::RandomVariable;
    use FileHandle;

    my $goal = $ARGV[0];

    my $seed_event = Math::StochasticProcess::Event::Tuple->new
    (
        random_variables=>
        {
            value=>Math::StochasticProcess::RandomVariable->new
                                                        (
                                                            value=>0,
                                                            internal=>1
                                                        ),
            rounds=>Math::StochasticProcess::RandomVariable->new
                                                        (
                                                            value=>0,
                                                            internal=>0
                                                        )
        },
        iterate_cb=>sub
        {
            my $self = shift;
            my @results;
            my $rounds = $self->randomVariable('rounds');
            my $value = $self->randomVariable('value');
            my $t = $value +7 - $goal;
            my $l = $t < 0 ? 6 : 6-$t;
            if ($t > 0) {
                push @results, $self->copy( $t/6,
                                            RESOLVED_VAR_NAME()=>1,
                                            rounds=>$rounds+1);
            }
            for(my $i = 1; $i <= $l; $i++) {
                push @results, $self->copy( 1/6,
                                            rounds=>$rounds+1,
                                            value=>$value+$i);
            }
            return @results;
        }
    );
    my $logfh = undef;


    my $analysis = undef;
    if (defined($ARGV[1])) {
        $logfh = FileHandle->new;
        open($logfh, ">$ARGV[1]") or croak "could not open log file";
        $analysis = Math::StochasticProcess->new(
                                seed_event=>$seed_event,
                                tolerance=>0.0000000000000001,
                                hard_sanity_level=>0.0000001,
                                log_file_handle=>$logfh
                            );
    }
    else {
        $analysis = Math::StochasticProcess->new(
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

=head1 AUTHOR

Nicholas Bamber, C<< <theabbot at silasthemonk.org.uk> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-math-stochasticprocess-event-tuple at rt.cpan.org>, or through the web interface at
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

1; # End of Math::StochasticProcess::Event::Tuple
