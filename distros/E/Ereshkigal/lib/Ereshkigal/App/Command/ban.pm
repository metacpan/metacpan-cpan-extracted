package Ereshkigal::App::Command::ban;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::ban - Ban one or more IPs.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # ban on all kur instances
    ereshkigal ban 1.2.3.4 5.6.7.8

    # ban on just the kur instance sshd
    ereshkigal ban --kur sshd 1.2.3.4

    # an hour long ban
    ereshkigal ban --ban-time 3600 1.2.3.4

    # a permanent ban
    ereshkigal ban --ban-time 0 1.2.3.4

=head1 DESCRIPTION

Bans one or more IPs. Without C<--kur> every kur gets them, each blocking per
its own ports and protocols; with C<--kur> only that instance does, and
naming a fan_out gate sends them to every kur behind it.

Each IP is answered for separately, so one bad address does not spoil the
rest of the request, and re-banning something already banned just resets its
sentence rather than erroring.

C<--ban-time> is in seconds and overrides the kur's default for these bans
only, with 0 meaning never time out... nothing will release it but an
C<unban>. Both IPv4 and IPv6 are taken in any spelling, v6 being
canonicalized so long and short forms of one address cannot become two
bans. For whole ranges see L<cidr_ban|Ereshkigal::App::Command::cidr_ban>.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, opt_spec, validate_args, and execute.

=cut

sub abstract { return 'ban one or more IPs' }

sub description {
	return <<'DESCRIPTION';
Banish one or more IPs to the underworld.

Without --kur every kur gets them, which is usually what you want... each
one blocks per its own ports and protocols. With --kur only that instance
does, and naming a fan_out gate sends them to every kur behind it.

Each IP is answered for separately, so one bad address does not spoil the
rest of the request. Re-banning something already held just resets its
sentence rather than erroring.

--ban-time is in seconds and overrides the kur's default for these bans
only. A 0 means never time out, so nothing will release it but an unban.

  ereshkigal ban 1.2.3.4 5.6.7.8
  ereshkigal ban --kur sshd 1.2.3.4
  ereshkigal ban --ban-time 0 1.2.3.4        # until told otherwise

Both IPv4 and IPv6 are taken, in any spelling... a v6 address is
canonicalized, so long and short forms of one address cannot become two
separate bans. For a whole range use cidr-ban.
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c ban %o <IP> [<IP> ...]'; }

sub opt_spec {
	return (
		[ 'kur=s',      'kur instance to send the ban to, defaulting to all of them' ],
		[ 'ban-time=i', 'seconds the bans should last, 0 meaning never time out, defaulting to the kur default' ],
	);
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( !@{$args} ) {
		$self->usage_error('at least one IP must be specified');
	}
	if ( defined( $opt->ban_time ) && $opt->ban_time !~ /^[0-9]+$/ ) {
		$self->usage_error('--ban-time must be a non-negative integer of seconds');
	}

	return;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $ban_args = { 'ips' => $args };
	if ( defined( $opt->kur ) ) {
		$ban_args->{kur} = $opt->kur;
	}
	if ( defined( $opt->ban_time ) ) {
		$ban_args->{ban_time} = $opt->ban_time;
	}

	$self->run_command( 'ban', $ban_args );

	return;
} ## end sub execute

1;
