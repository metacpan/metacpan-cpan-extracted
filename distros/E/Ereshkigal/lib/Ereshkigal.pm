package Ereshkigal;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use FindBin                          ();
use POE                              qw( Wheel::Run );
use POE::Component::Server::JSONUnix ();
use TOML::Tiny                       qw( from_toml );
use Ereshkigal::Client               ();
use Ereshkigal::IP                   qw( normalize_ip normalize_cidr );
use Ereshkigal::LogDrek              qw( log_drek );

=head1 NAME

Ereshkigal - Handle firewall or similar bans.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ereshkigal;

    my $ereshkigal = Ereshkigal->new( config => '/usr/local/etc/ereshkigal.toml' );

    $ereshkigal->start_server;

Ereshkigal is a ban manager for firewalls. It wrangles various
L<Ereshkigal::Kur> instances, spawned via the C<kur> bin, each of which runs
as its own process and uses L<Net::Firewall::BlockerHelper> for talking to
the firewall.

The manager listens on a unix socket, by default
C</var/run/ereshkigal/socket>, speaking the newline delimited JSON protocol
of L<POE::Component::Server::JSONUnix>, and proxies per instance work to the
kur sockets under C</var/run/ereshkigal/kur/>.

=head1 CONFIG FILE

The config file is TOML. Hashes under C<kur> define instances. The instance
name is the hash name, so the hash at C<kur.sshd> is the kur instance
C<sshd>. Keys inside are what kur/L<Net::Firewall::BlockerHelper> take...
C<backend>, C<ports>, C<protocols>, C<prefix>, C<self_heal>, and the backend
specific C<options> table.

Values in the C<options> table must be plain scalars, with one exception...
C<interfaces>, which backends such as xdp want as an array, may be given as
one. Any other array or table valued option is refused at config load rather
than being handed to the backend as a stringified ref.

Top level keys are manager settings.

    - socket_group :: Group ownership of the manager socket.
        Default :: the default group of the root user

    - socket_mode :: Perms for the manager socket. Processed via oct, so
          should be specified as a string such as "0660". Kur sockets are
          always 0600 and not configurable.
        Default :: 0660

    - run_base_dir :: Base dir for run files.
        Default :: /var/run/ereshkigal

    - cache_base_dir :: Base dir for cache files, passed to kur.
        Default :: /var/cache/ereshkigal

    - kur_bin :: The kur bin to spawn instances with.
        Default :: kur

    - timeout :: Timeout in seconds used when talking to kur sockets. For
          commands touching multiple kurs this bounds the whole fan out
          rather than each kur individually.
        Default :: 30

    - ban_time :: How long bans should last in seconds. 0 means bans never
          time out. May be overridden per kur via ban_time in its hash and
          per ban request.
        Default :: 600

    - checkpoint :: Seconds between periodic rewrites of each kur's ban
          state CSV. 0 disables the periodic rewrite... ban/unban, stop,
          and on demand checkpoints still happen. May be overridden per kur
          via checkpoint in its hash.
        Default :: 60

    - enable_cidr :: Whether CIDR banning is enabled. May be overridden per
          kur via enable_cidr in its hash. Even when set, the cidr_ban and
          cidr_unban commands only work on a kur whose backend supports CIDR
          bans.
        Default :: false

    - cidr_silent_drop :: How a kur handles a CIDR command when CIDR banning
          is not available for it, either because enable_cidr is off or the
          backend cannot do CIDR. When set such a kur silently drops the
          command rather than erroring, which keeps a fan out across a mix of
          CIDR capable and incapable kurs from being spoiled by the incapable
          ones. May be overridden per kur via cidr_silent_drop in its hash.
        Default :: false

    - enable_auth :: Enables the L<POE::Component::Server::JSONUnix>
          auth_required cookie file ownership challenge on the manager
          socket, along with authorization via authed_users/authed_groups.
        Default :: 0

    - authed_users :: An array of users with global access.
        Default :: []

    - authed_groups :: An array of groups with global access.
        Default :: []

    - auth_temp_dir :: Dir used for the ownership challenge cookie files,
          passed through to L<POE::Component::Server::JSONUnix>.
        Default :: undef

A kur hash may instead carry C<fan_out>, an array of other kur names, in
place of C<backend>. Such a kur is manager side only... no process and no
socket of its own. Commands targeted at it (C<ban> and C<cidr_ban> with
args.kur, C<checkpoint>, C<re_init>, and C<clear_retries> with args.kur,
and C<status_kur>) fan out to its members instead, making it usable as a
single point of contact for driving a whole set of kurs. With enable_auth
on, authorization for a command targeted at a fan_out kur is checked
against the fan_out kur's own lists rather than its members', so an
integration may be granted just the gate without being listed on any
member. Members must be defined non fan_out kurs... fan_out kurs may not
nest. Untargeted commands (C<ban> and C<cidr_ban> without args.kur,
C<unban>, C<cidr_unban>, C<banned>, and C<checkpoint>, C<re_init>, and
C<clear_retries> without args.kur) touch only real kurs, never fan_out
ones.

    [kur.baphomet]
    fan_out      = [ "sshd", "smtp" ]
    authed_users = [ "baphomet" ]

Each kur hash may also carry its own C<authed_users>/C<authed_groups>,
which expand upon the global ones for that kur... the effective lists for
a kur are the global ones plus its own. A command must be authorized for
every kur it touches, with untargeted fan-out commands touching every kur,
while commands about the manager itself (stop, add_kur, remove_kur, and
the whole manager views status/status_all) require the global lists. UID 0
is always authorized. The kur backends do no checking at all... their
sockets are 0600 and only ereshkigal is expected to be able to write to
them, so enforcement is entirely the manager's responsibility.

A refused command comes back as a normal JSONUnix error response carrying
a machine-readable C<code>, C<permission_denied> for an authorization
refusal, matching the C<code> field convention of
L<POE::Component::Server::JSONUnix>'s own permission and auth errors, so a
consumer may branch on the code rather than matching the message text.

Example...

    socket_group = "wheel"
    socket_mode  = "0660"

    [kur.sshd]
    backend   = "ipfw"
    ports     = [ "22" ]
    protocols = [ "tcp" ]

=head1 METHODS

=head2 new

Initiates the object. All errors are considered fatal, meaning if new fails
it will die.

    - config :: Path to the TOML config file.
        Default :: /usr/local/etc/ereshkigal.toml

=cut

