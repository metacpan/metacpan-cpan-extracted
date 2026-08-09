package Ereshkigal::App::Command::status;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::status - Show status of the manager and kur instances.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal status
    ereshkigal status --all
    ereshkigal status sshd

=head1 DESCRIPTION

Shows what the manager and its kurs are up to. With no args it asks only the
manager, so it answers even when a kur is wedged... its PID and uptime, and
per kur whether it is running, its PID, and how many times it has been
restarted.

With C<--all> each running kur is asked for its own status too: ban counts
split into timed and permanent, the next expiry, whether CIDR banning is
enabled and whether the backend can actually do it, the checkpoint interval,
per instance stats, and how many unbans are still owed to the firewall along
with how long the longest has been outstanding.

With a kur name it is that one instance in full, and naming a fan_out gate
gives its member list plus each member's status. A kur that is running but
whose socket cannot be reached shows up with an C<error> rather than a
C<status> block.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, opt_spec, validate_args, and execute.

=cut

sub abstract { return 'show status of the manager and kur instances' }

sub description {
	return <<'DESCRIPTION';
Show what the manager and its kurs are up to.

With no args it asks only the manager, so it answers even when a kur is
wedged... its PID and uptime, and for each kur whether it is running,
its PID, and how many times it has been restarted.

With --all each running kur is asked for its own status too: ban counts
split into timed and permanent, the next expiry, whether CIDR banning is
enabled and whether the backend can actually do it, the checkpoint
interval, per instance stats, and how many unbans are still owed to the
firewall along with how long the longest has been outstanding.

With a kur name it is that one instance in full. Naming a fan_out gate
gives its member list plus each member's status.

A kur that is running but whose socket cannot be reached shows up with an
error rather than a status block, which is the shape to look for when
something has gone quiet.

  ereshkigal status               # the cheap overview
  ereshkigal status --all         # everything, asks every kur
  ereshkigal status sshd          # just that one
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c status %o [kur]'; }

sub opt_spec {
	return ( [ 'all', 'include the full status of every kur instance' ], );
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} > 1 ) {
		$self->usage_error('status takes at most one arg, a kur instance name');
	}
	if ( @{$args} && $opt->all ) {
		$self->usage_error('--all and a kur instance name may not be used together');
	}

	return;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} ) {
		$self->run_command( 'status_kur', { 'name' => $args->[0] } );
	} elsif ( $opt->all ) {
		$self->run_command('status_all');
	} else {
		$self->run_command('status');
	}

	return;
} ## end sub execute

1;
