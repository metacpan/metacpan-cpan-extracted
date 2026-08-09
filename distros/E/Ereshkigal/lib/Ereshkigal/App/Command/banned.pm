package Ereshkigal::App::Command::banned;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::banned - List banned IPs, grouped per kur.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal banned

=head1 DESCRIPTION

Lists who each kur is holding... the banned IPs as the firewall itself
reports them, an C<expires> map giving when each sentence runs out with 0
meaning never, and the same pair for range bans under C<banned_cidr> and
C<cidr_expires>.

Also listed, under C<unban_retries> and C<cidr_unban_retries>, is anything
whose unban failed at expiry and is still owed to the firewall, each with
when it was first and last tried, how many times, and when it is next due.
Those are entries the kur has released but the firewall has not, so they
appear in the banned list as well.
L<clear_retries|Ereshkigal::App::Command::clear_retries> forgets them.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, validate_args, and execute.

=cut

sub abstract { return 'list banned IPs, grouped per kur' }

sub description {
	return <<'DESCRIPTION';
List who each kur is holding.

Per kur: the banned IPs as the firewall itself reports them, an expires
map giving when each sentence runs out with 0 meaning never, and the same
pair for range bans under banned_cidr and cidr_expires.

Also listed, under unban_retries and cidr_unban_retries, is anything whose
unban failed at expiry and is still owed to the firewall... each with when
it was first tried, when it was last tried, how many times, and when it is
next due. Those are entries the kur has released but the firewall has not,
so they will still appear in the banned list as well. "clear-retries"
forgets them, with the caveats in its own help.
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c banned %o'; }

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} ) {
		$self->usage_error('banned does not take any args');
	}

	return;
}

sub execute {
	my ( $self, $opt, $args ) = @_;

	$self->run_command('banned');

	return;
}

1;