sub new {
	my ( $blank, %opts ) = @_;

	my $self = {
		perror        => undef,
		error         => undef,
		errorLine     => undef,
		errorFilename => undef,
		errorString   => "",
		errorExtra    => {
			all_errors_fatal => 1,
			all_fatal        => 1,
			flags            => {
				1 => 'configReadFailed',
				2 => 'configParseFailed',
				3 => 'invalidKurDef',
				4 => 'runBaseDirError',
				5 => 'badSocketGroup',
				6 => 'invalidBanTime',
				7 => 'invalidCheckpoint',
				8 => 'invalidAuthedList',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		config           => '/usr/local/etc/ereshkigal.toml',
		run_base_dir     => '/var/run/ereshkigal',
		cache_base_dir   => '/var/cache/ereshkigal',
		kur_bin          => 'kur',
		timeout          => 30,
		ban_time         => 600,
		checkpoint       => 60,
		enable_cidr      => 0,
		cidr_silent_drop => 0,
		enable_auth      => 0,
		authed_users     => [],
		authed_groups    => [],
		auth_temp_dir    => undef,
		socket_group     => undef,
		socket_mode      => oct('0660'),
		kurs             => {},
		wheel_to_kur     => {},
		pid_to_kur       => {},
		shutting_down    => 0,
		started          => undef,
		server           => undef,
	};
	bless $self;

	if ( defined( $opts{config} ) ) {
		$self->{config} = $opts{config};
	}

	my $raw_config;
	{
		local $/ = undef;
		my $fh;
		if ( !open( $fh, '<', $self->{config} ) ) {
			$self->{perror}      = 1;
			$self->{error}       = 1;
			$self->{errorString} = 'Failed to open the config, "' . $self->{config} . '"... ' . $!;
			$self->warn;
		}
		$raw_config = <$fh>;
		close($fh);
	}

	my ( $config, $parse_error ) = from_toml($raw_config);
	if ( !defined($config) || ref($config) ne 'HASH' ) {
		$self->{perror} = 1;
		$self->{error}  = 2;
		$self->{errorString}
			= 'Failed to parse the config, "'
			. $self->{config} . '"... '
			. ( defined($parse_error) ? $parse_error : 'parsing did not return a hash' );
		$self->warn;
	}

	my @settings_to_merge = (
		'run_base_dir', 'cache_base_dir', 'kur_bin',     'timeout',
		'ban_time',     'checkpoint',     'enable_cidr', 'cidr_silent_drop',
		'enable_auth',  'auth_temp_dir',  'socket_group'
	);
	foreach my $item (@settings_to_merge) {
		if ( defined( $config->{$item} ) ) {
			$self->{$item} = $config->{$item};
		}
	}
	if ( defined( $config->{socket_mode} ) ) {
		# vetted before oct is trusted with it, as oct hands back 0 for
		# anything unparseable, which would leave the socket unusable by
		# everyone rather than erroring
		if ( '' . $config->{socket_mode} !~ /^0[0-7]{1,4}$/ ) {
			$self->{perror} = 1;
			$self->{error}  = 2;
			$self->{errorString}
				= 'socket_mode, "' . $config->{socket_mode} . '", is not an octal mode string such as "0660"';
			$self->warn;
		}
		$self->{socket_mode} = oct( '' . $config->{socket_mode} );
	} ## end if ( defined( $config->{socket_mode} ) )

	# A bare kur_bin (no path separator) is resolved against the directory
	# ereshkigal was invoked from, since kur is installed alongside it. This
	# avoids relying on $PATH, which is stripped down under service managers
	# such as FreeBSD's rc.subr (no /usr/local/bin) and would otherwise make
	# exec of the kur bin fail with "No such file or directory".
	if ( $self->{kur_bin} !~ m{/} ) {
		my $sibling = $FindBin::RealBin . '/' . $self->{kur_bin};
		if ( -x $sibling ) {
			$self->{kur_bin} = $sibling;
		}
	}

	if ( $self->{ban_time} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 6;
		$self->{errorString} = 'ban_time, "' . $self->{ban_time} . '", is not a non-negative int of seconds';
		$self->warn;
	}

	if ( $self->{checkpoint} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'checkpoint, "' . $self->{checkpoint} . '", is not a non-negative int of seconds';
		$self->warn;
	}

	foreach my $item ( 'authed_users', 'authed_groups' ) {
		if ( defined( $config->{$item} ) ) {
			my $list_error = _authed_list_error( $config->{$item} );
			if ( defined($list_error) ) {
				$self->{perror}      = 1;
				$self->{error}       = 8;
				$self->{errorString} = $item . ' is ' . $list_error;
				$self->warn;
			}
			$self->{$item} = $config->{$item};
		} ## end if ( defined( $config->{$item} ) )
	} ## end foreach my $item ( 'authed_users', 'authed_groups')

	# default to the default group of the root user... wheel on the BSDs, root on Linux
	if ( !defined( $self->{socket_group} ) ) {
		$self->{socket_gid} = ( getpwnam('root') )[3];
	} else {
		$self->{socket_gid} = getgrnam( $self->{socket_group} );
	}
	if ( !defined( $self->{socket_gid} ) ) {
		$self->{perror} = 1;
		$self->{error}  = 5;
		$self->{errorString}
			= 'Failed to resolve the socket group'
			. ( defined( $self->{socket_group} ) ? ', "' . $self->{socket_group} . '",' : ' for the root user' )
			. ' to a GID';
		$self->warn;
	}

	if ( defined( $config->{kur} ) && ref( $config->{kur} ) ne 'HASH' ) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'kur in the config is defined but not a hash';
		$self->warn;
	}
	if ( defined( $config->{kur} ) ) {
		foreach my $name ( keys( %{ $config->{kur} } ) ) {
			my $def = $config->{kur}{$name};
			$self->_check_kur_def( $name, $def, 1 );
			$self->{kurs}{$name} = {
				'opts'     => $def,
				'wheel'    => undef,
				'pid'      => undef,
				'restarts' => 0,
				'delay'    => 1,
				'enabled'  => 1,
				'spawned'  => undef,
			};
		} ## end foreach my $name ( keys( %{ $config->{kur} } ) )
		# member validation has to wait till every kur is registered
		foreach my $name ( keys( %{ $config->{kur} } ) ) {
			if ( defined( $config->{kur}{$name}{fan_out} ) ) {
				$self->_check_fan_out_members( $name, $config->{kur}{$name}, 1 );
			}
		}
	} ## end if ( defined( $config->{kur} ) )

	# create these here rather than in start_server as the PID file gets
	# written prior to start_server being called
	foreach my $dir ( $self->{run_base_dir}, $self->{run_base_dir} . '/kur' ) {
		if ( !-e $dir ) {
			# don't need to check if this worked failed or not here as the next if statement will handle that
			eval { mkdir($dir); };
		}
		if ( !-d $dir || !-r $dir || !-w $dir ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'The dir "' . $dir . '" is not a directory or is not read/writable';
			$self->warn;
		}
	} ## end foreach my $dir ( $self->{run_base_dir}, $self->...)

	return $self;
} ## end sub new

=head2 socket_path

Returns the path of the manager unix socket.

    my $socket_path = $ereshkigal->socket_path;

=cut

sub socket_path {
	my ($self) = @_;

	return $self->{run_base_dir} . '/socket';
}

=head2 pid_path

Returns the path of the manager PID file.

    my $pid_path = $ereshkigal->pid_path;

=cut

sub pid_path {
	my ($self) = @_;

	return $self->{run_base_dir} . '/pid';
}

=head2 kur_socket_path

Returns the path of the unix socket for the specified kur instance.

    my $kur_socket_path = $ereshkigal->kur_socket_path($name);

=cut

sub kur_socket_path {
	my ( $self, $name ) = @_;

	return $self->{run_base_dir} . '/kur/' . $name . '.sock';
}

=head2 start_server

Starts the manager. Spawns all configured kur instances, each supervised and
restarted with a backoff should it die, and brings up the
L<POE::Component::Server::JSONUnix> server on the manager socket, then calls
$poe_kernel->run.

This should not be expected to return till the manager is told to stop.

After binding, the manager socket is chowned to the configured group and
chmoded to the configured mode.

The JSON commands handled are as below.

    - status :: Manager status... uptime and kur list with up/down state.

    - status_all :: The above plus each kur's full status block.

    - status_kur :: Full status of the kur instance args.name. For a
          fan_out kur this is its member list plus each member's status.

    - banned :: Banned IPs, grouped per kur, along with when each expires.

    - ban :: Ban the IPs args.ips on the kur args.kur, or on all kurs if
          args.kur is not specified. If args.kur is a fan_out kur it expands
          to its members. args.ban_time, if defined, is forwarded
          to the kurs, overriding their default for how long the bans should
          last in seconds, with 0 meaning never time out. IPs are validated
          and normalized to their canonical form before being fanned out,
          with anything failing to validate reported back per IP under
          rejected rather than being sent to the kurs. If nothing validates
          the request as a whole errors.

    - unban :: If args.all is true, flush every kur. Otherwise validate and
          normalize args.ip, erroring if it fails to validate, then check
          each kur for it and unban it from each kur it is present on.

    - cidr_ban :: Ban the CIDR ranges args.cidrs, otherwise behaving like
          ban including the args.kur targeting and args.ban_time forwarding.
          CIDRs are validated and reduced to their canonical network form
          before being fanned out. A targeted kur, or an untargeted fan out,
          for which CIDR is not available answers per kur with either a drop
          or an error depending on its cidr_silent_drop.

    - cidr_unban :: Validate and normalize args.cidr, erroring if it fails to
          validate, then check each kur for it and unban it from each kur it
          is present on. There is no all form... unban with args.all already
          flushes CIDR bans alongside single IP bans.

    - add_kur :: Define and start a new kur instance, args.name and
          args.opts. Does not rewrite the config file.

    - remove_kur :: Stop the kur instance args.name and deregister it. Does
          not rewrite the config file.

    - checkpoint :: Force the kur args.kur, or all kurs if args.kur is not
          specified, to write their ban state CSVs out now. If args.kur is a
          fan_out kur it expands to its members.

    - re_init :: Have the kur args.kur, or all kurs if args.kur is not
          specified, tear their firewall setup down and rebuild it, re-banning
          everything their ban book carries. Expands a fan_out kur the same
          way checkpoint does. Bans are briefly not enforced while the setup
          is being rebuilt.

    - clear_retries :: Have the kur args.kur, or all kurs if args.kur is not
          specified, forget unbans still owed to the firewall. args.ip or
          args.cidr, at most one of them, names a single owed unban to
          forget rather than the lot. Expands a fan_out kur the same way
          checkpoint does. Nothing is asked of the firewall, so anything
          genuinely still banished there stays that way.

    - stop :: Stop all kur instances and then the manager.

=cut

sub start_server {
	my ($self) = @_;

	$self->errorblank;

	POE::Session->create(
		object_states => [
			$self => {
				'_start'      => '_poe_start',
				'spawn_kur'   => '_poe_spawn_kur',
				'restart_kur' => '_poe_restart_kur',
				'kur_stdout'  => '_poe_kur_stdout',
				'kur_stderr'  => '_poe_kur_stderr',
				'kur_reaped'  => '_poe_kur_reaped',
				'remove_kur'  => '_poe_remove_kur',
				'stop_all'    => '_poe_stop_all',
			},
		],
	);

	my $server = POE::Component::Server::JSONUnix->spawn(
		'socket_path'   => $self->socket_path,
		'socket_mode'   => $self->{socket_mode},
		'alias'         => 'ereshkigal_server',
		'auth_required' => $self->{enable_auth} ? 1 : 0,
		defined( $self->{auth_temp_dir} ) ? ( 'auth_temp_dir' => $self->{auth_temp_dir} ) : (),
		'on_error' => sub {
			my ( $operation, $errnum, $errstr ) = @_;
			log_drek( 'err', 'socket error during ' . $operation . '... ' . $errstr . ' (' . $errnum . ')' );
		},
		'commands' => {
			'status' => sub {
				my ( undef, undef, $ctx ) = @_;
				$self->_authorize($ctx);
				return $self->_cmd_status;
			},
			'status_all' => sub {
				my ( undef, undef, $ctx ) = @_;
				$self->_authorize($ctx);
				return $self->_cmd_status_all;
			},
			'status_kur' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_status_kur( $request, $ctx );
			},
			'banned' => sub {
				my ( undef, undef, $ctx ) = @_;
				$self->_authorize( $ctx, $self->_real_kur_names );
				return $self->_cmd_banned;
			},
			'ban' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_ban( $request, $ctx );
			},
			'unban' => sub {
				my ( undef, $request, $ctx ) = @_;
				$self->_authorize( $ctx, $self->_real_kur_names );
				return $self->_cmd_unban($request);
			},
			'cidr_ban' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_cidr_ban( $request, $ctx );
			},
			'cidr_unban' => sub {
				my ( undef, $request, $ctx ) = @_;
				$self->_authorize( $ctx, $self->_real_kur_names );
				return $self->_cmd_cidr_unban($request);
			},
			'add_kur' => sub {
				my ( undef, $request, $ctx ) = @_;
				$self->_authorize($ctx);
				return $self->_cmd_add_kur($request);
			},
			'remove_kur' => sub {
				my ( undef, $request, $ctx ) = @_;
				$self->_authorize($ctx);
				return $self->_cmd_remove_kur($request);
			},
			'checkpoint' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_checkpoint( $request, $ctx );
			},
			'clear_retries' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_clear_retries( $request, $ctx );
			},
			're_init' => sub {
				my ( undef, $request, $ctx ) = @_;
				return $self->_cmd_re_init( $request, $ctx );
			},
			'stop' => sub {
				my ( undef, undef, $ctx ) = @_;
				$self->_authorize($ctx);
				log_drek( 'info', 'stop requested' );
				$poe_kernel->post( 'ereshkigal_manager', 'stop_all' );
				# the current session is the JSONUnix server session, so this
				# fires its shutdown state after the response has had time to flush
				$poe_kernel->delay( 'shutdown', 1 );
				return { 'stopping' => 1 };
			},
		},
	);
	$self->{server} = $server;

	# group ownership gates who may drive the manager
	if ( !chown( $>, $self->{socket_gid}, $self->socket_path ) ) {
		log_drek( 'err', 'chown of "' . $self->socket_path . '" to GID ' . $self->{socket_gid} . ' failed... ' . $! );
	}

	$self->{started} = time;

	log_drek( 'info',
		'started... socket=' . $self->socket_path . ' kurs=' . join( ',', sort( keys( %{ $self->{kurs} } ) ) ) );

	$poe_kernel->run;

	log_drek( 'info', 'stopped' );

	return;
} ## end sub start_server

# Validates one kur definition, the hash that sits under kur.<name> in the
# config or arrives as args.opts on an add_kur request. Both paths run this so
# a kur added at runtime is held to exactly the same rules as one loaded from
# disk. It deliberately does not check fan_out members against the registry,
# as at config load that can only be done once every kur is registered...
# _check_fan_out_members is the second pass for that.
#
# The checks run as an if/elsif chain, so the first thing wrong is the thing
# reported. In order... the name matches /^[a-zA-Z0-9\-]+$/, the def is a
# hash, exactly one of backend and fan_out is present, fan_out is a non empty
# array of valid kur names, ban_time and checkpoint are non-negative ints,
# authed_users and authed_groups pass _authed_list_error, and options passes
# _options_error.
#
# Args, all required and positional...
#
#     $name   :: The kur instance name the def is for, as a string. Used both
#                as the thing being validated and in every error message.
#                undef is allowed in the sense that it is caught and reported
#                rather than warning.
#     $def    :: A hash ref of the kur definition. Recognized keys are
#                backend, fan_out, ports, protocols, prefix, self_heal,
#                ban_time, checkpoint, enable_cidr, cidr_silent_drop,
#                options, authed_users, and authed_groups. Anything else is
#                ignored here. A non hash ref, including undef, is caught and
#                reported.
#     $perror :: Boolean for whether a failure is an Error::Helper permanent
#                error as well as a die. Pass 1 from config load, where a bad
#                def means the object is unusable and new should die via
#                Error::Helper with flag 3, invalidKurDef. Pass 0 from
#                add_kur, where the die is caught and turned into an error
#                response and the manager carries on serving.
#
# Returns nothing meaningful, an empty return, when the def is good.
#
# Dies with a plain string describing the first problem found. When $perror
# is true it also sets perror, error 3, and errorString and calls warn first,
# so the die is preceded by the usual Error::Helper machinery.
#
#     # config load... a bad def should kill the object
#     $self->_check_kur_def( 'sshd', { 'backend' => 'pf' }, 1 );
#
#     # add_kur... the caller wants the die, not a dead manager
#     eval { $self->_check_kur_def( $name, $args->{opts}, 0 ); };
#     if ($@) { return { 'error' => $@ }; }
sub _check_kur_def {
	my ( $self, $name, $def, $perror ) = @_;

	my $error;
	if ( !defined($name) || $name !~ /^[a-zA-Z0-9\-]+$/ ) {
		$error = 'The kur name, "' . ( defined($name) ? $name : 'undef' ) . '", does not match /^[a-zA-Z0-9\-]+$/';
	} elsif ( ref($def) ne 'HASH' ) {
		$error = 'The def for the kur "' . $name . '" is not a hash';
	} elsif ( defined( $def->{backend} ) && defined( $def->{fan_out} ) ) {
		$error = 'The def for the kur "' . $name . '" has both a backend and a fan_out';
	} elsif ( !defined( $def->{backend} ) && !defined( $def->{fan_out} ) ) {
		$error = 'The def for the kur "' . $name . '" lacks a backend or a fan_out';
	} elsif ( defined( $def->{fan_out} ) && ( ref( $def->{fan_out} ) ne 'ARRAY' || !@{ $def->{fan_out} } ) ) {
		$error = 'The fan_out for the kur "' . $name . '" is not an array of one or more kur names';
	} elsif ( defined( $def->{fan_out} )
		&& grep { !defined($_) || ref($_) ne '' || $_ !~ /^[a-zA-Z0-9\-]+$/ } @{ $def->{fan_out} } )
	{
		$error = 'The fan_out for the kur "' . $name . '" contains an invalid kur name';
	} elsif ( defined( $def->{ban_time} ) && $def->{ban_time} !~ /^[0-9]+$/ ) {
		$error
			= 'The ban_time for the kur "'
			. $name . '", "'
			. $def->{ban_time}
			. '", is not a non-negative int of seconds';
	} elsif ( defined( $def->{checkpoint} ) && $def->{checkpoint} !~ /^[0-9]+$/ ) {
		$error
			= 'The checkpoint for the kur "'
			. $name . '", "'
			. $def->{checkpoint}
			. '", is not a non-negative int of seconds';
	} elsif ( defined( $def->{authed_users} ) && defined( _authed_list_error( $def->{authed_users} ) ) ) {
		$error = 'The authed_users for the kur "' . $name . '" is ' . _authed_list_error( $def->{authed_users} );
	} elsif ( defined( $def->{authed_groups} ) && defined( _authed_list_error( $def->{authed_groups} ) ) ) {
		$error = 'The authed_groups for the kur "' . $name . '" is ' . _authed_list_error( $def->{authed_groups} );
	} elsif ( defined( $def->{options} ) && defined( _options_error( $def->{options} ) ) ) {
		$error = 'The options for the kur "' . $name . '" is ' . _options_error( $def->{options} );
	}

	if ( defined($error) ) {
		if ($perror) {
			$self->{perror}      = 1;
			$self->{error}       = 3;
			$self->{errorString} = $error;
			$self->warn;
		}
		die($error);
	}

	return;
} ## end sub _check_kur_def

