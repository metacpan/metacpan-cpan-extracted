package Ereshkigal::App::Command::add;

use 5.006;
use strict;
use warnings;
use Ereshkigal::App -command;

=head1 NAME

Ereshkigal::App::Command::add - Define and start a new kur instance at runtime.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    ereshkigal add sshd --backend ipfw --ports 22 --protocols tcp
    ereshkigal add baphomet --fan-out sshd,smtp

=head1 DESCRIPTION

Defines and starts a new kur instance in the running manager. Does not
rewrite the config file... to make it permanent, add it to the config.

With C<--fan-out> in place of C<--backend> the new kur is a manager side
fan out kur... no process of its own, with commands targeted at it
fanning out to the listed member kurs.

=head1 METHODS

The App::Cmd hooks this subcommand supplies... abstract, description,
usage_desc, opt_spec, validate_args, and execute.

=cut

sub abstract { return 'define and start a new kur instance at runtime' }

sub description {
	return <<'DESCRIPTION';
Raise a new underworld in the running manager, now.

Defines a kur and starts it, building its firewall setup immediately. The
options mirror what the kur bin takes and are handed straight through.

With --fan-out in place of --backend the new kur is a gate instead: no
process and no firewall of its own, just a name that commands fan out
from to the kurs it lists. Handy as a single point of contact for an
integration, which can then be authorized for the gate alone rather than
each member. Gates cannot nest.

The config file is NOT rewritten. A kur added this way is gone at the next
manager start unless you also add it to the config yourself, which is
easy to forget after an incident.

Backend specific settings go via --option, repeated per setting. The one
exception is --interfaces, which some backends want as a list rather than
a single value.

  ereshkigal add dns --backend pf --ports 53 --protocols tcp,udp --option kill=1
  ereshkigal add edge --backend xdp --interfaces eth0,eth1 --enable-cidr 1
  ereshkigal add gate --fan-out sshd,smtp
DESCRIPTION
} ## end sub description

sub usage_desc { return '%c add %o <kur>'; }

sub opt_spec {
	return (
		[ 'backend=s',          'the Net::Firewall::BlockerHelper backend to use' ],
		[ 'fan-out=s',          'comma separated list of kurs to fan out to, in place of --backend' ],
		[ 'ports=s',            'comma separated list of ports to block' ],
		[ 'protocols=s',        'comma separated list of protocols to block' ],
		[ 'prefix=s',           'the prefix to use' ],
		[ 'option=s@',          'a backend specific option, key=value, may be given multiple times' ],
		[ 'interfaces=s',       'comma separated list of interfaces, handed over as the interfaces option array' ],
		[ 'self-heal=i',        'if the firewall setup should be checked and re-inited before each ban/unban' ],
		[ 'ban-time=i',         'seconds bans should last for this kur, 0 meaning never time out' ],
		[ 'checkpoint=i',       'seconds between ban state CSV rewrites for this kur' ],
		[ 'enable-cidr=s',      'if CIDR banning is enabled for this kur' ],
		[ 'cidr-silent-drop=s', 'if unavailable CIDR commands are silently dropped rather than errored' ],
	);
} ## end sub opt_spec

sub validate_args {
	my ( $self, $opt, $args ) = @_;

	if ( @{$args} != 1 ) {
		$self->usage_error('a single kur instance name must be specified');
	}
	if ( !defined( $opt->backend ) && !defined( $opt->fan_out ) ) {
		$self->usage_error('either --backend or --fan-out must be specified');
	}
	if ( defined( $opt->backend ) && defined( $opt->fan_out ) ) {
		$self->usage_error('--backend and --fan-out may not be used together');
	}

	return;
} ## end sub validate_args

