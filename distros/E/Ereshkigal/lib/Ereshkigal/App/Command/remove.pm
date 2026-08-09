package Ereshkigal::App::Command::remove;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::remove - Stop a kur instance and deregister it.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal remove sshd

=head1 DESCRIPTION

Stops the kur instance, tearing its firewall setup down and removing its
socket and PID files, and deregisters it from the running manager. Does not
rewrite the config file... to make it permanent, remove it from the config.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, validate_args, and execute.

=cut

sub abstract { return 'stop a kur instance and deregister it' }

sub description {
	return <<'DESCRIPTION';
Stop a kur instance and deregister it from the running manager.

The kur is asked to stop, which tears its firewall setup down on the way
out... the table, set, chain, or list it owns is removed, and with it
every ban it was holding. Those addresses stop being blocked the moment
this returns. The ban tablet is left on disk, so re-adding the same kur
later restores what it was carrying.

The config file is not rewritten, so a kur defined there returns at the
next manager start. To be rid of it for good, delete it from the config
as well.

A kur that is a member of a fan_out gate cannot be removed, as that would
leave the gate pointing at nothing... remove it from the gate first.
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c remove %o <kur>'; }

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} != 1 ) {
		$self->usage_error('a single kur instance name must be specified');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	$self->run_command( 'remove_kur', { 'name' => $args->[0] } );

	return;
}

1;