# Validates every member of a fan_out kur is a defined non fan_out kur...
# separate from _check_kur_def as it needs the kur registry, meaning at
# config load it can only happen once every kur is registered. _check_kur_def
# has already confirmed fan_out is a non empty array of syntactically valid
# names by the time this runs, so this only judges the names against what is
# actually registered.
#
# Walks the member list in order and stops at the first member that is either
# unknown to the registry or is itself a fan_out kur, gates not being
# allowed to nest.
#
# Args, all required and positional...
#
#     $name   :: The name of the fan_out kur whose members are being checked,
#                as a string. Used in the error messages.
#     $def    :: A hash ref of that kur's definition, which must carry a
#                fan_out key holding an array ref of member kur names.
#                _check_kur_def is expected to have validated its shape
#                already, so a missing or malformed fan_out here just walks
#                nothing and passes.
#     $perror :: Boolean, exactly as _check_kur_def takes it. 1 from config
#                load so a bad gate is an Error::Helper permanent error with
#                flag 3, invalidKurDef; 0 from add_kur so the die can be
#                turned into an error response.
#
# Returns nothing meaningful, an empty return, when every member checks out.
#
# Dies with a plain string naming the offending member and why. When $perror
# is true it sets perror, error 3, and errorString and warns first.
#
#     $self->_check_fan_out_members( 'baphomet', { 'fan_out' => [ 'sshd' ] }, 1 );
sub _check_fan_out_members {
	my ( $self, $name, $def, $perror ) = @_;

	my $error;
	foreach my $member ( @{ $def->{fan_out} } ) {
		if ( !defined( $self->{kurs}{$member} ) ) {
			$error = 'The fan_out for the kur "' . $name . '" contains an unknown kur, "' . $member . '"';
			last;
		}
		if ( defined( $self->{kurs}{$member}{opts}{fan_out} ) ) {
			$error
				= 'The fan_out for the kur "'
				. $name
				. '" contains the fan_out kur "'
				. $member
				. '"... fan_out kurs may not nest';
			last;
		}
	} ## end foreach my $member ( @{ $def->{fan_out} } )

	if ( defined($error) ) {
		if ($perror) {
			$self->{perror}      = 1;
			$self->{error}       = 3;
			$self->{errorString} = $error;
			$self->warn;
		}
		die($error);
	}

	return;
} ## end sub _check_fan_out_members

# Judges whether a value is usable as an authed_users or authed_groups list,
# which has to be an array of plain strings. Used by _check_kur_def for the
# per kur lists and by new for the manager wide ones, which is why it reports
# rather than dies... each caller wants to wrap the answer in its own
# message naming which list was wrong. It is a plain sub rather than a
# method, taking no invocant.
#
# Checks the value is an array ref and then that every element is defined and
# not a ref. Empty arrays are fine, an empty list simply granting nobody.
#
# Args, required and positional...
#
#     $list :: The value to judge. Anything at all may be passed... an array
#              ref of strings is the only thing that passes, and undef, a
#              plain string, a hash ref, or an array containing refs or undefs
#              all come back with an error string.
#
# Returns undef when the value is a valid list, or an error string fragment
# otherwise... either 'not an array' or 'not an array of just strings'. The
# fragments are written to read as the tail of a sentence, callers prefixing
# them with something like 'The authed_users for the kur "sshd" is '.
#
#     my $error = _authed_list_error( [ 'zane', 'root' ] );   # undef
#     my $error = _authed_list_error('zane');                 # 'not an array'
#     my $error = _authed_list_error( [ 'zane', {} ] );
#     # 'not an array of just strings'
sub _authed_list_error {
	my ($list) = @_;

	if ( ref($list) ne 'ARRAY' ) {
		return 'not an array';
	}
	foreach my $item ( @{$list} ) {
		if ( !defined($item) || ref($item) ne '' ) {
			return 'not an array of just strings';
		}
	}

	return undef;
} ## end sub _authed_list_error

# Judges whether a backend options table is something _build_kur_cmd can
# actually hand to the kur bin. The command line can only carry scalars, so a
# array or hash valued option would otherwise reach the backend stringified
# as ARRAY(0x...) and fail confusingly at init... this catches it at config
# load instead. The one exception is interfaces, which backends such as xdp
# want as an array and which rides its own --interfaces flag. Like
# _authed_list_error it reports rather than dies, and is a plain sub taking
# no invocant.
#
# Checks the value is a hash ref, then walks every key. A scalar value passes
# immediately. The interfaces key additionally passes when it is an array ref
# containing only scalars. Anything else fails, naming the key.
#
# Args, required and positional...
#
#     $options :: The value to judge, expected to be a hash ref of backend
#                 option name to value. Anything may be passed... a non hash
#                 ref, including undef, comes back as 'not a hash'. Key
#                 names are not judged at all, only their values, as which
#                 options a backend takes is the backend's business.
#
# Returns undef when the table is usable, or an error string fragment
# otherwise... 'not a hash', or a longer one naming the offending key. As
# with _authed_list_error the fragments read as the tail of a sentence the
# caller prefixes.
#
#     my $error = _options_error( { 'kill' => 1 } );                  # undef
#     my $error = _options_error( { 'interfaces' => ['eth0'] } );     # undef
#     my $error = _options_error( { 'bad' => ['a'] } );
#     # 'carrying a non-scalar value for the option "bad"... only interfaces
#     # may be an array, and only of plain scalars'
sub _options_error {
	my ($options) = @_;

	if ( ref($options) ne 'HASH' ) {
		return 'not a hash';
	}
	foreach my $key ( keys( %{$options} ) ) {
		my $value = $options->{$key};
		next if ( ref($value) eq '' );
		if ( $key eq 'interfaces' && ref($value) eq 'ARRAY' && !grep { ref($_) ne '' } @{$value} ) {
			next;
		}
		return 'carrying a non-scalar value for the option "' . $key
			. '"... only interfaces may be an array, and only of plain scalars';
	}

	return undef;
} ## end sub _options_error

# Checks if the user is in the passed users list or a member of one of the
# passed groups. The one place membership is actually decided, called by
# _authorize for both the manager level lists and the per kur ones, so the
# rule stays identical for both. It renders no verdict of its own about what
# that membership means... it answers yes or no and _authorize decides what
# to do about it.
#
# Names are compared as exact strings, no case folding and no globbing.
# Group membership, primary and secondary both, comes from the JSONUnix
# context rather than being resolved here, which is what lets user and group
# database changes apply without a restart... the context resolves it
# through NSS and caches it per connection.
#
# Args, all required and positional...
#
#     $ctx      :: The POE::Component::Server::JSONUnix context object for
#                  the connection the request arrived on. Only its in_group
#                  method is used here. Must be a real context... there is no
#                  guard against undef, as every caller has already taken uid
#                  and username off it.
#     $username :: The username to match against $users, as a plain string.
#                  _authorize passes '' rather than undef when the context
#                  has no username, so an empty string simply matches nothing.
#     $users    :: An array ref of usernames granted access. May be empty.
#     $groups   :: An array ref of group names granted access. May be empty. A
#                  group that does not exist just never matches rather than
#                  erroring.
#
# Returns 1 if the user matches by name or by any group, 0 if none of them
# match.
#
#     if ( $self->_user_in_lists( $ctx, 'zane', ['root'], ['wheel'] ) ) {
#         # zane is not the user root, but may still be in the wheel group
#     }
sub _user_in_lists {
	my ( $self, $ctx, $username, $users, $groups ) = @_;

	foreach my $user ( @{$users} ) {
		if ( $user eq $username ) {
			return 1;
		}
	}

	foreach my $group ( @{$groups} ) {
		# unknown groups just never match rather than erroring
		if ( $ctx->in_group($group) ) {
			return 1;
		}
	}

	return 0;
} ## end sub _user_in_lists

# Authorizes the authenticated user behind the context for the specified
# kurs, or for manager level commands when no kurs are specified. This is the
# whole of the trust model... every command handler calls it before doing
# anything, and a command must be authorized for every kur it touches. It is
# a no-op when enable_auth is off, so the same handlers serve both modes with
# out branching.
#
# The decision, in order... enable_auth off means yes. A context with no uid
# means the JSONUnix auth gate has somehow been bypassed and is refused. UID
# 0 is always yes. With no kurs named it is a manager level command and only
# the global lists are consulted. With kurs named, each is checked against
# the global lists plus that kur's own, which expand rather than replace
# them, and the first kur the user is not entitled to refuses the lot.
#
# Note the empty kur list case is load bearing rather than accidental...
# untargeted commands on a manager carrying zero real kurs land there
# deliberately, as with no per-kur lists to expand the global lists are all
# there is to check. That is why callers authorize before reporting that
# there is nothing to act on.
#
# Args...
#
#     $ctx   :: Required. The POE::Component::Server::JSONUnix context for
#              the connection, which supplies uid, username, and in_group. A
#              context whose uid method returns undef is treated as a
#              authentication failure rather than trusted.
#     @kurs  :: Optional, zero or more kur names as plain strings. Zero names
#              means the manager level check. Names that are not registered
#              are still checked, against the global lists alone, so that a
#              refusal and a nonexistent kur look the same to a caller who
#              is not entitled to either... callers rely on this to keep kur
#              names from being enumerated.
#
# Returns nothing meaningful, an empty return, when the user is allowed.
#
# Dies with a HASH ref rather than a string when refusing, which is how a
# machine readable code reaches the JSONUnix error response. The shape is
# { error => '...', code => '...' }, where code is 'permission_denied' for a
# authorization refusal and 'auth_required' for the should-be-unreachable
# missing uid case. Consumers are told to branch on code rather than match
# the message text, so the code matters as much as the message.
#
#     # manager level... stop, add_kur, remove_kur, the whole manager views
#     $self->_authorize($ctx);
#
#     # one named kur, as a targeted ban does
#     $self->_authorize( $ctx, 'sshd' );
#
#     # every real kur, as an untargeted command does
#     $self->_authorize( $ctx, $self->_real_kur_names );
sub _authorize {
	my ( $self, $ctx, @kurs ) = @_;

	if ( !$self->{enable_auth} ) {
		return;
	}

	my $uid      = $ctx->uid;
	my $username = $ctx->username;
	if ( !defined($uid) ) {
		# should be unreachable as JSONUnix gates unauthed commands first...
		# a hash ref die carries a machine-readable code through to the
		# JSONUnix error response, matching its own auth_required code
		die( { 'error' => 'authentication required', 'code' => 'auth_required' } );
	}
	if ( $uid == 0 ) {
		return;
	}
	$username = '' if !defined($username);

	# no kurs named means a manager level command... untargeted commands on a
	# manager with zero real kurs also land here, deliberately, as with no
	# per-kur lists to expand the global lists are all there is to check
	if ( !@kurs ) {
		if ( $self->_user_in_lists( $ctx, $username, $self->{authed_users}, $self->{authed_groups} ) ) {
			return;
		}
		die(
			{
				'error' => 'The user "' . $username . '" is not authorized for manager level commands',
				'code'  => 'permission_denied',
			}
		);
	} ## end if ( !@kurs )

	foreach my $name (@kurs) {
		# the effective lists for a kur are the global ones plus its own
		my $def = defined( $self->{kurs}{$name} ) ? $self->{kurs}{$name}{opts} : {};
		my @users
			= ( @{ $self->{authed_users} }, ref( $def->{authed_users} ) eq 'ARRAY' ? @{ $def->{authed_users} } : () );
		my @groups = ( @{ $self->{authed_groups} },
			ref( $def->{authed_groups} ) eq 'ARRAY' ? @{ $def->{authed_groups} } : () );
		if ( !$self->_user_in_lists( $ctx, $username, \@users, \@groups ) ) {
			die(
				{
					'error' => 'The user "' . $username . '" is not authorized for the kur "' . $name . '"',
					'code'  => 'permission_denied',
				}
			);
		}
	} ## end foreach my $name (@kurs)

	return;
} ## end sub _authorize

# Builds an Ereshkigal::Client aimed at one kur's socket, carrying the
# manager wide timeout. Used where a single kur has to be spoken to on its
# own rather than fanned to, which is the two shutdown paths, _poe_stop_all
# and _poe_remove_kur. Everything else goes through _fan_out, as that answers
# per kur and bounds the whole conversation with one deadline.
#
# Nothing is connected here... the client only opens a socket when a call is
# made on it, so a client for a kur that is not running is fine to build and
# will simply fail at call time.
#
# Args, required and positional...
#
#     $name :: The kur instance name, as a plain string. Not checked against
#              the registry... the path is built from it regardless, so a
#              name that is not registered yields a client pointed at a
#              socket that does not exist.
#
# Returns a new Ereshkigal::Client instance with its socket set to that
# kur's path under run_base_dir/kur/ and its timeout set to the manager's
# timeout setting.
#
#     eval { $self->_kur_client('sshd')->call_ok('stop'); };
#     if ($@) { log_drek( 'err', 'could not stop sshd... ' . $@ ); }
sub _kur_client {
	my ( $self, $name ) = @_;

	return Ereshkigal::Client->new(
		'socket'  => $self->kur_socket_path($name),
		'timeout' => $self->{timeout},
	);
}

# The names of the kurs that are actual processes, sorted... fan_out kurs
# are manager side only and get excluded everywhere an untargeted command
# resolves its targets. Every untargeted command runs through this, which is
# what keeps a gate from being double counted... banning with no --kur
# reaches each real kur once rather than once directly and again through
# every gate naming it.
#
# Takes only the invocant. Reads the kur registry and filters out any entry
# whose opts carry a fan_out key, whether or not it is running... this is
# about what a kur is, not what state it is in.
#
# Returns the names as a sorted list, not an array ref, so it drops straight
# into a call expecting a list. A manager with no real kurs returns the empty
# list, which callers are careful to authorize on before reporting.
#
#     my @targets = $self->_real_kur_names;
#     my $kurs    = $self->_fan_out( \@targets, 'banned' );
#
#     # or straight into a call taking a list
#     $self->_authorize( $ctx, $self->_real_kur_names );
sub _real_kur_names {
	my ($self) = @_;

	return grep { !defined( $self->{kurs}{$_}{opts}{fan_out} ) } sort( keys( %{ $self->{kurs} } ) );
}

