package Ereshkigal::App::Command;

use 5.006;
use strict;
use warnings;
use parent 'App::Cmd::Command';
use Ereshkigal::Client ();
use JSON::MaybeXS      ();

=head1 NAME

Ereshkigal::App::Command - Base class for the ereshkigal subcommands.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 DESCRIPTION

Base class for the Ereshkigal::App::Command modules, providing the shared
talk-to-the-manager plumbing.

Commands going through run_command exit with...

    0 - clean success
    1 - transport or server error, printed to STDERR
    2 - the command completed, but the result carries per-kur,
        per-IP, or per-CIDR failures

=head1 METHODS

=head2 client

Returns a new L<Ereshkigal::Client> for the socket named by the global
--socket option.

    my $client = $self->client;

=cut

sub client {
	my ($self) = @_;

	return Ereshkigal::Client->new( 'socket' => $self->app->global_options->{socket} );
}

=head2 run_command

Sends the command to the manager and prints the result to STDOUT as pretty
JSON, exiting per the codes above.

    $self->run_command( $command, $command_args );

=cut

sub run_command {
	my ( $self, $command, $command_args ) = @_;

	my $result;
	eval { $result = $self->client->call_ok( $command, defined($command_args) ? $command_args : () ); };
	if ($@) {
		my $error = $@;
		$error =~ s/\n*$//;
		print STDERR $error . "\n";
		exit 1;
	}

	print JSON::MaybeXS->new( 'pretty' => 1, 'canonical' => 1 )->encode($result);

	if ( _result_has_failures($result) ) {
		exit 2;
	}

	return;
} ## end sub run_command

# Decides whether a result that came back ok at the protocol level is
# nonetheless carrying failures inside it, which is what run_command turns
# into the exit 2 documented above. A ban fanned out to five kurs can
# succeed as a request while failing on two of them, and a script driving
# the CLI wants to know that without parsing the JSON... this is what lets
# the exit code say so. Called as a plain function rather than a method, as
# it needs nothing from the invocant.
#
# Three kinds of failure marker are looked for, and any one of them is
# enough... a non empty rejected hash, a kur carrying an error, or a per
# entry status of error. Both result shapes are handled, the manager's
# fanned out one with everything under kurs and the single kur one with
# ips/cidrs at the top level, that second being what comes back when -s is
# pointed straight at a kur socket.
#
# Args, one, positional and required...
#
#     $result :: Whatever call_ok returned, which is the result value of the
#                server's response. Normally a hash ref, but anything else,
#                undef and array refs included, is answered 0 rather than
#                dying, as plenty of commands answer with a shape carrying
#                no per item status at all. The keys looked at, all
#                optional, are 'rejected', a hash ref keyed by the raw entry
#                the manager refused to validate, which being non empty
#                means something was bounced before it ever reached a kur;
#                'kurs', a hash ref of kur name to that kur's own result,
#                where a value carrying a 'error' key is a kur that could
#                not be reached or refused the command; and 'ips' and
#                'cidrs', hash refs of entry to a hash ref carrying a
#                'status' of 'ok' or 'error', looked for both at the top
#                level and inside each value of kurs.
#
# Returns 1 if any failure marker was found and 0 otherwise, nothing more...
# it does not say which failed or how many, only whether the exit code
# should be 2. Never dies, whatever it is handed.
#
#     exit 2 if _result_has_failures($result);
#
#     # a fanned out ban where one kur is down
#     _result_has_failures(
#         {
#             'kurs' => {
#                 'sshd' => { 'ips' => { '1.2.3.4' => { 'status' => 'ok' } } },
#                 'smtp' => { 'error' => 'not running' },
#             }
#         }
#     );
#     # 1, for the smtp error
#
#     # an IP the manager would not validate
#     _result_has_failures(
#         { 'rejected' => { 'nope' => { 'status' => 'error' } } }
#     );
#     # 1
sub _result_has_failures {
	my ($result) = @_;

	return 0 if ref($result) ne 'HASH';

	if ( ref( $result->{rejected} ) eq 'HASH' && %{ $result->{rejected} } ) {
		return 1;
	}

	my @to_scan = ($result);
	if ( ref( $result->{kurs} ) eq 'HASH' ) {
		foreach my $kur_result ( values( %{ $result->{kurs} } ) ) {
			next     if ref($kur_result) ne 'HASH';
			return 1 if defined( $kur_result->{error} );
			push( @to_scan, $kur_result );
		}
	}

	foreach my $to_scan (@to_scan) {
		foreach my $entries_key ( 'ips', 'cidrs' ) {
			next if ref( $to_scan->{$entries_key} ) ne 'HASH';
			foreach my $entry ( values( %{ $to_scan->{$entries_key} } ) ) {
				if ( ref($entry) eq 'HASH' && defined( $entry->{status} ) && $entry->{status} eq 'error' ) {
					return 1;
				}
			}
		}
	} ## end foreach my $to_scan (@to_scan)

	return 0;
} ## end sub _result_has_failures

