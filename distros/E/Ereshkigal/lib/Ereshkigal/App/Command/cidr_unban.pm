package Ereshkigal::App::Command::cidr_unban;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::cidr_unban - Unban a CIDR range.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # check every kur for the CIDR and unban it where present
    ereshkigal cidr-unban 1.2.3.0/24

=head1 DESCRIPTION

Every kur is asked whether it is holding the range and it is released from
each one that is. Host bits are masked off first, the same as when banning,
so naming any address inside a banned network finds it.

The range is released as a range. A range ban is one firewall entry
covering the whole prefix rather than one ban per address inside it, so
unbanning a single IP within a banned range will not punch a hole in
it... that address stays blocked as long as the range is.

There is no --all form... C<ereshkigal unban --all> already flushes CIDR bans
alongside single IP bans.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... command_names, abstract,
description, usage_desc, opt_spec, validate_args, and execute.

=cut

# accept both the dashed and underscored spellings
sub command_names { return ( 'cidr-unban', 'cidr_unban' ); }

sub abstract { return 'unban a CIDR range' }

sub description {
	return <<'DESCRIPTION';
Release a CIDR range from the underworld.

Every kur is asked whether it is holding the range and it is released from
each one that is. Host bits are masked off first, the same as when banning,
so naming any address inside a banned network finds it.

This releases the range as a range. A range ban is a single firewall entry
covering the whole prefix, not one ban per address in it, so unbanning an
individual IP inside a banned range will not punch a hole in it... that
address stays blocked as long as the range is.

To empty everything, ranges and single IPs alike, use "unban --all".

  ereshkigal cidr-unban 1.2.3.0/24
  ereshkigal cidr-unban 1.2.3.4/24     # same range, host bits masked off
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c cidr-unban %o <CIDR>'; }

sub opt_spec {
	return ();
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} != 1 ) {
		$self->usage_error('a single CIDR must be specified');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	$self->run_command( 'cidr_unban', { 'cidr' => $args->[0] } );

	return;
}

1;