# Expands a targeted kur name into fan out targets... a fan_out kur becomes
# its members while a plain kur is just itself. This is what makes a gate
# usable as a single point of contact, and it is deliberately separate from
# authorization... the caller authorizes against the name it was given, not
# against what that name expands to, which is exactly why being granted a
# gate covers its members without being listed on any of them.
#
# One level only. Gates may not nest, which _check_fan_out_members enforces
# at definition time, so there is no recursion here.
#
# Args, required and positional...
#
#     $name :: The kur instance name that was targeted, as a plain string. A
#              name that is not registered is not an error here... it comes
#              back as itself, and the fan out then answers it with a not
#              running error. Callers that want an unknown kur to be an error
#              check the registry themselves, after authorizing.
#
# Returns a list of kur names to actually act on. For a gate that is its
# member list in the order the fan_out array carries them; for anything else
# it is a one element list holding the name it was given.
#
#     my @targets = $self->_expand_kur_targets('sshd');      # ('sshd')
#     my @targets = $self->_expand_kur_targets('baphomet');  # ('sshd','smtp')
sub _expand_kur_targets {
	my ( $self, $name ) = @_;

	my $entry = $self->{kurs}{$name};
	if ( defined($entry) && defined( $entry->{opts}{fan_out} ) ) {
		return @{ $entry->{opts}{fan_out} };
	}

	return ($name);
} ## end sub _expand_kur_targets

# Fans one command out to the passed kur instances concurrently via
# Ereshkigal::Client->call_many. Almost every command handler ends in a call
# to this, and its return is what they hand back as the kurs value of their
# response, so the per kur shape a consumer sees is decided here.
#
# Kurs that are not running are answered locally with a not running error and
# never dialled, so a stopped kur costs nothing and cannot slow the fan out
# down. Whatever is left is handed to call_many in one go, which talks to
# them concurrently under a single shared deadline... the wall time is the
# slowest kur capped at one timeout rather than the sum of all of them.
#
# It does no authorizing and no target expansion of its own... callers have
# already run _authorize and _expand_kur_targets by the time they get here.
#
# Args...
#
#     $targets :: Required. An array ref of kur names to reach, already
#                 expanded, so a gate's members rather than the gate. May be
#                 empty, which answers with an empty hash and dials nothing.
#                 Names not in the registry are answered as not running.
#     $command :: Required. The command name to send each kur, as a plain
#                 string... 'ban', 'banned', 'checkpoint', 're_init' and so
#                 on. Sent verbatim, so a command the kur does not handle
#                 comes back as that kur's error.
#     $args    :: Optional. A hash ref sent as the args value of the request,
#                 the same for every kur. Omitted or undef sends no args key
#                 at all, which is what commands taking none expect.
#
# Returns a hash ref keyed by kur name, every name in $targets present. Each
# value is either that kur's result, whatever shape the kur's own handler
# returned, or { error => '...' } when it could not be reached or answered
# with an error status. A caller can tell the two apart by looking for an error
# key, which is what _cmd_status_all and _cmd_status_kur do.
#
#     my $kurs = $self->_fan_out( [ 'sshd', 'smtp' ], 'banned' );
#     # { sshd => { banned => [...], ... }, smtp => { error => 'not running' } }
#
#     my $kurs = $self->_fan_out(
#         [ $self->_real_kur_names ],
#         'ban',
#         { 'ips' => ['1.2.3.4'], 'ban_time' => 3600 }
#     );
sub _fan_out {
	my ( $self, $targets, $command, $args ) = @_;

	my $kurs    = {};
	my $sockets = {};
	foreach my $name ( @{$targets} ) {
		my $entry = $self->{kurs}{$name};
		if ( !defined($entry) || !defined( $entry->{pid} ) ) {
			$kurs->{$name} = { 'error' => 'not running' };
			next;
		}
		$sockets->{$name} = $self->kur_socket_path($name);
	}

	if ( %{$sockets} ) {
		my $answers = Ereshkigal::Client->call_many(
			'sockets' => $sockets,
			'command' => $command,
			defined($args) ? ( 'args' => $args ) : (),
			'timeout' => $self->{timeout},
		);
		foreach my $name ( keys( %{$answers} ) ) {
			if ( defined( $answers->{$name}{error} ) ) {
				$kurs->{$name} = { 'error' => $answers->{$name}{error} };
			} else {
				$kurs->{$name} = $answers->{$name}{result};
			}
		}
	} ## end if ( %{$sockets} )

	return $kurs;
} ## end sub _fan_out

# Builds the argv the manager spawns a kur process with, translating that
# kur's config hash into the kur bin's flags. This is the single place the
# manager side config and the kur bin's command line meet, so anything the
# kur bin learns to take has to be taught here too or it can never be set
# from the config.
#
# Layering is resolved here rather than kur side... ban_time and checkpoint
# fall back to the manager wide values when the kur names none, and the two
# CIDR toggles do the same and are collapsed to a clean 1 or 0 so the kur is
# not left folding config strings. ports and protocols are comma joined.
# Backend options ride --option key=value, sorted for a stable command line,
# with interfaces the one exception... it may be an array and so rides its
# own --interfaces flag, comma joined, for the kur bin to split back apart.
# _options_error has already refused any other array valued option by now.
#
# Always passes --foreground, as the manager supervises the process through a
# POE::Wheel::Run and must not have it daemonize away from its wheel.
#
# Args, required and positional...
#
#     $name :: The kur instance name, as a plain string. Must already be
#              registered... its opts hash is read straight out of the
#              registry, so an unknown name warns and builds a broken command.
#
# Returns the command as a list, ready to hand to POE::Wheel::Run as its
# Program... the kur bin path first, then the flags. Not a string, so no
# quoting is needed or applied and an option value carrying spaces survives.
#
#     my @cmd = $self->_build_kur_cmd('sshd');
#     # ( '/usr/local/bin/kur', '--foreground', '--name', 'sshd',
#     #   '--backend', 'pf', '--run', '/var/run/ereshkigal', ... )
#     my $wheel = POE::Wheel::Run->new( 'Program' => \@cmd, ... );
sub _build_kur_cmd {
	my ( $self, $name ) = @_;

	my $def = $self->{kurs}{$name}{opts};

	my @cmd = (
		$self->{kur_bin}, '--foreground',  '--name', $name,
		'--backend',      $def->{backend}, '--run',  $self->{run_base_dir},
		'--cache',        $self->{cache_base_dir},
	);

	foreach my $listy ( 'ports', 'protocols' ) {
		if ( defined( $def->{$listy} ) ) {
			my @items = ref( $def->{$listy} ) eq 'ARRAY' ? @{ $def->{$listy} } : ( $def->{$listy} );
			if (@items) {
				push( @cmd, '--' . $listy, join( ',', @items ) );
			}
		}
	}

	if ( defined( $def->{prefix} ) ) {
		push( @cmd, '--prefix', $def->{prefix} );
	}

	if ( defined( $def->{self_heal} ) ) {
		push( @cmd, '--self-heal', $def->{self_heal} ? 1 : 0 );
	}

	# the kur ban_time and checkpoint, defaulting to the manager wide ones
	push( @cmd, '--ban-time',   defined( $def->{ban_time} )   ? $def->{ban_time}   : $self->{ban_time} );
	push( @cmd, '--checkpoint', defined( $def->{checkpoint} ) ? $def->{checkpoint} : $self->{checkpoint} );

	# the CIDR toggles, per kur overriding the manager wide ones, collapsed to
	# 1/0 here so the kur is handed a clean boolean
	my $enable_cidr      = defined( $def->{enable_cidr} )      ? $def->{enable_cidr}      : $self->{enable_cidr};
	my $cidr_silent_drop = defined( $def->{cidr_silent_drop} ) ? $def->{cidr_silent_drop} : $self->{cidr_silent_drop};
	push( @cmd, '--enable-cidr',      $enable_cidr      ? 1 : 0 );
	push( @cmd, '--cidr-silent-drop', $cidr_silent_drop ? 1 : 0 );

	if ( ref( $def->{options} ) eq 'HASH' ) {
		foreach my $key ( sort( keys( %{ $def->{options} } ) ) ) {
			my $value = $def->{options}{$key};
			# interfaces is the one array valued option, riding its own flag
			# so the kur bin can rebuild the array
			if ( $key eq 'interfaces' ) {
				push( @cmd, '--interfaces', ref($value) eq 'ARRAY' ? join( ',', @{$value} ) : $value );
			} else {
				push( @cmd, '--option', $key . '=' . $value );
			}
		} ## end foreach my $key ( sort( keys( %{ $def->{options...}})))
	} ## end if ( ref( $def->{options} ) eq 'HASH' )

	return @cmd;
} ## end sub _build_kur_cmd

#
# POE states for the manager session
#

# The manager session's _start handler, run by the POE kernel once when the
# session created in start_server comes up. Not called directly by anything.
#
# Claims the alias 'ereshkigal_manager', which is how every other part of the
# process reaches this session... the JSONUnix command handlers post to that
# alias rather than holding a session reference, and _cmd_add_kur and
# _cmd_remove_kur both rely on it. Then yields a spawn_kur for every kur in
# the registry, sorted, rather than spawning inline, so the session is fully
# up before any child process work begins.
#
# POE calling convention... invoked as an object state, so @_ carries OBJECT
# and KERNEL...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[KERNEL] :: The POE kernel, used to set the alias and to yield the
#                   per kur spawn_kur events.
#
# Returns nothing meaningful, an empty return. POE ignores the return of a
# state handler.
#
#     # not called directly... the kernel fires it when the session starts
#     POE::Session->create(
#         object_states => [ $self => { '_start' => '_poe_start', ... } ] );
sub _poe_start {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

	$kernel->alias_set('ereshkigal_manager');

	foreach my $name ( sort( keys( %{ $self->{kurs} } ) ) ) {
		$kernel->yield( 'spawn_kur', $name );
	}

	return;
} ## end sub _poe_start

# The manager session's spawn_kur handler, which actually starts one kur
# process. Reached three ways... _poe_start yields it per kur at startup,
# _poe_restart_kur yields it after a death, and _cmd_add_kur posts it for a
# kur added at runtime. All three go through the session because a
# POE::Wheel::Run must be created and destroyed in the session that watches
# it.
#
# Refuses to do anything, silently, when the kur is unknown, disabled,
# already has a wheel, or the manager is shutting down... that last one is
# what keeps a death during shutdown from being restarted into a race. A
# fan_out kur also returns early, having no process to spawn.
#
# Otherwise builds the command via _build_kur_cmd, starts it under a
# POE::Wheel::Run wired to the kur_stdout and kur_stderr events, and asks the
# kernel to send kur_reaped when it exits. The registry entry then records
# the wheel, the PID, and the spawn time, and both the wheel_to_kur and
# pid_to_kur lookups gain an entry... those two are how the output and reap
# handlers, which are only told a wheel ID or a PID, learn which kur they are
# about.
#
# POE calling convention... invoked as an object state...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[KERNEL] :: The POE kernel, used for sig_child.
#     $_[ARG0]   :: The kur instance name to spawn, as a plain string. A name
#                   that is not registered is ignored rather than erroring.
#
# Returns nothing meaningful, an empty return.
#
#     $kernel->yield( 'spawn_kur', 'sshd' );
#     $poe_kernel->post( 'ereshkigal_manager', 'spawn_kur', 'sshd' );
sub _poe_spawn_kur {
	my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];

	my $entry = $self->{kurs}{$name};
	if ( !defined($entry) || !$entry->{enabled} || defined( $entry->{wheel} ) || $self->{shutting_down} ) {
		return;
	}

	# fan_out kurs are manager side only... nothing to spawn
	if ( defined( $entry->{opts}{fan_out} ) ) {
		return;
	}

	my @cmd = $self->_build_kur_cmd($name);

	my $wheel = POE::Wheel::Run->new(
		'Program'     => \@cmd,
		'StdoutEvent' => 'kur_stdout',
		'StderrEvent' => 'kur_stderr',
	);

	$kernel->sig_child( $wheel->PID, 'kur_reaped' );

	$entry->{wheel}   = $wheel;
	$entry->{pid}     = $wheel->PID;
	$entry->{spawned} = time;

	$self->{wheel_to_kur}{ $wheel->ID } = $name;
	$self->{pid_to_kur}{ $wheel->PID }  = $name;

	log_drek( 'info', 'spawned kur "' . $name . '" as PID ' . $wheel->PID . '... ' . join( ' ', @cmd ) );

	return;
} ## end sub _poe_spawn_kur

# The manager session's restart_kur handler, which exists only so a delayed
# restart has something to land on. _poe_kur_reaped sets a delay_set for this
# rather than for spawn_kur directly, keeping the two apart so the backoff
# timer is visibly a restart rather than looking like a fresh spawn... all it
# does is yield spawn_kur, which holds every one of the guards about whether
# spawning is actually appropriate by then.
#
# That indirection matters for one case in particular... between the delay
# being set and it firing, the kur may have been removed or the manager may
# have begun shutting down, and spawn_kur is where both are noticed.
#
# POE calling convention... invoked as an object state...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[KERNEL] :: The POE kernel, used to yield spawn_kur.
#     $_[ARG0]   :: The kur instance name to restart, as a plain string,
#                   passed straight through to spawn_kur.
#
# Returns nothing meaningful, an empty return.
#
#     # from _poe_kur_reaped, after a death, with the current backoff
#     $kernel->delay_set( 'restart_kur', $delay, $name );
sub _poe_restart_kur {
	my ( $self, $kernel, $name ) = @_[ OBJECT, KERNEL, ARG0 ];

	$kernel->yield( 'spawn_kur', $name );

	return;
}

