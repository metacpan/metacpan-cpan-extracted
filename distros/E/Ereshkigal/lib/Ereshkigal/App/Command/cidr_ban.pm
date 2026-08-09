package Ereshkigal::App::Command::cidr_ban;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::cidr_ban - Ban one or more CIDR ranges.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # ban on all kur instances
    ereshkigal cidr-ban 1.2.3.0/24 10.0.0.0/8

    # ban on just the kur instance sshd
    ereshkigal cidr-ban --kur sshd 1.2.3.0/24

    # an hour long ban
    ereshkigal cidr-ban --ban-time 3600 1.2.3.0/24

    # a permanent ban
    ereshkigal cidr-ban --ban-time 0 1.2.3.0/24

=head1 DESCRIPTION

Bans one or more CIDR ranges. The range form of
L<ban|Ereshkigal::App::Command::ban>, behaving the same way... every kur
unless C<--kur> names one, each range answered for separately, re-banning
resetting the sentence, and C<--ban-time> in seconds with 0 meaning never.

Host bits are masked off, so C<1.2.3.4/24> is taken as C<1.2.3.0/24> and
the two cannot become separate bans.

Only works on a kur whose backend supports CIDR bans and which has CIDR
banning enabled. A kur that cannot or will not do CIDR either drops the
command or reports an error per its cidr_silent_drop setting.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... command_names, abstract,
description, usage_desc, opt_spec, validate_args, and execute.

=cut

# accept both the dashed and underscored spellings
sub command_names { return ( 'cidr-ban', 'cidr_ban' ); }

sub abstract { return 'ban one or more CIDR ranges' }

sub description {
	return <<'DESCRIPTION';
Banish one or more CIDR ranges to the underworld.

The range form of "ban", behaving the same way... every kur unless --kur
names one, each range answered for separately, re-banning resets the
sentence, and --ban-time in seconds with 0 meaning never.

Host bits are masked off, so 1.2.3.4/24 is taken as 1.2.3.0/24 and the
two cannot become separate bans.

This only works where the operator has turned CIDR banning on, via
enable_cidr, AND the backend can match on a prefix... several cannot.
A kur that cannot oblige either refuses or quietly ignores the request
per its cidr_silent_drop setting, which is what lets one command be fanned
across a mixed set of kurs. "status --all" reports cidr_enabled and
cidr_supported per kur if you are unsure which is which.

  ereshkigal cidr-ban 1.2.3.0/24
  ereshkigal cidr-ban --kur blocklist --ban-time 0 2001:db8::/32
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c cidr-ban %o <CIDR> [<CIDR> ...]'; }

sub opt_spec {
	return (
		[ 'kur=s',      'kur instance to send the ban to, defaulting to all of them' ],
		[ 'ban-time=i', 'seconds the bans should last, 0 meaning never time out, defaulting to the kur default' ],
	);
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( !@{$args} ) {
		$self->usage_error('at least one CIDR must be specified');
	}
	if ( defined( $opt->ban_time ) && $opt->ban_time !~ /^[0-9]+$/ ) {
		$self->usage_error('--ban-time must be a non-negative integer of seconds');
	}

	return;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $ban_args = { 'cidrs' => $args };
	if ( defined( $opt->kur ) ) {
		$ban_args->{kur} = $opt->kur;
	}
	if ( defined( $opt->ban_time ) ) {
		$ban_args->{ban_time} = $opt->ban_time;
	}

	$self->run_command( 'cidr_ban', $ban_args );

	return;
} ## end sub execute

1;
