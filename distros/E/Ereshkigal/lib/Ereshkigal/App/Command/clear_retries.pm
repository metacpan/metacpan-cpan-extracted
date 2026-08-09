package Ereshkigal::App::Command::clear_retries;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::clear_retries - Forget unbans still owed to the firewall.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    # forget every owed unban, on every kur
    ereshkigal clear-retries

    # just the ones sshd is carrying
    ereshkigal clear-retries sshd

    # just this one IP, everywhere
    ereshkigal clear-retries --ip 1.2.3.4

    # and a range, on the one kur
    ereshkigal clear-retries blocklist --cidr 1.2.3.0/24

=head1 DESCRIPTION

When a ban's sentence runs out but the backend refuses the unban, the kur
still drops it from the ban book and hands the firewall side to a retry that
backs off until it lands. Those owed unbans show up under C<unban_retries> in
the output of L<banned|Ereshkigal::App::Command::banned> and are counted by
L<status|Ereshkigal::App::Command::status>.

This forgets them. It is the escape hatch for one that will never land, the
rule having been removed by hand or the backend having never had it to begin
with. Nothing is asked of the firewall, so anything genuinely still banished
there stays banished... this only stops the kur from asking.

Which is the thing to be careful of. If the rule really is still in place,
forgetting it leaves that address blocked indefinitely with nothing tracking
it... it will not appear in C<banned> and no expiry will ever release it. So
check C<banned> first, and where the backend is healthy again prefer a plain
C<unban>, which asks the firewall to remove the rule for real and settles the
debt when it does.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... command_names, abstract,
description, usage_desc, opt_spec, validate_args, and execute.

=cut

# accept both the dashed and underscored spellings
sub command_names { return ( 'clear-retries', 'clear_retries' ); }

sub abstract { return 'forget unbans still owed to the firewall' }

sub description {
	return <<'DESCRIPTION';
Forget unbans that are still owed to the firewall.

When a ban's sentence runs out but the backend refuses the unban, the kur
drops it from the ban book and keeps owing the firewall the removal,
retrying with a backoff until it lands. Those debts survive a restart.
"status --all" counts them per kur and "banned" names each one, with how
many times it has been tried and when it is next due.

This forgets them. With no args every kur forgets every debt it carries; a
kur name scopes it to that one; --ip or --cidr, at most one of the two,
forgets a single entry.

BEWARE: nothing is sent to the firewall, this only stops the kur asking.
If the rule really is still in place, forgetting it leaves it there with
nothing tracking it, blocking that address indefinitely and no record
anywhere of why. This is for a debt that can never be paid because the
rule is already gone... removed by hand, or on a backend that never
carried it.

So check "banned" first. If the backend is healthy again, an ordinary
"ereshkigal unban <IP>" is the honest way out: it asks the firewall to
remove the rule for real, and settles the debt when it does.

  ereshkigal clear-retries                        # every debt, every kur
  ereshkigal clear-retries sshd                   # just that kur's
  ereshkigal clear-retries --ip 1.2.3.4           # that one, everywhere
  ereshkigal clear-retries blocklist --cidr 1.2.3.0/24
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c clear-retries %o [kur]'; }

sub opt_spec {
	return (
		[ 'ip=s',   'forget the owed unban of just this IP' ],
		[ 'cidr=s', 'forget the owed unban of just this CIDR range' ],
	);
}

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} > 1 ) {
		$self->usage_error('clear-retries takes at most one arg, a kur instance name');
	}
	if ( defined( $opt->ip ) && defined( $opt->cidr ) ) {
		$self->usage_error('--ip and --cidr may not be used together');
	}

	return;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $command_args = {};
	if ( @{$args} ) {
		$command_args->{kur} = $args->[0];
	}
	if ( defined( $opt->ip ) ) {
		$command_args->{ip} = $opt->ip;
	}
	if ( defined( $opt->cidr ) ) {
		$command_args->{cidr} = $opt->cidr;
	}

	$self->run_command( 'clear_retries', %{$command_args} ? $command_args : undef );

	return;
} ## end sub execute

1;