# The manager session's kur_stdout handler, fired by the POE::Wheel::Run of
# a kur process for each line that child writes to stdout. A kur normally
# says nothing there, logging through syslog itself, so anything arriving
# is worth relaying rather than swallowing... it is usually a module warning
# or something printed before logging was up.
#
# The wheel only reports which wheel ID the line came from, so the kur name
# is looked up through wheel_to_kur. A line arriving after the entry has gone
# is logged against 'unknown' rather than dropped or warned about.
#
# POE calling convention... invoked as an object state, and note it does not
# take KERNEL...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[ARG0]   :: The line the child wrote, as a string. The wheel has
#                   already split on newlines, but the line is chomped here
#                   anyway before it reaches the log.
#     $_[ARG1]   :: The ID of the POE::Wheel::Run the line came from, used to
#                   resolve the kur name via wheel_to_kur.
#
# Returns nothing meaningful, an empty return.
#
#     # not called directly... wired up when the wheel is created
#     POE::Wheel::Run->new( 'StdoutEvent' => 'kur_stdout', ... );
sub _poe_kur_stdout {
	my ( $self, $line, $wheel_id ) = @_[ OBJECT, ARG0, ARG1 ];

	my $name = $self->{wheel_to_kur}{$wheel_id};
	$name = 'unknown' if !defined($name);
	chomp($line);
	log_drek( 'info', 'kur "' . $name . '" stdout... ' . $line );

	return;
} ## end sub _poe_kur_stdout

# The manager session's kur_stderr handler, the stderr twin of
# _poe_kur_stdout, differing only in logging at err rather than info. This is
# where a kur that dies before it can log for itself ends up being heard
# from... a backend init failure or a missing binary arrives here, which is
# why it is relayed at err and not quietly discarded.
#
# As with stdout the wheel only reports a wheel ID, so the kur name comes
# from wheel_to_kur, and a line that outlives the entry is logged against
# 'unknown'.
#
# POE calling convention... invoked as an object state, without KERNEL...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[ARG0]   :: The line the child wrote to stderr, as a string, chomped
#                   here before logging.
#     $_[ARG1]   :: The ID of the POE::Wheel::Run it came from, used to
#                   resolve the kur name via wheel_to_kur.
#
# Returns nothing meaningful, an empty return.
#
#     # not called directly... wired up when the wheel is created
#     POE::Wheel::Run->new( 'StderrEvent' => 'kur_stderr', ... );
sub _poe_kur_stderr {
	my ( $self, $line, $wheel_id ) = @_[ OBJECT, ARG0, ARG1 ];

	my $name = $self->{wheel_to_kur}{$wheel_id};
	$name = 'unknown' if !defined($name);
	chomp($line);
	log_drek( 'err', 'kur "' . $name . '" stderr... ' . $line );

	return;
} ## end sub _poe_kur_stderr

# The manager session's kur_reaped handler, fired by the kernel's sig_child
# watch when a kur process exits however it exited... cleanly via stop, by
# signal, or by crashing. This is the whole of the supervision policy.
#
# First the bookkeeping, which happens for every death... the PID is taken
# out of pid_to_kur, and if the registry entry still holds the wheel that is
# dropped from wheel_to_kur and the entry's wheel and pid cleared, so a kur
# that is down is visibly down everywhere. Note the wheel_to_kur cleanup only
# happens while the entry is still around, which is why _poe_remove_kur does
# its own before deleting one.
#
# Then the restart decision. Nothing is restarted while shutting_down is set,
# nor for a kur that has been removed or disabled... those are all deaths we
# asked for. Otherwise the backoff runs... a process that stayed up longer
# than 60 seconds is considered to have started fine and has its delay reset
# to 1, so a kur that is merely restarted occasionally does not creep toward
# the cap. The restart is then scheduled at the current delay and the delay
# doubled for next time, capped at 60 seconds, and the restart count bumped.
#
# POE calling convention... invoked as an object state via sig_child, so note
# the argument slots are the signal handler's rather than ARG0 onward...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[KERNEL] :: The POE kernel, used for the delay_set that schedules the
#                   restart.
#     $_[ARG1]   :: The PID that exited, which is what pid_to_kur is keyed by.
#                   A PID that is not in there, which is any child not ours,
#                   returns immediately.
#     $_[ARG2]   :: The raw wait status, with the signal that killed it in
#                   the low seven bits and the exit code in the next eight.
#                   Both are decoded, so being killed by signal 9 and
#                   exiting 9 are logged as the different things they are.
#                   It never changes the decision though. Whether a kur
#                   comes back is the manager's call alone, so a kur does
#                   not get a vote by choosing how it exits... a clean exit
#                   the manager did not ask for is restarted exactly as a
#                   crash is, and logged as the error it is. The status is
#                   only ever wording.
#
# Returns nothing meaningful, an empty return.
#
#     # not called directly... armed per child when it is spawned
#     $kernel->sig_child( $wheel->PID, 'kur_reaped' );
sub _poe_kur_reaped {
	my ( $self, $kernel, $pid, $exit ) = @_[ OBJECT, KERNEL, ARG1, ARG2 ];

	my $name = delete( $self->{pid_to_kur}{$pid} );
	if ( !defined($name) ) {
		return;
	}

	my $entry = $self->{kurs}{$name};
	if ( defined($entry) && defined( $entry->{wheel} ) ) {
		delete( $self->{wheel_to_kur}{ $entry->{wheel}->ID } );
		$entry->{wheel} = undef;
		$entry->{pid}   = undef;
	}

	# the raw wait status packs the signal that killed it into the low seven
	# bits and the exit code into the next eight, so decode both rather than
	# shifting blindly... a kur killed by signal 9 and one that exited 9 of
	# its own accord are not the same event and should not read alike
	my $signal = $exit & 127;
	my $how    = $signal ? 'was killed by signal ' . $signal : 'exited with ' . ( $exit >> 8 );
	log_drek( 'info', 'kur "' . $name . '" PID ' . $pid . ' ' . $how );

	if ( $self->{shutting_down} || !defined($entry) || !$entry->{enabled} ) {
		return;
	}

	# it ran long enough to be considered to have started fine, so reset the backoff
	if ( defined( $entry->{spawned} ) && ( time - $entry->{spawned} ) > 60 ) {
		$entry->{delay} = 1;
	}

	my $delay = $entry->{delay};
	$entry->{delay} = $delay * 2 > 60 ? 60 : $delay * 2;
	$entry->{restarts}++;

	# whether a kur comes back is the manager's call and only the manager's...
	# a kur does not get a vote in it by choosing how it exits, so anything
	# the manager did not itself ask for is restarted, tidily as it may have
	# gone. The stops that were asked for never reach here, stop_all having
	# set shutting_down and remove_kur having cleared enabled before either
	# takes a kur down, so what is left is a kur that went away on its own.
	# That is an error whatever status it managed to exit with, and is logged
	# as one... the status only changes the wording, never the decision
	log_drek( 'err', 'kur "' . $name . '" ' . $how . ', restarting in ' . $delay . ' seconds' );

	$kernel->delay_set( 'restart_kur', $delay, $name );

	return;
} ## end sub _poe_kur_reaped

# The manager session's remove_kur handler, which stops one kur and drops it
# from the registry for good. The actual removal has to happen in the manager
# session as destroying a POE::Wheel::Run from within another session leaves
# its watchers behind, keeping the manager session alive forever... which is
# why _cmd_remove_kur only marks the entry disabled and posts here rather
# than doing the work itself.
#
# A running kur is asked to stop over its own socket, so it checkpoints its
# tablets and tears its firewall setup down properly. Only if that fails is
# it sent a TERM, which gets the process gone but leaves whatever it was
# holding in the firewall. Either way the entry is then unwired... its wheel
# dropped from wheel_to_kur, its PID from pid_to_kur, and the registry entry
# deleted.
#
# Those two lookups are cleaned here rather than being left to the reap
# handler because the reap handler only cleans them while the registry entry
# is still around, and it is about to not be... without this every add and
# remove cycle would leak a wheel_to_kur entry.
#
# POE calling convention... invoked as an object state, and note it does not
# take KERNEL...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[ARG0]   :: The kur instance name to remove, as a plain string. A
#                   name that is no longer registered returns immediately, so
#                   a doubled post is harmless.
#
# Returns nothing meaningful, an empty return.
#
#     # from _cmd_remove_kur, after marking the entry disabled
#     $poe_kernel->post( 'ereshkigal_manager', 'remove_kur', $name );
sub _poe_remove_kur {
	my ( $self, $name ) = @_[ OBJECT, ARG0 ];

	my $entry = $self->{kurs}{$name};
	if ( !defined($entry) ) {
		return;
	}

	if ( defined( $entry->{pid} ) ) {
		eval { $self->_kur_client($name)->call_ok('stop'); };
		if ($@) {
			log_drek( 'err', 'stopping kur "' . $name . '" via it\'s socket failed, sending TERM... ' . $@ );
			if ( defined( $entry->{wheel} ) ) {
				$entry->{wheel}->kill('TERM');
			}
		}
	}

	# the reaped handler only cleans these up while the registry entry is
	# still around, which it is about to not be, so they are cleaned here...
	# otherwise every add/remove cycle leaks a wheel_to_kur entry
	if ( defined( $entry->{wheel} ) ) {
		delete( $self->{wheel_to_kur}{ $entry->{wheel}->ID } );
	}
	if ( defined( $entry->{pid} ) ) {
		delete( $self->{pid_to_kur}{ $entry->{pid} } );
	}

	delete( $self->{kurs}{$name} );

	log_drek( 'info', 'removed kur "' . $name . '"' );

	return;
} ## end sub _poe_remove_kur

# The manager session's stop_all handler, which brings every kur down and
# then lets the manager session end. Posted by the stop command handler,
# which answers the client first and leaves the shutdown to happen behind
# its back.
#
# Sets shutting_down before anything else, which is what stops _poe_kur_reaped
# from restarting the deaths that are about to happen... without that, every
# kur stopped here would be dutifully brought back.
#
# Then each running kur is asked to stop over its own socket, in name order,
# so it checkpoints and tears its firewall setup down properly. A kur whose
# socket will not answer is sent a TERM instead, which ends the process but
# leaves its firewall state behind. This is done one at a time and inline
# rather than fanned out, as the manager has nothing else to do and each stop
# should be given its own full timeout.
#
# Finally the session's alarms are cleared and the alias dropped, which is
# what actually lets the session, and so the kernel, finish.
#
# POE calling convention... invoked as an object state...
#
#     $_[OBJECT] :: This Ereshkigal instance.
#     $_[KERNEL] :: The POE kernel, used to clear alarms and drop the alias.
#
# Returns nothing meaningful, an empty return.
#
#     # from the stop command handler, after its response has been queued
#     $poe_kernel->post( 'ereshkigal_manager', 'stop_all' );
sub _poe_stop_all {
	my ( $self, $kernel ) = @_[ OBJECT, KERNEL ];

	$self->{shutting_down} = 1;

	foreach my $name ( sort( keys( %{ $self->{kurs} } ) ) ) {
		my $entry = $self->{kurs}{$name};
		if ( !defined( $entry->{pid} ) ) {
			next;
		}
		eval { $self->_kur_client($name)->call_ok('stop'); };
		if ($@) {
			log_drek( 'err', 'stopping kur "' . $name . '" via it\'s socket failed, sending TERM... ' . $@ );
			if ( defined( $entry->{wheel} ) ) {
				$entry->{wheel}->kill('TERM');
			}
		}
	} ## end foreach my $name ( sort( keys( %{ $self->{kurs}...})))

	$kernel->alarm_remove_all;
	$kernel->alias_remove('ereshkigal_manager');

	return;
} ## end sub _poe_stop_all

#
# JSONUnix command handlers
#

# Builds the per kur summary rows that _cmd_status and, through it,
# _cmd_status_all hand back as their kurs value. Everything here comes out of
# the manager's own registry... no kur is asked anything, which is the point.
# It is what lets status answer promptly and truthfully even when a kur has
# wedged, and _cmd_status_all is what layers the asking on top.
#
# Takes only the invocant. A real kur's row reports whether it is running,
# from whether the registry holds a PID, along with that PID, its restart
# count, and whether it is enabled. A gate has no process of its own, so
# its row carries its member list instead of a PID or restart count and
# counts as running only when every one of its members is... a gate with a
# dead member reads as not running, which is the honest answer given a
# command through it would only partly land.
#
# Returns a hash ref keyed by kur name. A real kur's value is
# { running => 1|0, pid => PID or undef, restarts => N, enabled => 1|0 } and
# a gate's is { fan_out => [ names ], running => 1|0, enabled => 1|0 }. The
# presence of a fan_out key is how callers tell the two apart, which is what
# _cmd_status_all filters on before deciding who to ask for more.
#
#     my $kurs = $self->_kur_summary;
#     # { sshd     => { running => 1, pid => 4242, restarts => 0, enabled => 1 },
#     #   baphomet => { fan_out => ['sshd','smtp'], running => 1, enabled => 1 } }
sub _kur_summary {
	my ($self) = @_;

	my $kurs = {};
	foreach my $name ( keys( %{ $self->{kurs} } ) ) {
		my $entry = $self->{kurs}{$name};
		# a fan_out kur has no process of its own... it counts as running
		# when every member is
		if ( defined( $entry->{opts}{fan_out} ) ) {
			my $running = 1;
			foreach my $member ( @{ $entry->{opts}{fan_out} } ) {
				if ( !defined( $self->{kurs}{$member} ) || !defined( $self->{kurs}{$member}{pid} ) ) {
					$running = 0;
					last;
				}
			}
			$kurs->{$name} = {
				'fan_out' => $entry->{opts}{fan_out},
				'running' => $running,
				'enabled' => $entry->{enabled} ? 1 : 0,
			};
			next;
		} ## end if ( defined( $entry->{opts}{fan_out} ) )
		$kurs->{$name} = {
			'running'  => defined( $entry->{pid} ) ? 1 : 0,
			'pid'      => $entry->{pid},
			'restarts' => $entry->{restarts},
			'enabled'  => $entry->{enabled} ? 1 : 0,
		};
	} ## end foreach my $name ( keys( %{ $self->{kurs} } ) )

	return $kurs;
} ## end sub _kur_summary

