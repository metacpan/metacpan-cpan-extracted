package HPCD::uni::Stage;

### INCLUDES ##################################################################

# safe Perl
use warnings;
use strict;
use Carp;
use Data::Dumper;
use DateTime;

use Moose;
use Moose::Util::TypeConstraints;

use HPCD::uni::Run;

with qw(HPCI::Stage), HPCI::get_extra_roles('uni', 'stage');

sub _build_cluster_specific_valid_resources {
	return (
		h_time => undef,
		s_time => undef,
	)
}

=head1 NAME

    HPCD::uni::Stage

=head1 SYNOPSIS

This is a HPCD internal module, loaded by HPCD::uni::Group to
provide stage objects for uni clusters.

It consumes the HPCI::Stage role.

=cut

has '+runs' => (
    isa      => 'ArrayRef[HPCD::uni::Run]',
);

has '_run_class' => (
    is       => 'ro',
    isa      => 'Str',
    init_arg => undef,
    default  => "HPCD::uni::Run",
);

=head1 METHODS

=head2 _analyse_completion_state

Checks the completion info from when execution of this stage has
finished, and determine whether it:

- succeeded
- failed but can be retried (never for this driver)
- failed irrevocably

=cut

sub _analyse_completion_state {
	my $self  = shift;
	my $run   = shift;
	my $stats = $run->stats;
	$self->debug( "Stats from finished stage(" . $self->name . "): " . Dumper($stats) );
	my $new_state =
	    0 == $stats->{exit_status}
	    ? 'pass'
	    : 'fail';
	$self->_set_state($new_state);
}

sub _get_submit_timeouts {
	my $self  = shift;
	my $res   = $self->_use_resources_required;
	return
		$self->_time_to_secs( $res->{s_time} // 0 ),
		$self->_time_to_secs( $res->{h_time} // 0 );
}

=head1 AUTHOR

John Macdonald - Boutros Lab

=head1 ACKNOWLEDGEMENTS

Paul Boutros, Phd, PI - Boutros Lab

The Ontario Institute for Cancer Research

=cut

1;