# Overrides the App::Cmd::Command hook of the same name so every subcommand
# gains a --help/-h flag. App::Cmd wires up a help command but no such flag,
# so without this each subcommand answers "Unknown option: help" to the
# first thing most people reach for. Doing it here means the thirteen
# subcommands do not each have to remember to put it in their own opt_spec,
# and cannot drift from one another over it.
#
# The parent returns the usage_desc string followed by the opt_spec entries,
# which App::Cmd hands to _process_args and on to
# Getopt::Long::Descriptive. This returns that same list with one more
# option spec appended.
#
# Args, one, a list, forwarded verbatim...
#
#     @args :: Whatever App::Cmd is passing through for this subcommand, in
#              practice the Ereshkigal::App instance and nothing else. It is
#              handed on unexamined to usage_desc and opt_spec, both called
#              as class methods, so anything those accept is acceptable
#              here.
#
# Returns a list, not a ref... the usage_desc string first, then each
# opt_spec entry as its own array ref of [ spec, description ] or
# [ spec, description, \%opts ], then [ 'help|h', 'show this help and
# exit' ] last. Last so it renders at the bottom of the options listing,
# under the subcommand's own options, rather than in amongst them.
#
#     my @params
#         = Ereshkigal::App::Command::ban->_option_processing_params($app);
#     # ( '%c ban %o <IP> [<IP> ...]',
#     #   [ 'kur=s', 'kur instance to send the ban to, ...' ],
#     #   [ 'ban-time=i', 'seconds the bans should last, ...' ],
#     #   [ 'help|h', 'show this help and exit' ] )
sub _option_processing_params {
	my ( $class, @args ) = @_;

	return ( $class->usage_desc(@args), $class->opt_spec(@args), [ 'help|h', 'show this help and exit' ] );
}

# Overrides the App::Cmd::Command hook that turns a command line into a
# constructed command object, so the --help added by
# _option_processing_params actually does something. Handled here rather
# than in each subcommand's validate_args because prepare runs first...
# "ban --help" should explain ban, not refuse for want of an IP, and it only
# behaves that way because the help is answered before validate_args ever
# sees the empty arg list. It is public rather than underscored only
# because App::Cmd names the hook, and it carries no POD for the same
# reason its siblings do not... it is a framework callback, not an API
# anyone here calls.
#
# The parent is left to do all the real work, parsing the options and
# building the object. All this adds is the check afterwards.
#
# Args, both positional and required, both forwarded to the parent
# untouched...
#
#     $app   :: The Ereshkigal::App instance the subcommand is running
#               under, which the parent stores on the constructed object so
#               things like global_options can be reached from it.
#     @args  :: The rest of the command line for this subcommand, options
#               and positionals both, still unparsed. The parent hands it to
#               Getopt::Long::Descriptive, so an unknown option in here is
#               what dies with "Unknown option".
#
# Returns the parent's three part list unchanged... the constructed
# subcommand object, the Getopt::Long::Descriptive opts object, and then the
# leftover positional args as a plain list. App::Cmd feeds those straight
# into validate_args and execute.
#
# Or does not return at all. If --help or -h was given it prints the help
# screen to STDOUT and exits 0, so nothing downstream runs... no
# validate_args, no execute, and no connection to the manager.
#
#     my ( $cmd, $opt, @args )
#         = $class->prepare( $app, '--kur', 'sshd', '1.2.3.4' );
#     # $cmd is an Ereshkigal::App::Command::ban, $opt->kur is 'sshd',
#     # and @args is ( '1.2.3.4' )
#
#     $class->prepare( $app, '--help' );
#     # prints the help screen and exits 0, never returning
sub prepare {
	my ( $class, $app, @args ) = @_;

	my ( $self, $opt, @rest ) = $class->SUPER::prepare( $app, @args );

	if ( $opt->{help} ) {
		print $self->_help_text;
		exit 0;
	}

	return ( $self, $opt, @rest );
} ## end sub prepare

# Renders the help screen prepare prints for --help, assembled the same way
# and out of the same three pieces App::Cmd's own help command assembles
# its own. That sameness is the whole point... "ereshkigal help ban" and
# "ereshkigal ban --help" have to agree, and they only reliably do so by
# being built identically rather than by two bits of code being kept in step
# by hand.
#
# The three pieces are the usage leader line, the subcommand's description,
# and the option listing, joined with newlines. The description gets a
# leading newline of its own so it sits in a paragraph of its own under
# the usage line, but only when there is one... a subcommand with an empty
# description gets no stray blank line for it.
#
# Takes no arguments beyond the invocant, which must be a constructed
# subcommand object rather than a class... it reads description off it and
# needs the usage object the parent's prepare stored on it, so calling this
# on a class name dies for want of that.
#
# Returns the whole screen as one string, newline terminated and ready to
# hand straight to print. Nothing is written anywhere from here... printing
# is prepare's business.
#
#     print $self->_help_text;
#     # ereshkigal ban [-h] [long options...] <IP> [<IP> ...]
#     #
#     # Banish one or more IPs to the underworld.
#     # ...
#     #     --kur STR       kur instance to send the ban to, ...
#     #     --help (or -h)  show this help and exit
sub _help_text {
	my ($self) = @_;

	my $description = $self->description;
	$description = "\n" . $description if ( length($description) );

	return join( "\n", $self->usage->leader_text, $description, $self->usage->option_text ) . "\n";
}

1;
