package Geo::Coder::Many::Scheduler::Selective;

use strict;
use warnings;
use Time::HiRes qw( gettimeofday );
use List::Util qw( min max );
use Carp;

use base 'Geo::Coder::Many::Scheduler';

our $VERSION = '0.01';

=head1 NAME 
    
Geo::Coder::Many::Scheduler::Selective - Scheduler that times out bad geocoders

=head1 DESCRIPTION

This scheduler wraps another scheduler, and provides facilities for disabling
various geocoders based on external feedback (e.g. limit exceeded messages)

In particular, if a geocoder returns an error, it is disabled for a timeout
period. This period increases exponentially upon each successive consecutive
failure.

=head1 METHODS

=head2 new

Constructs and returns an instance of the class.
Takes a reference to an array of {name, weight} hashrefs, and the name of a
scheduler class to wrap (e.g. Geo::Coder::Many::Scheduler::OrderedList)

=cut

sub new {
    my $class = shift;
    my $ra_geocoders = shift;
    my $scheduler = shift;

    unless (defined $scheduler) {
        croak "Selective scheduler needs to wrap an ordinary scheduler.\n";
    }
    
    my $self = { };
    $self->{ scheduler } = $scheduler->new( $ra_geocoders );
    $self->{ geocoder_meta } = { };

    # Length of first timeout in seconds
    $self->{ base_timeout } = 1; 

    # Timeout multiplies by this upon each successive failure
    $self->{ timeout_multiplier } = 1.5; 

    bless $self, $class;

    for my $rh_geocoder (@$ra_geocoders) {
        $self->_clear_timeout($rh_geocoder->{name});
    }


    return $self;
}

=head2 reset_available

Wrapper method - passes the reset on to the wrapped scheduler.

=cut

sub reset_available {
    my $self = shift;
    $self->{scheduler}->reset_available();
    return;
}

=head2 get_next_unique

Retrieves the next geocoder from the internal scheduler, but skipping over
it if it isn't acceptable (e.g. being timed out)

=cut

sub get_next_unique {
    my $self = shift;

    my $acceptable = 0;
    my $t = gettimeofday();
    my $geocoder;
    while (!$acceptable) {
        $geocoder = $self->{scheduler}->get_next_unique();
        if (!defined $geocoder || $geocoder eq '') {return;}
        my $rh_meta = $self->{geocoder_meta}->{$geocoder};
        if ($t >= $rh_meta->{timeout_end}) {
            $acceptable = 1;
        } 
    }
    return $geocoder;
}

=head2 next_available

Returns undef if there are no more geocoders that will become available.
Otherwise it returns the time remaining until the earliest timeout-end arrives.

=cut

sub next_available {
    my $self = shift;
    return if (!defined $self->{scheduler}->next_available());
    my $first_time = 
        min( 
            map { 
                $_->{timeout_end};
            } values %{$self->{geocoder_meta}} 
        ) - gettimeofday();
    return max 0, $first_time;
}

=head2 process_feedback

Recieves feedback about geocoders, and sets/clears timeouts appropriately.

=cut

sub process_feedback {
    my ($self, $geocoder, $rh_feedback) = @_;

    if ( $rh_feedback->{response_code} != 200 ) {
        $self->_increase_timeout($geocoder);
    } 
    else {
        $self->_clear_timeout($geocoder);
    }
    return;
}

=head1 INTERNAL METHODS

=head2 _increase_timeout

Increases the timeout for the specified geocoder, according to the base_timeout
and timeout_multiplier instance variables.

=cut

sub _increase_timeout {
    my ($self, $geocoder) = @_;
    my $rh_meta = $self->{geocoder_meta}->{$geocoder};
    $rh_meta->{timeout_count} += 1;
    my $timeout_count = $rh_meta->{timeout_count};

    my $base_timeout = $self->{base_timeout};
    my $timeout_multiplier = $self->{timeout_multiplier}; 

    my $timeout_length = 
        $base_timeout * ($timeout_multiplier ** $timeout_count);

    $rh_meta->{timeout_end} = gettimeofday() + $timeout_length;
    return $timeout_length;
};

=head2 _clear_timeout

Clears the timeout for the specified geocoder.

=cut

sub _clear_timeout {
    my ($self, $geocoder) = @_;
    $self->{geocoder_meta}->{$geocoder} = { 
        timeout_count => 0,
        timeout_end => 0
    };
    return;
};

1;

__END__
