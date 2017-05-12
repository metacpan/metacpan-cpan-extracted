package HPCD::SGE::DRMAAWrapper;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use Schedule::DRMAAc qw( :all );

use Moose::Role;

# most drmaa functions return (error,*other vals*, diagnosis)
#   the error and diagnosis need to be tested to check for failure
# we wrap these functions with code that throws an exception on failure
# and simpy returns the *other vals*

BEGIN {
    # If *other vals* is a single value, we provide scalar context to the result
    eval "sub O$_ { shift; dt1( $_( \@_ ) ) }"
    for qw(
        drmaa_allocate_job_template
        drmaa_run_job
        drmaa_get_attribute_names
        drmaa_get_attribute
        drmaa_wifexited
        drmaa_wexitstatus
        drmaa_wifaborted
        drmaa_wcoredump
        drmaa_wifsignaled
        drmaa_wtermsig
    );

    # If *other vals* is multiple values or void, we provide scalar context to the result
    eval "sub O$_ { shift; dt( $_( \@_ ) ) }"
    for qw(
        drmaa_set_attribute
        drmaa_set_vector_attribute
        drmaa_control
    );
};

# iterator functions return (error,value) where error is usually a flag to
# denote whether a value is being returned or the end of the iterator was
# reached (or some real error condition, like an invalid iterator)
# These we wrap with code that returns (continue, value) where continue is true
# if there is a value, or false if the iterator is empty; or it throws an
# exception on other types of error.
my @drmaa_iter = qw(
    drmaa_get_next_attr_name
    drmaa_get_next_attr_value
);

use Schedule::DRMAAc qw( :all );

######## DRMAA function wrappers
#  pretend that they are methods to get the convenience of the around wrapper
#  mechanism, but since they are actually functions, don't pass the $self arg
#
#  The DRMAA functions all return a list, the first element is an error indicator
#  which has the value $DRMAA_ERRNO_SUCCESS if all worked well and an error code
#  value otherwise, and the final list element is a diagnosis string.  In between
#  the real return value (or values) are also returned (but they are only meaningful
#  if there was no error.
#
#  The around wrappers below cause these to throw an exception if there was an error
#  and otherwise remove the excess return values.  There are two types - depending
#  upon whether the function, after removing the error baggage, returns one element
#  or multiple.  We make sure that the single element functions return in scalar
#  context now so that the calling looks sensible.

sub dt { # drmaa_trap for long - abort on errors or strip error baggage, return list
    my $error = shift;
    my $diagnosis = pop;
    confess "DRMAA error(" . drmaa_strerror($error) . "), diagnosis ($diagnosis)"
        if $error != $DRMAA_ERRNO_SUCCESS;
    return @_;
}

sub dt1 { # convert the list return from dt to a scalar
    (dt(@_))[0];
}

my $init_count;

before 'BUILD' => sub {
    dt( drmaa_init( undef ) ) unless $init_count++;
};

sub Odrmaa_wait {
    shift;
    my @ret = drmaa_wait( @_ );
    if ($ret[0] == $DRMAA_ERRNO_EXIT_TIMEOUT) {
        $ret[0] = $DRMAA_ERRNO_SUCCESS;
        $ret[1] = undef;
    }
	else {
		$ret[1] .= ': ** THIS IS USUALLY A TIMING ERROR IN THE DRMAA LIBRARY'
	            .  ' INTERACTION WITH SGE. TRY RE-RUNNING THE PROGRAM. IT'
				.  ' WILL USUALLY WORK CORRECTLY **'
			if defined $ret[1]
		       and $ret[1] =~ /no usage information was returned for the completed job$/;
    }
    dt( @ret );
}

sub Odrmaa_get_next_attr_value {
    shift;
    my( $continue, $value ) = drmaa_get_next_attr_value( @_ );
    return ( $continue == $DRMAA_ERRNO_SUCCESS, $value );
}

sub Odrmaa_get_next_attr_name {
    shift;
    my( $continue, $value ) = drmaa_get_next_attr_name( @_ );
    return ( $continue == $DRMAA_ERRNO_SUCCESS, $value );
}

1;
