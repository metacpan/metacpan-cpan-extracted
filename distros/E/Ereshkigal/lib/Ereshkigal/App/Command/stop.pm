package Ereshkigal::App::Command::stop;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::stop - Stop all the kur instances and the manager.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal stop

=head1 DESCRIPTION

Stops every kur instance and then the manager. Each kur checkpoints its
tablets, tears its firewall setup down, and exits; the manager follows.

Tearing down removes the tables, sets, chains, and lists the kurs own, so
every ban stops being enforced... the host is unprotected by anything
Ereshkigal was doing until it is started again. The bans themselves are not
forgotten, the tablets being written before the teardown, so starting back up
re-bans everything whose sentence has not run out in the meantime.

This returns as soon as the shutdown has been requested rather than once it
has finished, which is why L<start|Ereshkigal::App::Command::start> waits for
the old PID file to clear before taking over.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, validate_args, and execute.

=cut

sub abstract { return 'stop all the kur instances and the manager' }

sub description {
	return <<'DESCRIPTION';
Stop every kur instance and then the manager.

Each kur checkpoints its tablets, tears its firewall setup down, and
exits; the manager follows. Tearing down removes the tables, sets,
chains, and lists the kurs own, so EVERY ban stops being enforced. The
host is unprotected by anything Ereshkigal was doing until it is started
again.

The bans themselves are not forgotten. The tablets are written before the
teardown, so starting back up re-bans everything whose sentence has not
run out in the meantime.

This returns as soon as the shutdown has been requested, not once it has
finished, which is why "start" waits for the old PID file to clear before
taking over.
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c stop %o'; }

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} ) {
		$self->usage_error('stop does not take any args');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	$self->run_command('stop');

	return;
}

1;