sub execute {
	my ( $self, $opt, $args ) = @_;

	my $opts = {};

	if ( defined( $opt->backend ) ) {
		$opts->{backend} = $opt->backend;
	}
	if ( defined( $opt->fan_out ) ) {
		$opts->{fan_out} = $self->_split_comma_list( 'fan-out', $opt->fan_out );
	}
	if ( defined( $opt->ports ) ) {
		$opts->{ports} = $self->_split_comma_list( 'ports', $opt->ports );
	}
	if ( defined( $opt->protocols ) ) {
		$opts->{protocols} = $self->_split_comma_list( 'protocols', $opt->protocols );
	}
	if ( defined( $opt->prefix ) ) {
		$opts->{prefix} = $opt->prefix;
	}
	if ( defined( $opt->self_heal ) ) {
		$opts->{self_heal} = $opt->self_heal;
	}
	if ( defined( $opt->ban_time ) ) {
		$opts->{ban_time} = $opt->ban_time;
	}
	if ( defined( $opt->checkpoint ) ) {
		$opts->{checkpoint} = $opt->checkpoint;
	}
	if ( defined( $opt->option ) ) {
		my %backend_options;
		foreach my $key_value ( @{ $opt->option } ) {
			my ( $key, $value ) = split( /=/, $key_value, 2 );
			if ( !defined($value) ) {
				$self->usage_error( '--option "' . $key_value . '" is not in the form key=value' );
			}
			$backend_options{$key} = $value;
		}
		$opts->{options} = \%backend_options;
	} ## end if ( defined( $opt->option ) )
	if ( defined( $opt->interfaces ) ) {
		$opts->{options}{interfaces} = $self->_split_comma_list( 'interfaces', $opt->interfaces );
	}
	if ( defined( $opt->enable_cidr ) ) {
		$opts->{enable_cidr} = $opt->enable_cidr;
	}
	if ( defined( $opt->cidr_silent_drop ) ) {
		$opts->{cidr_silent_drop} = $opt->cidr_silent_drop;
	}

	$self->run_command( 'add_kur', { 'name' => $args->[0], 'opts' => $opts } );

	return;
} ## end sub execute

# Turns one of this command's comma separated option values into the array
# ref the manager expects for it. The kur bin takes --ports 22,80 and the
# like as a single string, but add_kur is a JSON request where ports is a
# array, so the splitting has to happen somewhere and it happens here.
# Shared by --fan-out, --ports, --protocols and --interfaces rather than
# each doing its own, so all four treat sloppy input the same way.
#
# The value is trimmed at both ends, split on commas with any surrounding
# whitespace eaten, and empty elements dropped, so ",22", "22, 23," and
# "22 , 23" all come out as clean lists. Nothing else is checked... whether
# 22 is a plausible port or eth0 a real interface is for the manager and the
# backend to say, not this.
#
# Args, both positional and required...
#
#     $option_name  :: The option's name without its leading dashes, as in
#                      'ports' or 'fan-out'. Used only to build the usage
#                      error, so it wants to be the dashed spelling the user
#                      actually typed rather than the underscored one the
#                      opt object carries.
#     $option_value :: The raw string as given on the command line. Must be
#                      defined... callers guard with a defined check on the
#                      opt accessor, and an undef reaching here warns and
#                      then behaves as the empty string, which is a usage
#                      error anyway.
#
# Returns an array ref of the elements, in the order given and with
# duplicates left alone... a caller wanting them deduped does that its
# self, and for ports the manager does it anyway.
#
# Does not return if the value yields nothing, as "" or "," would. That
# calls usage_error, which dies with the message and the usage screen, so
# --ports with an empty value is refused rather than quietly becoming a
# ports list of none.
#
#     my $ports = $self->_split_comma_list( 'ports', '22, 80,443' );
#     # [ '22', '80', '443' ]
#
#     my $members = $self->_split_comma_list( 'fan-out', ',sshd,,smtp,' );
#     # [ 'sshd', 'smtp' ]
sub _split_comma_list {
	my ( $self, $option_name, $option_value ) = @_;

	$option_value =~ s/^\s+//;
	$option_value =~ s/\s+$//;

	my @elements = grep { length } split( /\s*,\s*/, $option_value );
	if ( !@elements ) {
		$self->usage_error( '--' . $option_name . ' must contain at least one item' );
	}

	return \@elements;
} ## end sub _split_comma_list

1;