# Handles the status command... the manager's own info plus the bare summary
# row for each kur, without asking any kur process anything. That is what
# makes it the cheap view and the one to reach for when something has gone
# quiet, as it answers from the registry alone and so cannot be held up by a
# kur that will not talk.
#
# Takes only the invocant. Authorization is not done here... the dispatch
# entry in start_server has already run _authorize with no kur names, this
# being a manager level view.
#
# Returns a hash ref carrying the manager's pid, its uptime in seconds since
# start_server finished coming up, the config path it was loaded from,
# enable_auth as 1 or 0, and kurs holding whatever _kur_summary built.
#
#     my $status = $self->_cmd_status;
#     # { pid => 1234, uptime => 3600, config => '/usr/local/etc/ereshkigal.toml',
#     #   enable_auth => 0, kurs => { sshd => { running => 1, ... } } }
sub _cmd_status {
	my ($self) = @_;

	return {
		'pid'         => $$,
		'uptime'      => time - $self->{started},
		'config'      => $self->{config},
		'enable_auth' => $self->{enable_auth} ? 1 : 0,
		'kurs'        => $self->_kur_summary,
	};
} ## end sub _cmd_status

# Handles the status_all command... _cmd_status with each running real kur
# additionally asked for its own status, which is where ban counts, the next
# expiry, the CIDR flags, per instance stats, and what unbans are still owed
# to the firewall come from. Those live kur side, so the only way to have
# them is to ask.
#
# Takes only the invocant. Only running real kurs are asked... a stopped one
# has nothing to answer with and stays a bare summary row, and a gate has no
# socket of its own, its members being asked in their own right anyway.
#
# A kur that is running but will not answer has its failure reported under a
# error key on its row rather than a status one, which is the same shape
# _cmd_status_kur uses, so a consumer checks one place for either view.
#
# Returns the same hash ref shape _cmd_status does, with each asked kur's row
# gaining either a status key holding that kur's whole status hash or an error
# key holding why it could not be had.
#
#     my $status = $self->_cmd_status_all;
#     # $status->{kurs}{sshd}{status}{banned_count} is 12
#     # $status->{kurs}{smtp}{error} is 'timed out after 30 seconds'
sub _cmd_status_all {
	my ($self) = @_;

	my $status = $self->_cmd_status;

	# only the running real ones... a not running kur stays a bare summary
	# row and a fan_out kur has no socket to ask
	my @running = grep { $status->{kurs}{$_}{running} && !defined( $status->{kurs}{$_}{fan_out} ) }
		sort( keys( %{ $status->{kurs} } ) );
	my $answers = $self->_fan_out( \@running, 'status' );
	foreach my $name (@running) {
		if ( defined( $answers->{$name}{error} ) ) {
			$status->{kurs}{$name}{error} = $answers->{$name}{error};
		} else {
			$status->{kurs}{$name}{status} = $answers->{$name};
		}
	}

	return $status;
} ## end sub _cmd_status_all

# Handles the status_kur command... the summary row for the kur named by
# args.name plus its own status when running, or the member list plus each
# member's status when it is a gate.
#
# Note the ordering... the name is authorized before the registry is
# consulted, so a caller who is not entitled to a kur cannot tell a refusal
# from a nonexistent name and so cannot use the difference to enumerate what
# the manager is carrying. Every targeted command handler does this.
#
# A running kur is asked through _fan_out rather than a bare client call, so
# a live process with a wedged socket degrades to an error entry rather than
# dying the whole command, and that error is reported under an error key
# beside status rather than nested inside it... the same shape
# _cmd_status_all uses.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry an args
#                 key holding a hash ref with a name key naming the kur, as a
#                 plain string. A missing args or name dies.
#     $ctx     :: The JSONUnix context for the connection, handed to
#                 _authorize. May be undef when enable_auth is off, as
#                 _authorize returns before touching it.
#
# Returns, for a real kur, a hash ref of { name, running, pid, restarts,
# enabled }, gaining either a status key holding that kur's full status hash
# or an error key when it is running but could not be reached. For a gate it
# is { name, fan_out => [ members ], enabled, kurs => { per member } }, with
# no running or pid of its own.
#
# Dies with a plain string when args.name is missing or names no registered
# kur. Authorization failures die with the { error, code } hash ref
# _authorize raises, code being 'permission_denied'.
#
#     my $status = $self->_cmd_status_kur( { 'args' => { 'name' => 'sshd' } }, $ctx );
#     # { name => 'sshd', running => 1, pid => 4242, restarts => 0,
#     #   enabled => 1, status => { backend => 'pf', banned_count => 12, ... } }
sub _cmd_status_kur {
	my ( $self, $request, $ctx ) = @_;

	my $args = $request->{args};
	if ( !defined($args) || !defined( $args->{name} ) ) {
		die('args.name must be the name of a kur instance');
	}
	my $name = $args->{name};

	# authorized before existence is checked, so an unauthorized caller can
	# not use the difference in errors to enumerate kur names
	$self->_authorize( $ctx, $name );

	my $entry = $self->{kurs}{$name};
	if ( !defined($entry) ) {
		die( 'No such kur instance, "' . $name . '"' );
	}

	# a fan_out kur has no process of its own, so its status is its
	# member list plus each member's status
	if ( defined( $entry->{opts}{fan_out} ) ) {
		return {
			'name'    => $name,
			'fan_out' => $entry->{opts}{fan_out},
			'enabled' => $entry->{enabled} ? 1 : 0,
			'kurs'    => $self->_fan_out( $entry->{opts}{fan_out}, 'status' ),
		};
	}

	my $status = {
		'name'     => $name,
		'running'  => defined( $entry->{pid} ) ? 1 : 0,
		'pid'      => $entry->{pid},
		'restarts' => $entry->{restarts},
		'enabled'  => $entry->{enabled} ? 1 : 0,
	};

	if ( $status->{running} ) {
		# via _fan_out rather than a bare call_ok so a live process with a
		# wedged socket degrades to an error entry, reported under the same
		# error key status_all uses rather than nested inside status
		my $answer = $self->_fan_out( [$name], 'status' )->{$name};
		if ( defined( $answer->{error} ) ) {
			$status->{error} = $answer->{error};
		} else {
			$status->{status} = $answer;
		}
	} ## end if ( $status->{running} )

	return $status;
} ## end sub _cmd_status_kur

# Handles the banned command... fans banned out to every real kur and trims
# each successful answer down to the fields this view is about, dropping
# anything else the kur happened to include.
#
# Takes only the invocant. Authorization has already been done by the
# dispatch entry, against every real kur, this being an untargeted command.
# Gates are not asked, _real_kur_names excluding them, as their members are
# each asked in their own right.
#
# The trimming is an explicit whitelist rather than a passthrough, so any
# field a kur learns to report has to be added here as well or it will never
# reach a consumer... the retry books are in the list for exactly that
# reason, having once been dropped on the way out.
#
# A kur that could not be reached keeps its { error => ... } row untouched,
# the trimming only applying to successful answers.
#
# Returns a hash ref of { kurs => { name => row } }. A successful row carries
# banned as an array ref of the IPs the firewall itself reports, expires as a
# hash ref of IP to the epoch its sentence ends with 0 meaning never, the
# same pair as banned_cidr and cidr_expires for ranges, and unban_retries and
# cidr_unban_retries as hash refs of entry to its retry book keeping. A
# failed row is { error => '...' }.
#
#     my $result = $self->_cmd_banned;
#     # { kurs => { sshd => { banned => ['1.2.3.4'],
#     #                       expires => { '1.2.3.4' => 1785919052 },
#     #                       banned_cidr => [], cidr_expires => {},
#     #                       unban_retries => {}, cidr_unban_retries => {} } } }
sub _cmd_banned {
	my ($self) = @_;

	my $kurs = $self->_fan_out( [ $self->_real_kur_names ], 'banned' );
	foreach my $name ( keys( %{$kurs} ) ) {
		if ( !defined( $kurs->{$name}{error} ) ) {
			$kurs->{$name} = {
				'banned'             => $kurs->{$name}{banned},
				'expires'            => $kurs->{$name}{expires},
				'banned_cidr'        => $kurs->{$name}{banned_cidr},
				'cidr_expires'       => $kurs->{$name}{cidr_expires},
				'unban_retries'      => $kurs->{$name}{unban_retries},
				'cidr_unban_retries' => $kurs->{$name}{cidr_unban_retries},
			};
		} ## end if ( !defined( $kurs->{$name}{error} ) )
	} ## end foreach my $name ( keys( %{$kurs} ) )

	return { 'kurs' => $kurs };
} ## end sub _cmd_banned

# Handles the ban command... fans args.ips out to the targeted kurs. All of
# the shared validate, authorize, and fan out work lives in _cmd_ban_common,
# this being nothing but the single IP half of the spec that tells it apart
# from the CIDR one.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding an ips key with an array ref of one or more IPs, and
#                 may carry a kur key naming one kur or gate to send them to
#                 and a ban_time key overriding how long they last. See
#                 _cmd_ban_common, which does the judging.
#     $ctx     :: The JSONUnix context, handed through to _authorize. May be
#                 undef when enable_auth is off.
#
# Returns whatever _cmd_ban_common returns... a hash ref of
# { kurs => { name => per kur result } } plus a rejected key when any of the
# IPs would not validate.
#
# Dies as _cmd_ban_common does... a plain string for a bad request or a
# unknown kur, or the { error, code } hash ref from _authorize for a refusal.
#
#     my $result = $self->_cmd_ban(
#         { 'args' => { 'ips' => ['1.2.3.4'], 'kur' => 'sshd' } }, $ctx );
sub _cmd_ban {
	my ( $self, $request, $ctx ) = @_;

	return $self->_cmd_ban_common(
		$request, $ctx,
		{
			'arg_key'    => 'ips',
			'noun'       => 'IP',
			'noun_long'  => 'IPv4 or IPv6 IP',
			'normalizer' => \&normalize_ip,
			'command'    => 'ban',
		}
	);
} ## end sub _cmd_ban

# Handles the unban command... args.all set fans flush out to every real kur,
# otherwise args.ip is normalized and unban fanned out instead.
#
# There is deliberately no kur targeting here, unlike ban... an unban goes
# wherever the address actually is, every real kur being asked whether it is
# holding it and releasing it if so. That is why the per kur answers carry
# was_banned rather than a plain success, and why a kur that never had the IP
# is not an error.
#
# The all form is a flush rather than a mass unban, so it empties range bans
# alongside single IPs on every kur in one command.
#
# Note this takes no context and does no authorizing of its own... the
# dispatch entry in start_server has already authorized against every real
# kur before calling, this being untargeted either way.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding either a true all key or an ip key with a single
#                 IPv4 or IPv6 address as a plain string. Neither one dies.
#                 The IP is normalized here rather than kur side, so garbage
#                 is bounced once instead of by every kur, and what is fanned
#                 out is the canonical form... which is what lets a variant
#                 spelling of an IPv6 address still find its ban.
#
# Returns a hash ref of { kurs => { name => per kur result } }. For the all
# form each result is that kur's flush answer, { flushed => 1 }; for a single
# IP it is { ip => '...', was_banned => 1|0 }. Unreachable kurs are
# { error => '...' } as always.
#
# Dies with a plain string when neither args.all nor args.ip is given, or
# when args.ip will not normalize as an IP.
#
#     my $result = $self->_cmd_unban( { 'args' => { 'ip' => '1.2.3.4' } } );
#     # { kurs => { sshd => { ip => '1.2.3.4', was_banned => 1 },
#     #             smtp => { ip => '1.2.3.4', was_banned => 0 } } }
#
#     my $result = $self->_cmd_unban( { 'args' => { 'all' => 1 } } );
#     # { kurs => { sshd => { flushed => 1 }, smtp => { flushed => 1 } } }
sub _cmd_unban {
	my ( $self, $request ) = @_;

	my $args = $request->{args};
	if ( !defined($args) || ( !$args->{all} && !defined( $args->{ip} ) ) ) {
		die('Either args.all must be true or args.ip must be an IP');
	}

	my @all = $self->_real_kur_names;
	my $kurs;
	if ( $args->{all} ) {
		$kurs = $self->_fan_out( \@all, 'flush' );
	} else {
		# bounce garbage here instead of fanning it out just for every kur
		# to report it absent, and fan out the canonical form so variant
		# spellings of the same IP all find the ban
		my $ip = normalize_ip( $args->{ip} );
		if ( !defined($ip) ) {
			die( '"' . $args->{ip} . '" does not appear to be an IPv4 or IPv6 IP' );
		}
		# the kur checks if the IP is present and only unbans it if it is,
		# reporting back via was_banned
		$kurs = $self->_fan_out( \@all, 'unban', { 'ip' => $ip } );
	} ## end else [ if ( $args->{all} ) ]

	return { 'kurs' => $kurs };
} ## end sub _cmd_unban

