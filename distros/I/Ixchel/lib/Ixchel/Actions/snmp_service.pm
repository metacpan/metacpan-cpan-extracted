package Ixchel::Actions::snmp_service;

use 5.006;
use strict;
use warnings;
use Rex::Commands::Gather;
use Rex::Commands::Service;
use base 'Ixchel::Actions::base';

# prevents Rex from printing out rex is exiting after the script ends
$::QUIET = 2;

=head1 NAME

Ixchel::Actions::snmp_service - Manage the snmpd service.

=head1 VERSION

Version 0.1.1

=cut

our $VERSION = '0.1.1';

=head1 CLI SYNOPSIS

ixchel -a snmp_service --enable [B<--start>|B<--stop>|B<--restart>|B<--stopstart>]

ixchel -a snmp_service --disable [B<--start>|B<--stop>|B<--restart>|B<--stopstart>]

ixchel -a snmp_service --start

ixchel -a snmp_service --stop

ixchel -a snmp_service --restart

ixchel -a snmp_service --stopstart

=head1 CODE SYNOPSIS

    use Data::Dumper;

    my $results=$ixchel->action(action=>'snmp_enable', opts=>{enable=>1,start=>1});

=head1 FLAGS

=head2 --enable

Enable the service.

My not be combined with --disable.

=head2 --disable

Disable the service.

My not be combined with --enable.

=head2 --start

Start the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --stop

Stop the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --restart

Restart the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head2 --stopstart

Stop and then restart the service.

May not be combined with.

    --start
    --stop
    --restart
    --stopstart

=head1 RESULT HASH REF

    .errors :: A array of errors encountered.
    .status_text :: A string description of what was done and the results.
    .ok :: Set to zero if any of the above errored.

=cut

sub new_extra { }

sub action_extra {
	my $self = $_[0];

	# make sure we don't have extra start/stop stuff specified
	my $extra_opts   = 0;
	my @various_opts = ( 'restart', 'start', 'stop', 'stopstart' );
	foreach my $item (@various_opts) {
		if ( defined( $self->{opts}{$item} ) ) {
			$extra_opts++;
		}
	}
	if ( $extra_opts > 1 ) {
		my $extra_opts_string = '--' . join( ', --', @various_opts );
		$self->status_add( error => 1, status => $extra_opts_string . ' can not be combined' );
		return undef;
	}

	# make sure --enable and --disable are not both specified
	if ( $self->{opts}{enable} && $self->{opts}{disable} ) {
		$self->status_add( error => 1, status => '--disable and --enable may not be specified at the same time' );
		return undef;
	}

	# enable/disable it
	if ( $self->{opts}{enable} ) {
		eval {
			service 'snmpd', ensure => 'started';
			$self->status_add( status => 'snmpd enabled' );
		};
		if ($@) {
			$self->status_add( status => 'Errored enabling snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{disable} ) {
		eval {
			service 'snmpd', ensure => 'stopped';
			$self->status_add( status => 'snmpd disabled' );
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored disabling snmpd... ' . $@ );
		}
	}

	# start/stop it etc
	if ( $self->{opts}{restart} ) {
		eval {
			service 'snmpd' => 'restart';
			$self->status_add( status => 'snmped restarted' );
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored restarting snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{start} ) {
		eval {
			service 'snmpd' => 'start';
			$self->status_add( status => 'snmped started' );
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored starting snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{stop} ) {
		eval {
			service 'snmpd' => 'stop';
			$self->status_add( status => 'snmped stopped' );
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored stopping snmpd... ' . $@ );
		}
	} elsif ( $self->{opts}{stopstart} ) {
		eval {
			service 'snmpd' => 'stop';
			$self->status_add( status => 'snmped stopped' );
			service 'snmpd' => 'start';
			$self->status_add( status => 'snmped started' );
		};
		if ($@) {
			$self->status_add( error => 1, status => 'Errored stopping and then starting snmpd... ' . $@ );
		}
	} ## end elsif ( $self->{opts}{stopstart} )

	return undef;
} ## end sub action_extra

sub short {
	return 'Manage the snmpd service.';
}

sub opts_data {
	return '
enable
disable
start
stop
restart
stopstart
';
} ## end sub opts_data

1;
