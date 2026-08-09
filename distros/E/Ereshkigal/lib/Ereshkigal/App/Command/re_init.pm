package Ereshkigal::App::Command::re_init;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::re_init - Rebuild kur firewall setups from their ban books.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # every kur rebuilds
    ereshkigal re-init

    # just sshd
    ereshkigal re-init sshd

=head1 DESCRIPTION

Has each kur tear its firewall setup down and build it again from scratch,
re-banning everything its ban book carries. This is the repair for a setup
that something outside Ereshkigal has interfered with... a C<shorewall
restart> or C<pf -F all> that dropped the rules, a firewalld reload, an ipset
flushed by hand. It also settles unban debts, as tearing down takes any rule
a failed unban left behind with it.

Bans are not enforced during the rebuild. It is brief, but it is a real
window.

Mostly a convenience... with C<self_heal> on, which is the default, each kur
already checks its setup before every ban and unban and rebuilds it if it has
gone missing. This is for when that is wanted now rather than at the next
ban, or when C<self_heal> is off.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... command_names, abstract,
description, usage_desc, validate_args, and execute.

=cut

# accept both the dashed and underscored spellings
sub command_names { return ( 're-init', 're_init' ); }

sub abstract { return 'rebuild kur firewall setups from their ban books' }

sub description {
	return <<'DESCRIPTION';
Rebuild a kur's firewall setup from its ban book.

The kur tears its table, set, chain, or list down and builds it again from
scratch, then re-bans everything its book is carrying. The book is the
authority here, so the firewall ends up matching what Ereshkigal believes
it is holding.

This is the repair for a setup something outside Ereshkigal has interfered
with: a "shorewall restart" or "pf -F all" that dropped the rules, a
firewalld reload, an ipset someone flushed by hand. It also settles unban
debts, since tearing down takes any rule the kur failed to remove with it.

Bans are NOT enforced during the rebuild. It is brief, but it is a real
window, so prefer a quiet moment on a busy edge.

Most kurs will not need this. With self_heal on, which is the default, a
kur already checks its setup before every ban and unban and rebuilds it
if it has gone missing... this is the manual version, for when you want
it now rather than at the next ban, or when self_heal is off.

With no args every kur rebuilds; with a kur name only that one, and naming
a fan_out gate reaches every kur behind it.

  ereshkigal re-init                 # everything
  ereshkigal re-init sshd            # just that one
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c re-init %o [kur]'; }

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} > 1 ) {
		$self->usage_error('re-init takes at most one arg, a kur instance name');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	$self->run_command( 're_init', @{$args} ? { 'kur' => $args->[0] } : undef );

	return;
}

1;