# The CIDR twin of _cmd_ban... fans args.cidrs out to the targeted kurs, all
# of the shared validate, authorize, and fan out work living in
# _cmd_ban_common. Only the spec differs... the args key, the normalizer, the
# kur command, and the noun used in error messages.
#
# Whether a given kur will actually act on it is not decided here. A kur with
# CIDR banning off, or on a backend that cannot match a prefix, either
# refuses or silently drops per its own cidr_silent_drop setting, and that
# answer comes back in its row like any other.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding a cidrs key with an array ref of one or more ranges,
#                 and may carry kur and ban_time exactly as ban does. Host
#                 bits are masked off during pre-flight, so 1.2.3.4/24 and
#                 1.2.3.0/24 are the same range and dedupe against each other.
#     $ctx     :: The JSONUnix context, handed through to _authorize. May be
#                 undef when enable_auth is off.
#
# Returns whatever _cmd_ban_common returns... { kurs => { name => result } }
# plus a rejected key when any of the ranges would not validate.
#
# Dies as _cmd_ban_common does... a plain string for a bad request or unknown
# kur, or the { error, code } hash ref from _authorize.
#
#     my $result = $self->_cmd_cidr_ban(
#         { 'args' => { 'cidrs' => ['1.2.3.0/24'], 'ban_time' => 0 } }, $ctx );
sub _cmd_cidr_ban {
	my ( $self, $request, $ctx ) = @_;

	return $self->_cmd_ban_common(
		$request, $ctx,
		{
			'arg_key'    => 'cidrs',
			'noun'       => 'CIDR',
			'noun_long'  => 'IPv4 or IPv6 CIDR',
			'normalizer' => \&normalize_cidr,
			'command'    => 'cidr_ban',
		}
	);
} ## end sub _cmd_cidr_ban

# The shared body of _cmd_ban and _cmd_cidr_ban, which differ only in the
# args key, the normalizer, the kur command, and the noun used in errors.
#
# The ordering here is deliberate and worth keeping. Targets are resolved and
# authorization checked before anything is done with the payload, so a caller
# who is not entitled can neither enumerate kur names nor make the manager
# burn cycles validating a list it is never going to send. Within that, a
# named kur is authorized against the name as given rather than what it
# expands to, which is what makes a gate grant cover its members; and a
# untargeted command authorizes before reporting that there are no kurs, so
# a refusal never leaks whether the manager is carrying anything.
#
# Entries are then pre-flighted... each is normalized, garbage collected into
# a rejected hash rather than being fanned out for every kur to bounce
# separately, and duplicates dropped. Normalizing here also means variant
# spellings of one address dedupe against each other and what reaches the
# kurs is canonical. A request where nothing at all survives is a die rather
# than a fan out of nothing.
#
# Args, all required and positional...
#
#     $request :: The decoded request hash ref. Must carry args holding the
#                 spec's arg_key with an array ref of one or more entries. May
#                 also carry kur, naming one kur or gate rather than all of
#                 them, and ban_time, an override in seconds passed through
#                 unvalidated for the kur to judge, 0 meaning never expire.
#     $ctx     :: The JSONUnix context for the connection, handed to
#                 _authorize. May be undef when enable_auth is off.
#     $spec    :: A hash ref of the per family knobs, which is how the two
#                 callers differ. Every key is required...
#                   arg_key    :: the args key holding the entries, 'ips' or
#                                 'cidrs'
#                   noun       :: the short noun for errors, 'IP' or 'CIDR'
#                   noun_long  :: the long one, 'IPv4 or IPv6 IP' or the CIDR
#                                 equivalent
#                   normalizer :: a code ref taking a raw entry and returning
#                                 its canonical form or undef, so normalize_ip
#                                 or normalize_cidr
#                   command    :: the command name to fan out, 'ban' or
#                                 'cidr_ban'
#
# Returns a hash ref carrying kurs, a hash ref of kur name to that kur's
# per entry results, and, only when something was refused during pre-flight,
# rejected, a hash ref of the raw entry to
# { status => 'error', error => '...' }. The rejected key being absent is how
# a caller knows every entry it sent was at least well formed.
#
# Dies with a plain string when args or the entry array is missing or empty,
# when a named kur is not registered, or when not one entry validated.
# Authorization failures die with _authorize's { error, code } hash ref.
#
#     my $result = $self->_cmd_ban_common(
#         $request, $ctx,
#         {
#             'arg_key'    => 'ips',
#             'noun'       => 'IP',
#             'noun_long'  => 'IPv4 or IPv6 IP',
#             'normalizer' => \&normalize_ip,
#             'command'    => 'ban',
#         }
#     );
#     # { kurs => { sshd => { ips => { '1.2.3.4' => { status => 'ok' } } } },
#     #   rejected => { 'nope' => { status => 'error', error => '...' } } }
sub _cmd_ban_common {
	my ( $self, $request, $ctx, $spec ) = @_;

	my $args    = $request->{args};
	my $arg_key = $spec->{arg_key};
	if ( !defined($args) || ref( $args->{$arg_key} ) ne 'ARRAY' || !@{ $args->{$arg_key} } ) {
		die( 'args.' . $arg_key . ' must be an array of one or more ' . $spec->{noun} . 's' );
	}

	# targets are resolved and authorization checked before anything is done
	# with the payload, so an unauthorized caller can neither enumerate kur
	# names nor burn cycles on validation
	my @targets;
	if ( defined( $args->{kur} ) ) {
		# authorization is checked against the requested name... for a
		# fan_out kur being authorized for the gateway is the grant, which
		# is what makes one usable as a single point of contact
		$self->_authorize( $ctx, $args->{kur} );
		if ( !defined( $self->{kurs}{ $args->{kur} } ) ) {
			die( 'No such kur instance, "' . $args->{kur} . '"' );
		}
		@targets = $self->_expand_kur_targets( $args->{kur} );
	} else {
		@targets = $self->_real_kur_names;
		# authorized before the empty check, matching every other untargeted
		# command... with zero real kurs this is the manager level check, so
		# an unauthorized caller is refused rather than being told what the
		# manager is carrying
		$self->_authorize( $ctx, @targets );
		if ( !@targets ) {
			die('No kur instances');
		}
	} ## end else [ if ( defined( $args->{kur} ) ) ]

	# ban_time is pre-flighted for the same reason the entries below are...
	# every kur would otherwise judge it separately and answer with the same
	# error, so a single bad value comes back N times rather than once. The
	# check matches the kur's own in Ereshkigal::Kur::_resolve_ban_time, which
	# still runs and is still the authority for anything reaching a kur by
	# another route
	if ( defined( $args->{ban_time} )
		&& ( ref( $args->{ban_time} ) ne '' || $args->{ban_time} !~ /^[0-9]+$/ ) )
	{
		die('args.ban_time must be a non-negative int of seconds');
	}

	# pre-flight the entries so garbage is bounced here instead of being
	# fanned out just for every kur to bounce it, and so what is fanned out
	# is the canonical form... variant spellings also dedupe here
	my @entries;
	my %seen;
	my $rejected = {};
	foreach my $raw_entry ( @{ $args->{$arg_key} } ) {
		my $entry = $spec->{normalizer}->($raw_entry);
		if ( !defined($entry) ) {
			my $key = defined($raw_entry) ? $raw_entry : '';
			$rejected->{$key}
				= { 'status' => 'error', 'error' => '"' . $key . '" does not appear to be an ' . $spec->{noun_long} };
			next;
		}
		if ( !$seen{$entry} ) {
			$seen{$entry} = 1;
			push( @entries, $entry );
		}
	} ## end foreach my $raw_entry ( @{ $args->{$arg_key} } )
	if ( !@entries ) {
		die( 'None of the ' . $spec->{noun} . 's in args.' . $arg_key . ' appear to be an ' . $spec->{noun_long} );
	}

	my $kur_args = { $arg_key => \@entries };
	if ( defined( $args->{ban_time} ) ) {
		$kur_args->{ban_time} = $args->{ban_time};
	}

	my $response = { 'kurs' => $self->_fan_out( \@targets, $spec->{command}, $kur_args ) };
	if ( %{$rejected} ) {
		$response->{rejected} = $rejected;
	}

	return $response;
} ## end sub _cmd_ban_common

# The CIDR twin of _cmd_unban, minus the all form... args.cidr is normalized
# and cidr_unban fanned out to every real kur. There is no all here because
# unban --all already flushes ranges alongside single IPs, so a second way to
# empty everything would only be a second way to get it wrong.
#
# As with unban there is no kur targeting... every real kur is asked whether
# it holds the range and releases it if so. Host bits are masked off during
# normalization, so naming any address inside a banned network finds it.
#
# Takes no context and authorizes nothing itself... the dispatch entry has
# already authorized against every real kur.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding a cidr key with a single range as a plain string,
#                 such as '1.2.3.0/24'. Normalized here rather than kur side
#                 so garbage is bounced once and what is fanned out is the
#                 canonical network form.
#
# Returns a hash ref of { kurs => { name => per kur result } }, each result
# being { cidr => '...', was_banned => 1|0 }, or { error => '...' } for a kur
# that could not be reached.
#
# Dies with a plain string when args.cidr is missing or will not normalize.
#
#     my $result = $self->_cmd_cidr_unban( { 'args' => { 'cidr' => '1.2.3.4/24' } } );
#     # { kurs => { sshd => { cidr => '1.2.3.0/24', was_banned => 1 } } }
sub _cmd_cidr_unban {
	my ( $self, $request ) = @_;

	my $args = $request->{args};
	if ( !defined($args) || !defined( $args->{cidr} ) ) {
		die('args.cidr must be a CIDR');
	}

	# bounce garbage here instead of fanning it out just for every kur to
	# report it absent, and fan out the canonical network form so variant
	# spellings of the same range all find the ban
	my $cidr = normalize_cidr( $args->{cidr} );
	if ( !defined($cidr) ) {
		die( '"' . $args->{cidr} . '" does not appear to be an IPv4 or IPv6 CIDR' );
	}

	# the kur checks if the CIDR is present and only unbans it if it is,
	# reporting back via was_banned
	my $kurs = $self->_fan_out( [ $self->_real_kur_names ], 'cidr_unban', { 'cidr' => $cidr } );

	return { 'kurs' => $kurs };
} ## end sub _cmd_cidr_unban

# Handles the checkpoint command... fans checkpoint out to the kurs behind
# args.kur when given, or every real kur otherwise, having each write its
# tablets to disk now rather than waiting for its next mutation or interval.
#
# Authorization follows the same pattern every targeted command uses... a
# named kur is authorized against the name as given, before the registry is
# consulted, so a gate grant covers the fanned command and kur names cannot
# be enumerated by the difference between a refusal and an unknown name. The
# untargeted form authorizes against every real kur, which with none
# registered is the manager level check.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. args is optional
#                 here, and when present may carry a kur key naming one kur
#                 or gate. With no args, or no kur key, every real kur is
#                 checkpointed.
#     $ctx     :: The JSONUnix context, handed to _authorize. May be undef
#                 when enable_auth is off.
#
# Returns a hash ref of { kurs => { name => per kur result } }, each result
# being that kur's checkpoint answer... { checkpointed => 1, bans => N,
# cidr_bans => N, unban_retries => N, cidr_unban_retries => N }, or
# { error => '...' } for one that could not be reached.
#
# Dies with a plain string when args.kur names no registered kur, or with
# _authorize's { error, code } hash ref on a refusal.
#
#     my $result = $self->_cmd_checkpoint( {}, $ctx );                     # all
#     my $result = $self->_cmd_checkpoint( { 'args' => { 'kur' => 'sshd' } }, $ctx );
sub _cmd_checkpoint {
	my ( $self, $request, $ctx ) = @_;

	my $args = $request->{args};

	my @targets;
	if ( defined($args) && defined( $args->{kur} ) ) {
		# like ban, authorization is against the requested name, so a
		# fan_out kur grant covers the fanned command... and it comes before
		# the existence check so kur names cannot be enumerated
		$self->_authorize( $ctx, $args->{kur} );
		if ( !defined( $self->{kurs}{ $args->{kur} } ) ) {
			die( 'No such kur instance, "' . $args->{kur} . '"' );
		}
		@targets = $self->_expand_kur_targets( $args->{kur} );
	} else {
		@targets = $self->_real_kur_names;
		$self->_authorize( $ctx, @targets );
	}

	return { 'kurs' => $self->_fan_out( \@targets, 'checkpoint' ) };
} ## end sub _cmd_checkpoint

# Handles the re_init command... fans re_init out the same way checkpoint
# does, having the kurs tear their firewall setup down and rebuild it from
# what their ban books carry. This is the repair for a setup something
# outside Ereshkigal has interfered with, a firewall reload or a flushed
# table having taken the rules with it.
#
# Worth knowing what it costs... bans are not enforced during the rebuild,
# brief as that window is, so it is not something to fan at every kur on a
# busy edge without meaning to. It also settles any unban debts, tearing down
# taking with it whatever rule a failed unban left behind.
#
# Authorization and targeting are exactly checkpoint's, down to authorizing a
# named kur before the registry is consulted.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. args is optional,
#                 and when present may carry a kur key naming one kur or
#                 gate. With no args, or no kur key, every real kur rebuilds.
#     $ctx     :: The JSONUnix context, handed to _authorize. May be undef
#                 when enable_auth is off.
#
# Returns a hash ref of { kurs => { name => per kur result } }, each result
# being { re_init => 1 } on success or { error => '...' } for a kur that
# could not be reached or whose rebuild failed.
#
# Dies with a plain string when args.kur names no registered kur, or with
# _authorize's { error, code } hash ref on a refusal.
#
#     my $result = $self->_cmd_re_init( { 'args' => { 'kur' => 'sshd' } }, $ctx );
#     # { kurs => { sshd => { re_init => 1 } } }
sub _cmd_re_init {
	my ( $self, $request, $ctx ) = @_;

	my $args = $request->{args};

	my @targets;
	if ( defined($args) && defined( $args->{kur} ) ) {
		# as with checkpoint, authorization is against the requested name so
		# a fan_out grant covers the fanned command, and it comes before the
		# existence check so kur names cannot be enumerated
		$self->_authorize( $ctx, $args->{kur} );
		if ( !defined( $self->{kurs}{ $args->{kur} } ) ) {
			die( 'No such kur instance, "' . $args->{kur} . '"' );
		}
		@targets = $self->_expand_kur_targets( $args->{kur} );
	} else {
		@targets = $self->_real_kur_names;
		$self->_authorize( $ctx, @targets );
	}

	return { 'kurs' => $self->_fan_out( \@targets, 're_init' ) };
} ## end sub _cmd_re_init

# Handles the clear_retries command... fans it out the same way checkpoint
# does, passing along the optional args.ip or args.cidr naming a single owed
# unban to forget rather than the lot.
#
# What is being forgotten is book keeping only. When a ban's sentence runs
# out but the backend refuses the unban, the kur drops it from its ban book
# and keeps owing the firewall the removal, retrying with a backoff. This
# forgets that debt. Nothing is sent to the firewall, so a rule that really
# is still in place is left with nothing tracking it... which is why the CLI
# help is emphatic about checking first.
#
# The address is validated and canonicalized here as well as kur side, so
# garbage is bounced once rather than by every kur it would have been fanned
# to, and what goes out is the form the retry tablets are actually keyed by.
#
# Authorization and targeting are checkpoint's again.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. args is optional
#                 and may carry any of... kur, naming one kur or gate rather
#                 than all of them; ip, a single IPv4 or IPv6 address whose
#                 debt to forget; cidr, the range equivalent. ip and cidr are
#                 mutually exclusive. With neither, every debt the targeted
#                 kurs carry is forgotten.
#     $ctx     :: The JSONUnix context, handed to _authorize. May be undef
#                 when enable_auth is off.
#
# Returns a hash ref of { kurs => { name => per kur result } }, each result
# being { cleared => N, cleared_ip => N, cleared_cidr => N } counting what
# that kur actually forgot, or { error => '...' } for one that could not be
# reached. Forgetting something that was not owed is not an error... it simply
# counts zero.
#
# Dies with a plain string when both args.ip and args.cidr are given, when
# either will not normalize, or when args.kur names no registered kur.
# Authorization failures die with _authorize's { error, code } hash ref.
#
#     my $result = $self->_cmd_clear_retries( {}, $ctx );   # every debt, every kur
#
#     my $result = $self->_cmd_clear_retries(
#         { 'args' => { 'kur' => 'sshd', 'ip' => '1.2.3.4' } }, $ctx );
#     # { kurs => { sshd => { cleared => 1, cleared_ip => 1, cleared_cidr => 0 } } }
sub _cmd_clear_retries {
	my ( $self, $request, $ctx ) = @_;

	my $args = defined( $request->{args} ) ? $request->{args} : {};

	if ( defined( $args->{ip} ) && defined( $args->{cidr} ) ) {
		die('only one of args.ip and args.cidr may be given');
	}

	# validated and canonicalized here as well as kur side, so garbage is
	# bounced once rather than by each kur it would have been fanned out to,
	# and what is fanned out is the form the retry tablets are keyed by
	my $fan_args = {};
	if ( defined( $args->{ip} ) ) {
		my $ip = normalize_ip( $args->{ip} );
		if ( !defined($ip) ) {
			die( '"' . $args->{ip} . '" does not appear to be an IPv4 or IPv6 IP' );
		}
		$fan_args->{ip} = $ip;
	}
	if ( defined( $args->{cidr} ) ) {
		my $cidr = normalize_cidr( $args->{cidr} );
		if ( !defined($cidr) ) {
			die( '"' . $args->{cidr} . '" does not appear to be an IPv4 or IPv6 CIDR' );
		}
		$fan_args->{cidr} = $cidr;
	}

	my @targets;
	if ( defined( $args->{kur} ) ) {
		# as with checkpoint, authorization is against the requested name so
		# a fan_out grant covers the fanned command, and it comes before the
		# existence check so kur names cannot be enumerated
		$self->_authorize( $ctx, $args->{kur} );
		if ( !defined( $self->{kurs}{ $args->{kur} } ) ) {
			die( 'No such kur instance, "' . $args->{kur} . '"' );
		}
		@targets = $self->_expand_kur_targets( $args->{kur} );
	} else {
		@targets = $self->_real_kur_names;
		$self->_authorize( $ctx, @targets );
	}

	return { 'kurs' => $self->_fan_out( \@targets, 'clear_retries', %{$fan_args} ? $fan_args : undef ) };
} ## end sub _cmd_clear_retries

# Handles the add_kur command... validates the definition in args.opts the
# same way config load would, registers it under args.name, and has the
# manager session spawn it.
#
# The definition is run through the same _check_kur_def and, for a gate,
# _check_fan_out_members the config path uses, with perror off so a bad
# definition is an error response rather than a dead manager. That parity is
# the point... a kur added at runtime is held to exactly the rules one from
# the config is.
#
# The config file is not rewritten, so a kur added this way is gone at the
# next manager start unless it is also added to the config by hand.
#
# The spawn is posted to the manager session rather than done here, as the
# POE::Wheel::Run has to be created in the session that will watch it, and
# the registry entry is seeded with the same shape config load builds so the
# supervision machinery finds what it expects... a fresh restart count, a
# backoff delay of 1, and enabled set.
#
# Note this takes no context and authorizes nothing of its own... the
# dispatch entry has already run _authorize with no kur names, adding a kur
# being a manager level act.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding a name key, the new kur's name as a plain string,
#                 and an opts key holding its definition hash ref, which
#                 takes the same keys a config kur hash does... backend or
#                 fan_out, ports, protocols, prefix, self_heal, ban_time,
#                 checkpoint, enable_cidr, cidr_silent_drop, options,
#                 authed_users, authed_groups.
#
# Returns a hash ref of { added => name } once it is registered and the spawn
# posted. That is not a promise the process came up... it is a promise the
# manager will try, status being where to look for whether it did.
#
# Dies with a plain string when args.name is missing, when that name is
# already registered, or with whatever _check_kur_def or
# _check_fan_out_members raised about the definition.
#
#     my $result = $self->_cmd_add_kur(
#         {
#             'args' => {
#                 'name' => 'dns',
#                 'opts' => { 'backend' => 'pf', 'ports' => ['53'] },
#             }
#         }
#     );
#     # { added => 'dns' }
sub _cmd_add_kur {
	my ( $self, $request ) = @_;

	my $args = $request->{args};
	if ( !defined($args) || !defined( $args->{name} ) ) {
		die('args.name must be the name for the new kur instance');
	}
	my $name = $args->{name};

	if ( defined( $self->{kurs}{$name} ) ) {
		die( 'The kur instance "' . $name . '" already exists' );
	}

	$self->_check_kur_def( $name, $args->{opts}, 0 );
	if ( defined( $args->{opts}{fan_out} ) ) {
		$self->_check_fan_out_members( $name, $args->{opts}, 0 );
	}

	$self->{kurs}{$name} = {
		'opts'     => $args->{opts},
		'wheel'    => undef,
		'pid'      => undef,
		'restarts' => 0,
		'delay'    => 1,
		'enabled'  => 1,
		'spawned'  => undef,
	};

	$poe_kernel->post( 'ereshkigal_manager', 'spawn_kur', $name );

	log_drek( 'info', 'added kur "' . $name . '"' );

	return { 'added' => $name };
} ## end sub _cmd_add_kur

# Handles the remove_kur command... refuses while args.name is still a
# fan_out member, otherwise disables it and has the manager session stop and
# drop it.
#
# The gate check is why this is not simply a post. Config load refuses a
# fan_out naming an unknown kur, so removal cannot be allowed to create that
# same dangling state at runtime... every registered kur is scanned for gates
# naming this one, and if any do the removal is refused naming them. Remove
# the gate first, or the member stays.
#
# Setting enabled to 0 before posting matters as well... it is what stops the
# reap handler restarting the kur when the stop it is about to be sent
# actually kills it.
#
# The real work is left to the manager session, as a POE::Wheel::Run must be
# destroyed in the session watching it or its watchers outlive it and keep
# the session alive forever.
#
# The config file is not rewritten, so a kur defined there returns at the
# next manager start.
#
# Note this takes no context and authorizes nothing of its own... the
# dispatch entry has already run _authorize with no kur names.
#
# Args...
#
#     $request :: Required. The decoded request hash ref. Must carry args
#                 holding a name key naming the kur to remove, as a plain
#                 string.
#
# Returns a hash ref of { removed => name } once it is disabled and the
# removal posted. As with add_kur that is a promise the manager will do it,
# not that the process is already gone.
#
# Dies with a plain string when args.name is missing, names no registered
# kur, or is still a member of one or more gates, which names them.
#
#     my $result = $self->_cmd_remove_kur( { 'args' => { 'name' => 'dns' } } );
#     # { removed => 'dns' }
sub _cmd_remove_kur {
	my ( $self, $request ) = @_;

	my $args = $request->{args};
	if ( !defined($args) || !defined( $args->{name} ) ) {
		die('args.name must be the name of a kur instance');
	}
	my $name = $args->{name};

	my $entry = $self->{kurs}{$name};
	if ( !defined($entry) ) {
		die( 'No such kur instance, "' . $name . '"' );
	}

	# config load refuses a fan_out naming an unknown kur, so removal cannot
	# be allowed to create that same dangling state at runtime... remove the
	# gate first, or the member stays
	my @gates_using;
	foreach my $other_name ( sort( keys( %{ $self->{kurs} } ) ) ) {
		my $fan_out = $self->{kurs}{$other_name}{opts}{fan_out};
		if ( defined($fan_out) && grep { $_ eq $name } @{$fan_out} ) {
			push( @gates_using, $other_name );
		}
	}
	if (@gates_using) {
		die(      'The kur "'
				. $name
				. '" is a fan_out member of "'
				. join( '", "', @gates_using )
				. '"... remove the fan_out kur first' );
	}

	$entry->{enabled} = 0;

	# the actual stop and removal happens in the manager session given the
	# wheel has to be destroyed there
	$poe_kernel->post( 'ereshkigal_manager', 'remove_kur', $name );

	return { 'removed' => $name };
} ## end sub _cmd_remove_kur

=head1 ERROR CODES / ERROR FLAGS

Error handling is provided by L<Error::Helper>. All errors
are considered fatal.

=head2 1, configReadFailed

Failed to read the config file.

=head2 2, configParseFailed

Failed to parse the config file as TOML.

=head2 3, invalidKurDef

A kur def in the config is invalid... bad name, not a hash, lacking a
backend or a fan_out, having both, an invalid fan_out (not an array of
kur names, an unknown member, or a nested fan_out kur), or an options table
carrying a non-scalar value for anything other than C<interfaces>.

=head2 4, runBaseDirError

The run base dir or the kur dir under it could not be created or is not
read/writable.

=head2 5, badSocketGroup

Failed to resolve the socket group to a GID.

=head2 6, invalidBanTime

ban_time is not a non-negative int of seconds.

=head2 7, invalidCheckpoint

checkpoint is not a non-negative int of seconds.

=head2 8, invalidAuthedList

authed_users or authed_groups is not an array of strings.

=head1 AUTHOR

Zane C. Bowers-Hadley, C<< <vvelox at vvelox.net> >>

=head1 BUGS

Please report any bugs or feature requests via GitHub at
L<https://github.com/LilithSec/Ereshkigal/issues>, or to
C<bug-ereshkigal at rt.cpan.org>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Ereshkigal

You can also look for information at:

=over 4

=item * GitHub (source and issues)

L<https://github.com/LilithSec/Ereshkigal>

=item * RT: CPAN's request tracker

L<https://rt.cpan.org/NoAuth/Bugs.html?Dist=Ereshkigal>

=item * CPAN Ratings

L<https://cpanratings.perl.org/d/Ereshkigal>

=item * Search CPAN

L<https://metacpan.org/release/Ereshkigal>

=back

=head1 LICENSE AND COPYRIGHT

This software is Copyright (c) 2023 by Zane C. Bowers-Hadley.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)


=cut

1;    # End of Ereshkigal
