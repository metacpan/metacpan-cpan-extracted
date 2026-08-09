package Ereshkigal::Kur;

use 5.006;
use strict;
use warnings;
use base 'Error::Helper';
use POE;
use POE::Component::Server::JSONUnix ();
use Net::Firewall::BlockerHelper     ();
use Ereshkigal::LogDrek              qw( log_drek );
use Ereshkigal::IP                   qw( normalize_ip normalize_cidr );

=head1 NAME

Ereshkigal::Kur - FW handler for Ereshkigal.

=head1 VERSION

Version 0.0.1

=cut

our $VERSION = '0.0.1';

=head1 SYNOPSIS

    use Ereshkigal::Kur;

    my $kur = Ereshkigal::Kur->new(
                  'name'      => 'sshd',
                  'backend'   => 'ipfw',
                  'ports'     => ['22'],
                  'protocols' => ['tcp'],
              );

    $kur->start_server;

Each Kur instance wraps a single L<Net::Firewall::BlockerHelper> instance and
serves it up via a L<POE::Component::Server::JSONUnix> server listening on a
unix socket under C<$run_base_dir/kur/>.

=head1 METHODS

=head2 new

Initiates the object. All errors are considered fatal, meaning if new fails
it will die.

    - name :: Name of this specific instance. Must match /^[a-zA-Z0-9\-]+$/.
        Default :: undef

    - backend :: The backend to use for Net::Firewall::BlockerHelper.
        Default :: undef

    - ports :: An array of ports to block, passed to Net::Firewall::BlockerHelper.
        Default :: []

    - protocols :: An array of protocols to block, passed to Net::Firewall::BlockerHelper.
        Default :: []

    - prefix :: Prefix to use, passed to Net::Firewall::BlockerHelper.
        Default :: undef, left for the backend to default to kur

    - options :: Backend specific options hash, passed to Net::Firewall::BlockerHelper.
        Default :: undef, left for the backend to default to {}

    - self_heal :: Self heal setting, passed to Net::Firewall::BlockerHelper.
        Default :: undef, left for the backend to default to 1

    - ban_time :: How long bans should last in seconds. 0 means bans never
          time out. May be overridden per ban request.
        Default :: 600

    - checkpoint :: Seconds between periodic rewrites of the ban state CSV.
          0 disables the periodic rewrite... ban/unban, stop, and on demand
          checkpoints still happen.
        Default :: 60

    - enable_cidr :: Boolean for whether CIDR banning is enabled for this
          instance. Even when set, CIDR commands only work if the backend
          supports CIDR bans. Config files carry strings rather than
          booleans, so the value is folded... undef, the empty string, 0,
          false, no, and off are all off, and anything else at all is on.
        Default :: 0

    - cidr_silent_drop :: Boolean for how a CIDR command is handled when CIDR
          banning is not available for this instance, either because
          enable_cidr is off or the backend does not support it. When set the
          command is silently dropped, returning dropped => 1, rather than
          erroring, which is the point when fanning out to a mix of CIDR
          capable and incapable instances. Folded the same way enable_cidr
          is.
        Default :: 0

    - run_base_dir :: Base dir for run files. The socket and PID for this
          instance live under C<$run_base_dir/kur/> named for this instance.
        Default :: /var/run/ereshkigal

    - cache_base_dir :: Base dir for cache files. The ban state and the
          unban retry state for this instance are persisted as CSVs under
          here, named for the instance, so timed bans and unbans still owed
          to the firewall both survive a restart. See L</state_path>,
          L</cidr_state_path>, L</retry_state_path>, and
          L</cidr_retry_state_path> for the four.
        Default :: /var/cache/ereshkigal

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
				1 => 'NErunBaseDir',
				2 => 'invalidName',
				3 => 'backendInitFailed',
				4 => 'nonRWrunBaseDir',
				5 => 'NEcacheBaseDir',
				6 => 'nonRWcacheBaseDir',
				7 => 'invalidBanTime',
				8 => 'invalidCheckpoint',
			},
			fatal_flags      => {},
			perror_not_fatal => 0,
		},
		name               => undef,
		backend            => undef,
		ports              => [],
		protocols          => [],
		prefix             => undef,
		options            => undef,
		self_heal          => undef,
		ban_time           => 600,
		checkpoint         => 60,
		enable_cidr        => 0,
		cidr_silent_drop   => 0,
		run_base_dir       => '/var/run/ereshkigal',
		cache_base_dir     => '/var/cache/ereshkigal',
		backend_obj        => undef,
		cidr_supported     => 0,
		server             => undef,
		started            => undef,
		stopping           => 0,
		bans               => {},
		cidr_bans          => {},
		unban_retries      => {},
		cidr_unban_retries => {},
		last_checkpoint    => 0,
		stats              => {
			bans         => 0,
			unbans       => 0,
			cidr_bans    => 0,
			cidr_unbans  => 0,
			errors       => 0,
			expired      => 0,
			cidr_expired => 0,
		},
	};
	bless $self;

	my @to_merge = (
		'name',       'backend',     'ports',            'protocols',
		'prefix',     'options',     'self_heal',        'ban_time',
		'checkpoint', 'enable_cidr', 'cidr_silent_drop', 'run_base_dir',
		'cache_base_dir'
	);
	foreach my $item (@to_merge) {
		if ( defined( $opts{$item} ) ) {
			$self->{$item} = $opts{$item};
		}
	}

	# the two CIDR toggles are booleans... a config may hand them over as the
	# literal strings true/false, which are both truthy in Perl, so those are
	# folded down before the truthiness of the value is trusted
	foreach my $toggle ( 'enable_cidr', 'cidr_silent_drop' ) {
		if ( !defined( $self->{$toggle} ) || $self->{$toggle} =~ /\A(?:|0|false|no|off)\z/i ) {
			$self->{$toggle} = 0;
		} else {
			$self->{$toggle} = 1;
		}
	}

	if ( $self->{ban_time} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 7;
		$self->{errorString} = 'ban_time, "' . $self->{ban_time} . '", is not a non-negative int of seconds';
		$self->warn;
	}

	if ( $self->{checkpoint} !~ /^[0-9]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 8;
		$self->{errorString} = 'checkpoint, "' . $self->{checkpoint} . '", is not a non-negative int of seconds';
		$self->warn;
	}

	if ( !defined( $self->{name} ) ) {
		$self->{perror}      = 1;
		$self->{error}       = 2;
		$self->{errorString} = 'name is undef';
		$self->warn;
	} elsif ( $self->{name} !~ /^[a-zA-Z0-9\-]+$/ ) {
		$self->{perror}      = 1;
		$self->{error}       = 2;
		$self->{errorString} = 'The specified name, "' . $self->{name} . '", does not match /^[a-zA-Z0-9\-]+$/';
		$self->warn;
	}

	foreach my $dir ( $self->{run_base_dir}, $self->{run_base_dir} . '/kur' ) {
		if ( !-e $dir ) {
			# don't need to check if this worked failed or not here as the next if statement will handle that
			eval { mkdir($dir); };
		}
		if ( !-d $dir ) {
			$self->{perror}      = 1;
			$self->{error}       = 1;
			$self->{errorString} = 'run dir,"' . $dir . '", does not exist or is not a directory';
			$self->warn;
		}
		if ( !-r $dir || !-w $dir ) {
			$self->{perror}      = 1;
			$self->{error}       = 4;
			$self->{errorString} = 'run dir,"' . $dir . '", is either not writable or readable by the current user';
			$self->warn;
		}
	} ## end foreach my $dir ( $self->{run_base_dir}, $self->...)

	if ( !-e $self->{cache_base_dir} ) {
		# don't need to check if this worked failed or not here as the next if statement will handle that
		eval { mkdir( $self->{cache_base_dir} ); };
	}
	if ( !-d $self->{cache_base_dir} ) {
		$self->{perror}      = 1;
		$self->{error}       = 5;
		$self->{errorString} = 'cache_base_dir,"' . $self->{cache_base_dir} . '", does not exist or is not a directory';
		$self->warn;
	}
	if ( !-r $self->{cache_base_dir} || !-w $self->{cache_base_dir} ) {
		$self->{perror} = 1;
		$self->{error}  = 6;
		$self->{errorString}
			= 'cache_base_dir,"'
			. $self->{cache_base_dir}
			. '", is either not writable or readable by the current user';
		$self->warn;
	}

	eval {
		$self->{backend_obj} = Net::Firewall::BlockerHelper->new(
			backend   => $self->{backend},
			ports     => $self->{ports},
			protocols => $self->{protocols},
			name      => $self->{name},
			defined( $self->{prefix} )    ? ( prefix    => $self->{prefix} )    : (),
			defined( $self->{options} )   ? ( options   => $self->{options} )   : (),
			defined( $self->{self_heal} ) ? ( self_heal => $self->{self_heal} ) : (),
		);
		$self->{backend_obj}->init_backend;
	};
	if ($@) {
		$self->{perror}      = 1;
		$self->{error}       = 3;
		$self->{errorString} = 'Failed to init the backend... ' . $@;
		$self->warn;
	}

	# note whether the backend can carry CIDR bans... enable_cidr is the
	# operator opting in, but a backend that cannot do CIDR still cannot, so
	# the two together are what gate the CIDR commands
	$self->{cidr_supported} = $self->_backend_cidr_supported;
	if ( $self->{enable_cidr} && !$self->{cidr_supported} ) {
		log_drek(
			'warning',
			'enable_cidr is set but the "'
				. $self->{backend}
				. '" backend does not support CIDR bans... CIDR commands will be refused',
			undef,
			'kur-' . ( defined( $self->{name} ) ? $self->{name} : '' )
		);
	} ## end if ( $self->{enable_cidr} && !$self->{cidr_supported...})

	# bring any persisted ban state back, dropping and unbanning whatever
	# expired while not running
	$self->_load_bans;
	$self->_load_cidr_bans;
	$self->_load_retries;

	return $self;
} ## end sub new

=head2 socket_path

Returns the path of the unix socket for this instance.

    my $socket_path = $kur->socket_path;

=cut

sub socket_path {
	my ($self) = @_;

	return $self->{run_base_dir} . '/kur/' . $self->{name} . '.sock';
}

=head2 pid_path

Returns the path of the PID file for this instance.

    my $pid_path = $kur->pid_path;

=cut

sub pid_path {
	my ($self) = @_;

	return $self->{run_base_dir} . '/kur/' . $self->{name} . '.pid';
}

=head2 state_path

Returns the path of the ban state CSV for this instance.

    my $state_path = $kur->state_path;

=cut

sub state_path {
	my ($self) = @_;

	return $self->{cache_base_dir} . '/kur.' . $self->{name} . '.csv';
}

=head2 cidr_state_path

Returns the path of the CIDR ban state CSV for this instance. This is kept
separate from L</state_path> so the single IP state format stays untouched.

    my $cidr_state_path = $kur->cidr_state_path;

=cut

sub cidr_state_path {
	my ($self) = @_;

	return $self->{cache_base_dir} . '/kur.' . $self->{name} . '.cidr.csv';
}

=head2 retry_state_path

Returns the path of the unban retry state CSV for this instance, the tablet
carrying entries whose unban at expiry failed and is still owed to the
firewall.

    my $retry_state_path = $kur->retry_state_path;

=cut

sub retry_state_path {
	my ($self) = @_;

	return $self->{cache_base_dir} . '/kur.' . $self->{name} . '.retry.csv';
}

=head2 cidr_retry_state_path

Returns the path of the CIDR unban retry state CSV for this instance, the
CIDR counterpart of L</retry_state_path>.

    my $cidr_retry_state_path = $kur->cidr_retry_state_path;

=cut

sub cidr_retry_state_path {
	my ($self) = @_;

	return $self->{cache_base_dir} . '/kur.' . $self->{name} . '.cidr.retry.csv';
}

=head2 start_server

Starts up the L<POE::Component::Server::JSONUnix> server for this instance,
calling $poe_kernel->run.

This should not be expected to return till the server is told to stop.

The socket is chmoded to 0600 given only the manager, running as the same
user, talks to it.

A ban sweeper is also started, which checks once a second for timed bans
that have expired and unbans them, and handles the periodic checkpointing
of the ban state CSVs. SIGTERM and SIGINT are handled, checkpointing and
tearing the backend down the same as the stop command before exiting.

IPs passed to ban and unban are validated and normalized to their canonical
string form, so variant spellings of the same IP, most notably IPv6 long
form vs short form as well as case, are all treated as the same IP. For ban
anything failing to validate errors per IP without disturbing the rest of
the request, while for unban it is fatal to the request.

The JSON commands handled are as below.

    - ban :: Ban the IPs specified via the array args.ips. args.ban_time,
          if defined, overrides the instance default for how long the bans
          should last in seconds, with 0 meaning never time out. Banning an
          already banned IP just refreshes its timer.

    - unban :: Check if the IP, args.ip, is banned and if so unban it.

    - cidr_ban :: Ban the CIDR ranges specified via the array args.cidrs,
          otherwise behaving like ban. Only handled when enable_cidr is set
          and the backend supports CIDR bans, otherwise it is either dropped
          or refused per cidr_silent_drop.

    - cidr_unban :: Check if the CIDR, args.cidr, is banned and if so unban
          it. Gated the same as cidr_ban.

    - banned :: Return a list of banned IPs along with an expires map of
          when each times out, 0 meaning never. banned_cidr and cidr_expires
          carry the same for CIDR bans. unban_retries and cidr_unban_retries
          carry the per entry book keeping for unbans still owed to the
          firewall.

    - status :: Return instance status info and stats, including ban_time,
          counts of timed and permanent bans, the next expiry, and how many
          unbans are still owed to the firewall along with how long the
          longest owed has been outstanding.

    - flush :: Unban everything currently banned, ranges as well as single
          IPs, emptying both ban books and both unban retry books with them.

    - re_init :: Have the backend tear its firewall setup down and build it
          again, re-banning everything the ban books carry. Bans are not
          enforced while that is happening. Tearing down takes any rule a
          failed unban left behind, so the retry books are emptied too.

    - checkpoint :: Write the ban state CSVs out now.

    - clear_retries :: Forget unbans still owed to the firewall, either the
          single one named by args.ip or args.cidr, or all of them when
          neither is given. Only the book keeping is forgotten, nothing is
          asked of the firewall, so anything genuinely still banished there
          stays that way.

    - stop :: Checkpoint, teardown the backend, and exit.

=cut

sub start_server {
	my ($self) = @_;

	$self->errorblank;

	my $ident = 'kur-' . $self->{name};

	my $server = POE::Component::Server::JSONUnix->spawn(
		'socket_path' => $self->socket_path,
		'socket_mode' => oct('0600'),
		'alias'       => $ident,
		'on_error'    => sub {
			my ( $operation, $errnum, $errstr ) = @_;
			log_drek( 'err', 'socket error during ' . $operation . '... ' . $errstr . ' (' . $errnum . ')',
				undef, $ident );
		},
		'commands' => {
			'ban' => sub {
				my ( undef, $request ) = @_;
				return $self->_cmd_ban($request);
			},
			'unban' => sub {
				my ( undef, $request ) = @_;
				return $self->_cmd_unban($request);
			},
			'cidr_ban' => sub {
				my ( undef, $request ) = @_;
				return $self->_cmd_cidr_ban($request);
			},
			'cidr_unban' => sub {
				my ( undef, $request ) = @_;
				return $self->_cmd_cidr_unban($request);
			},
			'banned' => sub {
				return $self->_cmd_banned;
			},
			'status' => sub {
				return $self->_cmd_status;
			},
			'flush' => sub {
				return $self->_cmd_flush;
			},
			're_init' => sub {
				return $self->_cmd_re_init;
			},
			'checkpoint' => sub {
				return $self->_cmd_checkpoint;
			},
			'clear_retries' => sub {
				my ( undef, $request ) = @_;
				return $self->_cmd_clear_retries($request);
			},
			'stop' => sub {
				my ( undef, undef, $ctx ) = @_;
				return $self->_cmd_stop($ctx);
			},
		},
	);

	$self->{server}  = $server;
	$self->{started} = time;

	# the ban sweeper... a self-rescheduling one second alarm that expires
	# timed bans and handles the periodic checkpoint... it stops
	# rescheduling once stop has been requested so the session ends and the
	# kernel can exit... it also watches for TERM/INT so a signaled kur
	# still checkpoints and tears the backend down rather than dying with
	# the firewall state dangling
	POE::Session->create(
		'inline_states' => {
			'_start' => sub {
				$_[KERNEL]->sig( 'TERM', 'sig_shutdown' );
				$_[KERNEL]->sig( 'INT',  'sig_shutdown' );
				$_[KERNEL]->delay( 'sweep', 1 );
			},
			'sweep' => sub {
				if ( $self->{stopping} ) {
					return;
				}
				$self->_tick;
				$_[KERNEL]->delay( 'sweep', 1 );
			},
			'sig_shutdown' => sub {
				my $signal = $_[ARG0];
				$_[KERNEL]->sig_handled;
				if ( $self->{stopping} ) {
					return;
				}
				log_drek( 'info', 'SIG' . $signal . ' received, tearing the backend down', undef, $ident );
				$self->_stop_guts;
				# _stop_guts set stopping, so the pending sweep alarm is the
				# only thing keeping this session alive... clear it and fire
				# the server session's shutdown so the kernel can exit
				$_[KERNEL]->delay('sweep');
				$_[KERNEL]->post( $ident, 'shutdown' );
			},
		},
	);

	log_drek( 'info', 'started... socket=' . $self->socket_path . ' backend=' . $self->{backend}, undef, $ident );

	$poe_kernel->run;

	log_drek( 'info', 'stopped', undef, $ident );

	return;
} ## end sub start_server

# The single choke point for every call into the Net::Firewall::BlockerHelper
# frontend held in $self->{backend_obj}. It exists because that frontend has
# two ways of failing and only one of them is a die... depending on the
# Error::Helper fatality settings in play a failure may instead just warn and
# leave the error flag set, which a bare method call would sail straight past.
# Everything in this module goes through here so both look the same to the
# caller, which is why none of the command handlers check errors themselves.
#
# The method is called on the frontend inside an eval. A die is rethrown as
# is, and if the call survived but left the frontend's error flag set, the
# frontend's errorString is thrown instead.
#
# Args, the first required and the rest optional...
#
#     $method :: The name of the method to call on the frontend, as a plain
#                string, called as a method so it may be any of the frontend's
#                public API... 'ban', 'unban', 'ban_cidr', 'unban_cidr',
#                'list', 'list_cidr', 'check', 'flush', 're_init', or
#                'teardown'. Not validated here, so a name the frontend does
#                not implement dies with the usual can't locate object method.
#     %args   :: The remaining pairs, passed through to that method verbatim.
#                In practice this is either empty, for the ones taking no
#                arguments, or a single ban => $entry pair for the ban and
#                unban family.
#
# Returns whatever the method returned, as a list, propagated unchanged. For
# list and list_cidr that is the entries the firewall is carrying; for check
# it is a single true or false healthy value, which is why callers of that
# assign it as ($healthy); for the rest it is generally empty and ignored.
#
# Dies with either the frontend's own exception or its errorString, neither
# carrying a trailing newline, so a caller wanting to report it cleanly has
# to trim it.
#
#     my @banned = $self->_backend_do('list');
#
#     $self->_backend_do( 'unban', ban => '1.2.3.4' );
#
#     my ($healthy) = $self->_backend_do('check');
sub _backend_do {
	my ( $self, $method, %args ) = @_;

	my @results;
	eval { @results = $self->{backend_obj}->$method(%args); };
	if ($@) {
		die($@);
	}
	if ( $self->{backend_obj}->error ) {
		die( $self->{backend_obj}->errorString );
	}

	return @results;
} ## end sub _backend_do

# The per family knobs the shared ban/unban/sweep/load helpers use. The single
# IP and the CIDR paths are identical beyond these, so rather than two near
# copies of every helper there is one of each taking a $spec, which is one of
# the two entries below... $family_spec{ip} or $family_spec{cidr}. Any helper
# below documenting a $spec argument means one of these two hash refs, and
# names only the keys it actually reaches for.
#
# The keys, all present in both entries...
#
#     noun             :: The family in error messages meant for a human,
#                         'IP' or 'CIDR'.
#     label            :: The family in lower case, 'ip' or 'cidr'. Used as
#                         the first column name in the tablet header, and
#                         matched against when deciding if a tablet's first
#                         line is that header.
#     log_label        :: What one entry of this family is called in the log,
#                         'ban' or 'cidr ban'.
#     infix            :: Fragment glued into log lines before the entry
#                         itself, '' or 'cidr '. Separate from log_label as
#                         the two read differently depending on the sentence.
#     normalizer       :: Code ref, normalize_ip or normalize_cidr, taking one
#                         raw string and returning the canonical form or undef
#                         if it will not validate. Everything is put through
#                         this before being booked, which is what keeps the
#                         books canonical only.
#     ban_method       :: Frontend method banning one entry, 'ban' or
#                         'ban_cidr'.
#     unban_method     :: Frontend method unbanning one entry, 'unban' or
#                         'unban_cidr'.
#     list_method      :: Frontend method listing what the firewall carries,
#                         'list' or 'list_cidr'.
#     hash             :: Name of the key on $self holding this family's ban
#                         book, 'bans' or 'cidr_bans'. That book is a hash of
#                         canonical entry to { banned_at => epoch,
#                         expires => epoch or 0 for never }.
#     retry_hash       :: Name of the key on $self holding this family's unban
#                         retry book, 'unban_retries' or
#                         'cidr_unban_retries'. That book is a hash of
#                         canonical entry to { first_tried => epoch,
#                         last_tried => epoch, times_tried => int,
#                         next_try => epoch, delay => seconds }.
#     ban_stat         :: Key under $self->{stats} counting bans for this
#                         family, 'bans' or 'cidr_bans'.
#     unban_stat       :: Key under $self->{stats} counting unbans,
#                         'unbans' or 'cidr_unbans'.
#     expired_stat     :: Key under $self->{stats} counting expiries,
#                         'expired' or 'cidr_expired'.
#     checkpoint       :: Name of the method writing this family's ban tablet,
#                         '_checkpoint' or '_checkpoint_cidr'. Called as
#                         $self->$method with no arguments.
#     retry_checkpoint :: Name of the method writing this family's retry
#                         tablet, '_checkpoint_retries' or
#                         '_checkpoint_cidr_retries'.
#     retry_path       :: Name of the accessor giving this family's retry
#                         tablet path, 'retry_state_path' or
#                         'cidr_retry_state_path'.
#     retry_arg        :: The request argument naming a single entry of this
#                         family, 'ip' or 'cidr'. Used by the clear_retries
#                         handler to work out which family was named.
my %family_spec = (
	'ip' => {
		'noun'             => 'IP',
		'label'            => 'ip',
		'log_label'        => 'ban',
		'infix'            => '',
		'normalizer'       => \&normalize_ip,
		'ban_method'       => 'ban',
		'unban_method'     => 'unban',
		'list_method'      => 'list',
		'hash'             => 'bans',
		'retry_hash'       => 'unban_retries',
		'ban_stat'         => 'bans',
		'unban_stat'       => 'unbans',
		'expired_stat'     => 'expired',
		'checkpoint'       => '_checkpoint',
		'retry_checkpoint' => '_checkpoint_retries',
		'retry_path'       => 'retry_state_path',
		'retry_arg'        => 'ip',
	},
	'cidr' => {
		'noun'             => 'CIDR',
		'label'            => 'cidr',
		'log_label'        => 'cidr ban',
		'infix'            => 'cidr ',
		'normalizer'       => \&normalize_cidr,
		'ban_method'       => 'ban_cidr',
		'unban_method'     => 'unban_cidr',
		'list_method'      => 'list_cidr',
		'hash'             => 'cidr_bans',
		'retry_hash'       => 'cidr_unban_retries',
		'ban_stat'         => 'cidr_bans',
		'unban_stat'       => 'cidr_unbans',
		'expired_stat'     => 'cidr_expired',
		'checkpoint'       => '_checkpoint_cidr',
		'retry_checkpoint' => '_checkpoint_cidr_retries',
		'retry_path'       => 'cidr_retry_state_path',
		'retry_arg'        => 'cidr',
	},
);

# Guard called at the top of every command handler that would touch the
# backend, refusing it once stop has been requested. It exists because stop
# tears the backend down and writes a final tablet, but the server session
# stays up for another second so the stop response can flush... anything
# arriving in that window would both fail against a torn down backend and
# overwrite the fresh tablet stop just left behind. The read only handlers,
# banned and status, and the book only ones, checkpoint and clear_retries,
# deliberately do not call this, as neither can do that damage.
#
# Takes no arguments beyond the invocant, reading $self->{stopping}, which
# _stop_guts sets.
#
# Returns nothing meaningful, an empty return, when the kur is not stopping.
# The whole point is the die on the other branch, so callers just call it and
# carry on.
#
# Dies with 'this kur is stopping', no trailing newline, once stopping is
# set. That reaches the client as a normal error response.
#
#     sub _cmd_flush {
#         my ($self) = @_;
#         $self->_refuse_when_stopping;
#         ...
#     }
sub _refuse_when_stopping {
	my ($self) = @_;

	if ( $self->{stopping} ) {
		die('this kur is stopping');
	}

	return;
}

# Works out how long the bans in one request should last, which is the
# instance default unless that request carried its own ban_time. This is the
# per request layer of the ban_time layering, the ones below it having already
# been resolved into $self->{ban_time} by new... a request beats the kur
# setting, which beats the manager wide one, which beats 600.
#
# Validation happens here rather than being left to the backend so a bad
# ban_time fails the whole request up front, instead of after some of its IPs
# have already been banned.
#
# Args, one required...
#
#     $args :: The args hash ref of the request, which is whatever the client
#              sent and so may be missing keys or carry rubbish. Only
#              args.ban_time is looked at, and it is optional... when absent
#              or undef the instance default is used. When present it must be
#              a plain scalar of digits, so a non-negative integer of seconds
#              with 0 meaning the ban never expires. A ref, a negative number,
#              or anything non-numeric dies.
#
# Returns the effective ban_time as an integer of seconds, 0 meaning the bans
# should never expire. Callers hand that straight to _ban_many.
#
# Dies with 'args.ban_time must be a non-negative int of seconds', no
# trailing newline, on a carried ban_time that will not validate.
#
#     my $ban_time = $self->_resolve_ban_time( $request->{args} );
#
#     # with args of { ips => ['1.2.3.4'], ban_time => 3600 } that is 3600,
#     # and with { ips => ['1.2.3.4'] } it is whatever $self->{ban_time} is
sub _resolve_ban_time {
	my ( $self, $args ) = @_;

	if ( !defined( $args->{ban_time} ) ) {
		return $self->{ban_time};
	}
	if ( ref( $args->{ban_time} ) ne '' || $args->{ban_time} !~ /^[0-9]+$/ ) {
		die('args.ban_time must be a non-negative int of seconds');
	}

	return $args->{ban_time};
} ## end sub _resolve_ban_time

# Gives self_heal its chance on the refresh path. Normally self_heal lives
# inside the backend's own ban and unban, checking the firewall setup is still
# there before each one, but re-banning something already banned deliberately
# does not call the backend at all... and for a ban source hammering the same
# handful of addresses that refresh is the common case, so a setup swept away
# by a firewall reload could go unnoticed indefinitely. This runs the
# check-and-re_init half by hand to close that.
#
# Reads the effective self_heal, defaulting to on when the instance leaves it
# undef, and returns straight away when it is off. Otherwise the backend is
# asked to check, and if that succeeds but reports unhealthy the backend is
# asked to re_init. A successful re_init empties both retry books and
# checkpoints them, since re_init tears the setup down and rebuilds from the
# ban books, taking any rule a failed unban left behind with it.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return, whichever branch it took.
#
# Deliberately dies for nothing. Both backend calls are wrapped, a failed
# check is treated as no reason to act, and a failed re_init is only logged...
# this is best effort housekeeping on the way through a refresh, so a
# firewall having a bad moment is left for the next real ban to trip over
# rather than turning a successful refresh into an error.
#
#     # from _ban_many, on finding the entry already in the book
#     $self->_refresh_heal;
#     $self->{ $spec->{hash} }{$entry}{expires} = $expires;
sub _refresh_heal {
	my ($self) = @_;

	my $self_heal = defined( $self->{self_heal} ) ? ( $self->{self_heal} ? 1 : 0 ) : 1;
	if ( !$self_heal ) {
		return;
	}

	my $healthy;
	eval { ($healthy) = $self->_backend_do('check'); };
	if ( !$@ && !$healthy ) {
		eval { $self->_backend_do('re_init'); };
		if ($@) {
			log_drek( 'err', 're_init during refresh self heal failed... ' . $@, undef, 'kur-' . $self->{name} );
		} else {
			# re_init re-bans only what the book carries, so anything pending
			# an unban retry is no longer in the firewall
			$self->{unban_retries}      = {};
			$self->{cidr_unban_retries} = {};
			$self->_checkpoint_retries;
			$self->_checkpoint_cidr_retries;
		}
	} ## end if ( !$@ && !$healthy )

	return;
} ## end sub _refresh_heal

# The shared loop body behind both _cmd_ban and _cmd_cidr_ban, the two being
# identical once the family knobs are parameterized out. Every entry is
# answered for separately, so one bad address never spoils the rest of a
# request... that is the reason this returns a per entry hash rather than
# dieing on the first problem.
#
# For each entry in turn... it is normalized, and an entry that will not
# normalize is recorded as an error and skipped. One already in the ban book is
# a refresh, so its expiry is reset, _refresh_heal is given its chance, and
# the backend is deliberately not asked to re-add it, as not every backend
# takes that gracefully. One with a pending unban retry means the firewall
# still carries the rule, so that retry is cancelled and the entry booked
# afresh, again without troubling the backend. Anything else is banned via the
# backend and booked. Nothing here writes a tablet... the caller checkpoints
# once for the whole request.
#
# Args, all three required and positional...
#
#     $entries  :: Array ref of raw entries straight off the request, so
#                  args.ips or args.cidrs as the client sent them. Elements
#                  are whatever arrived and may be undef, refs, or nonsense;
#                  each is put through the family normalizer and a failure
#                  becomes that entry's error rather than a die. An empty array
#                  is legal here and simply produces an empty result, the
#                  callers having already rejected one.
#     $ban_time :: Effective seconds from _resolve_ban_time. 0 means the bans
#                  never expire, anything else is added to the current time to
#                  get each entry's expiry.
#     $spec     :: One of the %family_spec entries described above. Uses
#                  normalizer, noun, log_label, infix, hash, retry_hash,
#                  retry_checkpoint, ban_method, and ban_stat.
#
# Returns a hash ref keyed by entry, holding one result per entry of the
# request. A good entry is keyed by its canonical form, so the caller sees the
# normalized spelling rather than what was sent, and its value is
# { status => 'ok' }, or { status => 'ok', refreshed => 1 } when it was
# already banned and only had its timer reset. An entry that would not
# normalize is keyed by the raw string it arrived as, or by the empty string
# when it arrived undef, with a value of
# { status => 'error', error => '...' }. A backend refusal is the same error
# shape but keyed by the canonical form.
#
# Does not die. Every failure is a per entry error in the returned hash.
#
#     my $results = $self->_ban_many(
#         [ '1.2.3.4', 'nonsense' ],
#         600,
#         $family_spec{ip},
#     );
#     # $results is {
#     #     '1.2.3.4'  => { status => 'ok' },
#     #     'nonsense' => { status => 'error', error => '"nonsense" does ...' },
#     # }
#
#     my $results = $self->_ban_many( ['1.2.3.0/24'], 0, $family_spec{cidr} );
sub _ban_many {
	my ( $self, $entries, $ban_time, $spec ) = @_;

	my $ident = 'kur-' . $self->{name};

	my $results = {};
	foreach my $raw_entry ( @{$entries} ) {
		# bounced here rather than left for the backend to judge, given the
		# backend accepts ambiguous stuff like leading zero octet IPv4, and
		# reduced to the canonical form so variant spellings dedupe
		my $entry = $spec->{normalizer}->($raw_entry);
		if ( !defined($entry) ) {
			my $key = defined($raw_entry) ? $raw_entry : '';
			$self->{stats}{errors}++;
			$results->{$key} = {
				'status' => 'error',
				'error'  => '"' . $key . '" does not appear to be an IPv4 or IPv6 ' . $spec->{noun}
			};
			log_drek(
				'err',
				$spec->{log_label} . ' of "'
					. $key
					. '" failed... does not appear to be an IPv4 or IPv6 '
					. $spec->{noun},
				undef,
				$ident
			);
			next;
		} ## end if ( !defined($entry) )
		my $expires = $ban_time ? time + $ban_time : 0;

		# already banned, so just refresh its timer... the backend ban is
		# not re-ran, as not every backend takes re-adding an existing entry
		# gracefully, but self_heal still gets its chance via _refresh_heal
		if ( defined( $self->{ $spec->{hash} }{$entry} ) ) {
			$self->_refresh_heal;
			$self->{ $spec->{hash} }{$entry}{expires} = $expires;
			$results->{$entry} = { 'status' => 'ok', 'refreshed' => 1 };
			log_drek( 'info', 'refreshed ' . $spec->{log_label} . ' of ' . $entry . ' expires=' . $expires,
				undef, $ident );
			next;
		}

		# a pending unban retry means the firewall still carries it, so the
		# backend is not asked to re-add what it already has... the retry is
		# cancelled and the entry booked fresh
		if ( defined( $self->{ $spec->{retry_hash} }{$entry} ) ) {
			delete( $self->{ $spec->{retry_hash} }{$entry} );
			my $retry_checkpoint_method = $spec->{retry_checkpoint};
			$self->$retry_checkpoint_method;
			$self->{stats}{ $spec->{ban_stat} }++;
			$self->{ $spec->{hash} }{$entry} = { 'banned_at' => time, 'expires' => $expires };
			$results->{$entry} = { 'status' => 'ok' };
			log_drek( 'info',
				'banned ' . $spec->{infix} . $entry . ' expires=' . $expires . ', cancelling pending unban retry',
				undef, $ident );
			next;
		} ## end if ( defined( $self->{ $spec->{retry_hash}...}))

		my $ban_method = $spec->{ban_method};
		eval { $self->_backend_do( $ban_method, ban => $entry ); };
		if ($@) {
			$self->{stats}{errors}++;
			$results->{$entry} = { 'status' => 'error', 'error' => $@ };
			log_drek( 'err', $spec->{log_label} . ' of "' . $entry . '" failed... ' . $@, undef, $ident );
		} else {
			$self->{stats}{ $spec->{ban_stat} }++;
			$self->{ $spec->{hash} }{$entry} = { 'banned_at' => time, 'expires' => $expires };
			$results->{$entry} = { 'status' => 'ok' };
			log_drek( 'info', 'banned ' . $spec->{infix} . $entry . ' expires=' . $expires, undef, $ident );
		}
	} ## end foreach my $raw_entry ( @{$entries} )

	return $results;
} ## end sub _ban_many

# The shared body behind both _cmd_unban and _cmd_cidr_unban. It asks the
# firewall rather than the book whether the entry is actually there, which is
# what lets an unban be fired at every kur in a fan out without the ones that
# never held it erroring... they answer was_banned 0 and nothing else happens.
#
# The backend is listed and each entry it reports is normalized before being
# compared, because a firewall may well render an entry differently to how it
# was handed over, IPv6 especially, and it is that spelling it wants back to
# remove it. When no match is found any stale book entry is dropped and the
# tablet rewritten, so a hand removal behind the kur's back still tidies up.
# When a match is found the backend is asked to unban it, and on success the
# book, the retry book, and both tablets are brought into line.
#
# Args, both required and positional...
#
#     $entry :: A single entry in canonical form. The caller is expected to
#               have already put the request argument through the family
#               normalizer and dealt with a failure, so this is never undef
#               and never a raw spelling... the book and the retry book are
#               keyed by this form.
#     $spec  :: One of the %family_spec entries described above. Uses
#               normalizer, list_method, unban_method, hash, retry_hash,
#               checkpoint, retry_checkpoint, unban_stat, and infix.
#
# Returns 1 when the firewall was carrying the entry and it has now been
# removed, and 0 when it was not carrying it at all. The callers put that
# straight into their was_banned field, so 0 is a perfectly ordinary answer
# and not a failure.
#
# Dies if the backend refuses the unban, rethrowing whatever it said, having
# first counted an error. It also dies if listing the backend fails, that
# being a bare _backend_do call. A caller wanting a failed unban to be
# survivable has to wrap it.
#
#     my $was_banned = $self->_unban_one( '1.2.3.4', $family_spec{ip} );
#
#     my $was_banned = $self->_unban_one( '1.2.3.0/24', $family_spec{cidr} );
sub _unban_one {
	my ( $self, $entry, $spec ) = @_;

	my $checkpoint_method = $spec->{checkpoint};

	# check if it is actually present before trying to unban it... what the
	# backend lists back is compared in normalized form, as a firewall may
	# well render an entry differently to how it was handed over, IPv6
	# especially, and that spelling is what it wants back to remove it
	my @banned = $self->_backend_do( $spec->{list_method} );
	my $present;
	foreach my $banned_entry (@banned) {
		my $normalized = $spec->{normalizer}->($banned_entry);
		if ( ( defined($normalized) ? $normalized : $banned_entry ) eq $entry ) {
			$present = $banned_entry;
			last;
		}
	}
	if ( !defined($present) ) {
		# make sure no stale timer is left behind either way
		if ( defined( delete( $self->{ $spec->{hash} }{$entry} ) ) ) {
			$self->$checkpoint_method;
		}
		return 0;
	}

	# unbanned via the spelling the backend book actually carries, which for
	# anything banned by this process is the canonical form anyway
	eval { $self->_backend_do( $spec->{unban_method}, ban => $present ); };
	if ($@) {
		$self->{stats}{errors}++;
		die($@);
	}
	$self->{stats}{ $spec->{unban_stat} }++;
	# the book and the retry list are both keyed by the canonical form, that
	# being the only form either ever carries, so the backend's spelling is
	# not a key to worry about here... a pending unban retry is now moot
	delete( $self->{ $spec->{hash} }{$entry} );
	if ( defined( delete( $self->{ $spec->{retry_hash} }{$entry} ) ) ) {
		my $retry_checkpoint_method = $spec->{retry_checkpoint};
		$self->$retry_checkpoint_method;
	}
	$self->$checkpoint_method;
	log_drek( 'info', 'unbanned ' . $spec->{infix} . $entry, undef, 'kur-' . $self->{name} );

	return 1;
} ## end sub _unban_one

# Handles the ban command off the socket, the single IP half of the pair with
# _cmd_cidr_ban. All the real work is _ban_many's... this validates the shape
# of the request, resolves the sentence, and checkpoints once at the end
# rather than once per IP, so a request banning a hundred addresses writes one
# tablet rather than a hundred.
#
# Args, one required...
#
#     $request :: The request hash ref as it came off the socket. Only
#                 $request->{args} is read, and that must be a hash ref
#                 carrying an ips key holding an array ref of one or more raw
#                 IPs. Elements are not checked here, _ban_many judging each
#                 one. args.ban_time is optional and goes to
#                 _resolve_ban_time.
#
# Returns a hash ref of { ips => $results }, where $results is the per entry
# hash _ban_many built... each key an IP and each value either
# { status => 'ok' }, { status => 'ok', refreshed => 1 }, or
# { status => 'error', error => '...' }. That whole thing becomes the result
# field of the response.
#
# Dies if the kur is stopping, if args is missing, or if args.ips is not a
# array ref of at least one element, and via _resolve_ban_time if
# args.ban_time will not validate. Individual bad IPs do not die.
#
#     my $result = $self->_cmd_ban(
#         { 'args' => { 'ips' => [ '1.2.3.4', '5.6.7.8' ] } }
#     );
#     # $result is { ips => { '1.2.3.4' => { status => 'ok' }, ... } }
#
#     my $result = $self->_cmd_ban(
#         { 'args' => { 'ips' => ['1.2.3.4'], 'ban_time' => 0 } }
#     );
sub _cmd_ban {
	my ( $self, $request ) = @_;

	$self->_refuse_when_stopping;

	my $args = $request->{args};
	if ( !defined($args) || ref( $args->{ips} ) ne 'ARRAY' || !@{ $args->{ips} } ) {
		die('args.ips must be an array of one or more IPs');
	}

	my $results = $self->_ban_many( $args->{ips}, $self->_resolve_ban_time($args), $family_spec{ip} );

	$self->_checkpoint;

	return { 'ips' => $results };
} ## end sub _cmd_ban

# Handles the unban command off the socket, the single IP half of the pair
# with _cmd_cidr_unban. Unlike ban it takes exactly one address, and unlike
# ban a bad one is fatal to the whole request rather than a per entry error...
# there being only the one entry, there is nothing to salvage.
#
# Args, one required...
#
#     $request :: The request hash ref as it came off the socket. Only
#                 $request->{args} is read, and that must be a hash ref
#                 carrying an ip key holding a single raw IP as a plain scalar.
#                 An array ref is refused rather than treated as a list of one.
#                 There is deliberately no kur argument here... the manager
#                 fans unban at every kur it has.
#
# Returns a hash ref of { ip => $canonical, was_banned => 0 or 1 }. The ip
# field is the canonical form rather than what was sent, so a client that
# asked in a variant IPv6 spelling can see what was actually acted on, and
# was_banned says whether the firewall was carrying it... 0 is a normal
# answer meaning it was not.
#
# Dies if the kur is stopping, if args is missing, if args.ip is missing or a
# ref, or if it will not normalize, and via _unban_one if the backend refuses
# the unban.
#
#     my $result = $self->_cmd_unban( { 'args' => { 'ip' => '1.2.3.4' } } );
#     # $result is { ip => '1.2.3.4', was_banned => 1 }
#
#     my $result = $self->_cmd_unban(
#         { 'args' => { 'ip' => '2001:0DB8::1' } }
#     );
#     # $result is { ip => '2001:db8::1', was_banned => 0 }
sub _cmd_unban {
	my ( $self, $request ) = @_;

	$self->_refuse_when_stopping;

	my $args = $request->{args};
	if ( !defined($args) || !defined( $args->{ip} ) || ref( $args->{ip} ) ne '' ) {
		die('args.ip must be an IP');
	}
	my $ip = normalize_ip( $args->{ip} );
	if ( !defined($ip) ) {
		die( 'args.ip, "' . $args->{ip} . '", does not appear to be an IPv4 or IPv6 IP' );
	}

	return { 'ip' => $ip, 'was_banned' => $self->_unban_one( $ip, $family_spec{ip} ) };
} ## end sub _cmd_unban

# Works out whether the backend this kur is wrapping can carry whole ranges,
# by reaching through the Net::Firewall::BlockerHelper frontend to the actual
# backend object underneath it and reading the cidr_supported flag there.
# That is the same flag the frontend itself gates ban_cidr on, so asking it
# directly keeps this kur's answer and the frontend's refusal in step. It is
# called once at init, the answer cached in $self->{cidr_supported}, so the
# reaching through happens the once rather than per command.
#
# Reaching two levels into another distribution's internals is why every step
# is guarded... a frontend that is undef, not blessed, or has no backend
# object yet is treated as no support rather than being allowed to die,
# because this runs during init where a die would take the whole kur down over
# a question that has a perfectly good conservative answer.
#
# Takes no arguments beyond the invocant, reading $self->{backend_obj}.
#
# Returns 1 when the backend claims CIDR support and 0 otherwise, including
# every case where the answer could not be reached at all. Never undef, so it
# is safe to store and test directly.
#
# Does not die.
#
#     $self->{cidr_supported} = $self->_backend_cidr_supported;
sub _backend_cidr_supported {
	my ($self) = @_;

	my $frontend = $self->{backend_obj};
	if ( !defined($frontend) || ref($frontend) eq '' ) {
		return 0;
	}
	my $backend = $frontend->{backend_obj};
	if ( !defined($backend) || ref($backend) eq '' ) {
		return 0;
	}

	return $backend->{cidr_supported} ? 1 : 0;
} ## end sub _backend_cidr_supported

# Whether this instance will actually act on a CIDR command, which needs both
# halves... the operator has to have opted in via enable_cidr, and the backend
# has to be able to carry ranges at all. Either alone is not enough, which is
# why this exists rather than the callers testing enable_cidr and assuming.
#
# Takes no arguments beyond the invocant, reading $self->{enable_cidr}, which
# new folded to a plain 1 or 0, and $self->{cidr_supported}, which init
# cached from _backend_cidr_supported.
#
# Returns 1 when ranges may be acted on and 0 otherwise. It does not say which
# half was missing... _cidr_guard works that out for the error message.
#
# Does not die.
#
#     if ( !$self->_cidr_available ) {
#         # skip loading the CIDR tablet entirely
#         return;
#     }
sub _cidr_available {
	my ($self) = @_;

	return ( $self->{enable_cidr} && $self->{cidr_supported} ) ? 1 : 0;
}

# The gate both CIDR command handlers pass through before doing anything
# else, deciding what a kur that cannot oblige should do about it. There are
# three answers rather than two because of fan outs... a gate spanning range
# capable and range incapable kurs would have every cidr-ban soured by the
# incapable ones if their only option were an error, so cidr_silent_drop lets
# those quietly report the command as dropped and leave the response clean.
#
# It runs before the handlers validate their payload, deliberately, so a kur
# that was never going to act short circuits regardless of whether the
# request was well formed.
#
# Takes no arguments beyond the invocant, reading _cidr_available,
# $self->{enable_cidr}, $self->{cidr_silent_drop}, and $self->{backend} for
# the message.
#
# Returns undef when CIDR is available, which the callers read as carry on.
# When it is not available and cidr_silent_drop is set it returns a hash ref
# of { dropped => 1, reason => '...' }, which the callers return to the client
# unchanged as the whole result... reason names which half was missing, either
# that CIDR bans are not enabled for the kur or that the named backend does
# not support them.
#
# Dies with that same reason string, no trailing newline, when CIDR is
# unavailable and cidr_silent_drop is not set.
#
#     my $drop = $self->_cidr_guard;
#     if ( defined($drop) ) {
#         return $drop;
#     }
#     # reached only when this kur really will act on ranges
sub _cidr_guard {
	my ($self) = @_;

	if ( $self->_cidr_available ) {
		return undef;
	}

	my $reason;
	if ( !$self->{enable_cidr} ) {
		$reason = 'CIDR bans are not enabled for this kur';
	} else {
		$reason = 'the "' . $self->{backend} . '" backend does not support CIDR bans';
	}

	if ( $self->{cidr_silent_drop} ) {
		log_drek( 'info', 'dropping CIDR command... ' . $reason, undef, 'kur-' . $self->{name} );
		return { 'dropped' => 1, 'reason' => $reason };
	}

	die($reason);
} ## end sub _cidr_guard

# Handles the cidr_ban command off the socket, the range twin of _cmd_ban and
# identical to it beyond the family knobs and the guard. _cidr_guard gets
# first say, so a kur that will not act on ranges answers before the payload
# is even looked at.
#
# Args, one required...
#
#     $request :: The request hash ref as it came off the socket. A missing
#                 args is tolerated as far as the guard, becoming an empty hash
#                 so a dropping kur can answer cleanly rather than dieing over
#                 a payload it was never going to read. Past the guard,
#                 args.cidrs must be an array ref of one or more raw ranges,
#                 elements unchecked here as _ban_many judges each. Host bits
#                 are masked off by the normalizer, so 1.2.3.4/24 and
#                 1.2.3.0/24 are one range. args.ban_time is optional.
#
# Returns a hash ref of { cidrs => $results } with the same per entry shape
# _cmd_ban returns, keyed by canonical range. When the guard dropped the
# command it instead returns that guard's { dropped => 1, reason => '...' },
# so a caller has to be ready for either shape.
#
# Dies if the kur is stopping, if the guard refuses rather than drops, if
# args.cidrs is not an array ref of at least one element, or via
# _resolve_ban_time on a bad ban_time.
#
#     my $result = $self->_cmd_cidr_ban(
#         { 'args' => { 'cidrs' => ['1.2.3.0/24'] } }
#     );
#     # $result is { cidrs => { '1.2.3.0/24' => { status => 'ok' } } }
#
#     # on a kur with CIDR off and cidr_silent_drop set
#     # $result is { dropped => 1, reason => 'CIDR bans are not enabled ...' }
sub _cmd_cidr_ban {
	my ( $self, $request ) = @_;

	$self->_refuse_when_stopping;

	my $args = $request->{args};
	if ( !defined($args) ) {
		$args = {};
	}

	# the guard comes first so a dropping or incapable instance short circuits
	# regardless of the payload... a capable one falls through and validates
	my $drop = $self->_cidr_guard;
	if ( defined($drop) ) {
		return $drop;
	}

	if ( ref( $args->{cidrs} ) ne 'ARRAY' || !@{ $args->{cidrs} } ) {
		die('args.cidrs must be an array of one or more CIDRs');
	}

	my $results = $self->_ban_many( $args->{cidrs}, $self->_resolve_ban_time($args), $family_spec{cidr} );

	$self->_checkpoint_cidr;

	return { 'cidrs' => $results };
} ## end sub _cmd_cidr_ban

# Handles the cidr_unban command off the socket, the range twin of
# _cmd_unban. _cidr_guard gets first say the same way it does for cidr_ban.
#
# Args, one required...
#
#     $request :: The request hash ref as it came off the socket. A missing
#                 args is tolerated as far as the guard, for the same reason
#                 it is in _cmd_cidr_ban. Past the guard, args.cidr must be a
#                 single raw range as a plain scalar; a ref is refused. Host
#                 bits are masked off, so naming any address inside a banned
#                 network finds it.
#
# Returns a hash ref of { cidr => $canonical, was_banned => 0 or 1 }, the cidr
# field being the masked canonical form rather than what was sent. When the
# guard dropped the command it instead returns that guard's
# { dropped => 1, reason => '...' }.
#
# Dies if the kur is stopping, if the guard refuses rather than drops, if
# args.cidr is missing or a ref, if it will not normalize, or via _unban_one
# if the backend refuses the unban.
#
#     my $result = $self->_cmd_cidr_unban(
#         { 'args' => { 'cidr' => '1.2.3.4/24' } }
#     );
#     # $result is { cidr => '1.2.3.0/24', was_banned => 1 }
sub _cmd_cidr_unban {
	my ( $self, $request ) = @_;

	$self->_refuse_when_stopping;

	my $args = $request->{args};
	if ( !defined($args) ) {
		$args = {};
	}

	my $drop = $self->_cidr_guard;
	if ( defined($drop) ) {
		return $drop;
	}

	if ( !defined( $args->{cidr} ) || ref( $args->{cidr} ) ne '' ) {
		die('args.cidr must be a CIDR');
	}
	my $cidr = normalize_cidr( $args->{cidr} );
	if ( !defined($cidr) ) {
		die( 'args.cidr, "' . $args->{cidr} . '", does not appear to be an IPv4 or IPv6 CIDR' );
	}

	return { 'cidr' => $cidr, 'was_banned' => $self->_unban_one( $cidr, $family_spec{cidr} ) };
} ## end sub _cmd_cidr_unban

# Handles the banned command off the socket, the detail view of who this kur
# is holding. The lists come from the firewall itself rather than the ban
# books, so what is reported is what is really in place... the books only
# supply the expiry times, which the firewall has no notion of.
#
# One consequence worth knowing: an entry whose unban failed at expiry has left
# the ban book but not the firewall, so it appears in banned and in
# unban_retries at once. That is not an inconsistency, it is the whole point of
# the retry books.
#
# Takes no arguments beyond the invocant. Deliberately not gated on
# _refuse_when_stopping, being read only, nor on _cidr_available, as
# list_cidr is safe on every backend and simply comes back empty on the ones
# that do not do ranges.
#
# Returns a hash ref carrying six keys...
#
#     banned             :: Array ref of the single IPs the firewall is
#                           carrying, in whatever spelling it reports them.
#     expires            :: Hash ref of canonical IP to the epoch its sentence
#                           ends, 0 meaning never. Keyed off the ban book, so
#                           a firewall entry the book does not know about has
#                           no key here.
#     banned_cidr        :: Array ref of the ranges the firewall is carrying.
#     cidr_expires       :: The range equivalent of expires.
#     unban_retries      :: Hash ref from _retry_details for the IP family,
#                           each key an entry still owed to the firewall.
#     cidr_unban_retries :: The range equivalent.
#
# Dies only if listing the backend fails, that being a bare _backend_do call.
#
#     my $result = $self->_cmd_banned;
#     # $result is {
#     #     banned => ['1.2.3.4'], expires => { '1.2.3.4' => 1785919052 },
#     #     banned_cidr => [], cidr_expires => {},
#     #     unban_retries => {}, cidr_unban_retries => {},
#     # }
sub _cmd_banned {
	my ($self) = @_;

	my @banned = $self->_backend_do('list');

	my $expires = {};
	foreach my $ip ( keys( %{ $self->{bans} } ) ) {
		$expires->{$ip} = $self->{bans}{$ip}{expires};
	}

	# list_cidr is safe on every backend, returning empty on the ones that do
	# not do CIDR, so there is no need to gate this on _cidr_available
	my @banned_cidr = $self->_backend_do('list_cidr');

	my $cidr_expires = {};
	foreach my $cidr ( keys( %{ $self->{cidr_bans} } ) ) {
		$cidr_expires->{$cidr} = $self->{cidr_bans}{$cidr}{expires};
	}

	return {
		'banned'             => \@banned,
		'expires'            => $expires,
		'banned_cidr'        => \@banned_cidr,
		'cidr_expires'       => $cidr_expires,
		'unban_retries'      => $self->_retry_details( $family_spec{ip} ),
		'cidr_unban_retries' => $self->_retry_details( $family_spec{cidr} ),
	};
} ## end sub _cmd_banned

# Flattens one family's retry book into the shape the banned command reports,
# a plain hash of entry to its counts and times. It exists so the wire format
# is decided in one place rather than in the command handler, and so the
# delay field stays internal... that is the backoff's own book keeping and
# means nothing to a client, next_try already saying when the entry is due.
#
# These are unbans still owed to the firewall, deliberately reported
# separately rather than folded into the banned lists, which are what the
# firewall is carrying on this kur's behalf.
#
# Args, one required...
#
#     $spec :: One of the %family_spec entries described above. Uses only
#              retry_hash.
#
# Returns a hash ref keyed by canonical entry, empty when nothing is owed.
# Each value is a hash ref of...
#
#     first_tried :: Epoch the unban first failed, so the age of the debt.
#     last_tried  :: Epoch of the most recent attempt.
#     times_tried :: How many attempts have been made, counting the one at
#                    expiry, so it is at least 1.
#     next_try    :: Epoch the next attempt is due. A value in the past means
#                    it is due at the next sweep.
#
# Does not die.
#
#     my $owed = $self->_retry_details( $family_spec{ip} );
#     # $owed is {
#     #     '1.2.3.4' => {
#     #         first_tried => 1785918152, last_tried => 1785919052,
#     #         times_tried => 9,          next_try    => 1785919112,
#     #     },
#     # }
sub _retry_details {
	my ( $self, $spec ) = @_;

	my $details = {};
	foreach my $entry ( keys( %{ $self->{ $spec->{retry_hash} } } ) ) {
		my $retry = $self->{ $spec->{retry_hash} }{$entry};
		$details->{$entry} = {
			'first_tried' => $retry->{first_tried},
			'last_tried'  => $retry->{last_tried},
			'times_tried' => $retry->{times_tried},
			'next_try'    => $retry->{next_try},
		};
	}

	return $details;
} ## end sub _retry_details

# Finds the first_tried of the longest owed retry in one family, which is the
# single number that tells an operator whether the backend is having a brief
# moment or has been refusing since last week. status reports it so that
# question can be answered without pulling the whole per entry list out of
# banned.
#
# Args, one required...
#
#     $spec :: One of the %family_spec entries described above. Uses only
#              retry_hash.
#
# Returns the epoch of the oldest first_tried across that family's retry
# book, as an integer, or 0 when nothing is owed. 0 is unambiguous here since a
# real first_tried is an epoch, so a caller can test it as a boolean for
# anything owed at all.
#
# Does not die.
#
#     my $oldest = $self->_retries_oldest( $family_spec{ip} );
#     # 0 with a clean book, or something like 1785918152 with a debt
#     # first taken on at that time
sub _retries_oldest {
	my ( $self, $spec ) = @_;

	my $oldest = 0;
	foreach my $entry ( keys( %{ $self->{ $spec->{retry_hash} } } ) ) {
		my $first_tried = $self->{ $spec->{retry_hash} }{$entry}{first_tried};
		if ( !$oldest || $first_tried < $oldest ) {
			$oldest = $first_tried;
		}
	}

	return $oldest;
} ## end sub _retries_oldest

# Handles the status command off the socket, the summary view of this kur...
# how it is configured, what it has been doing, and how much it is holding.
# The counts come from the firewall while the timed versus permanent split
# comes from the ban books, since only the books know about sentences.
#
# Takes no arguments beyond the invocant. Read only, so deliberately not
# gated on _refuse_when_stopping.
#
# Returns a hash ref carrying the instance settings as given, name, backend,
# ports, protocols, prefix, ban_time and checkpoint, along with...
#
#     last_checkpoint           :: Epoch of the last successful ban tablet
#                                  write, 0 if there has not been one.
#     pid                       :: This kur process's PID.
#     uptime                    :: Seconds since the server came up.
#     stats                     :: The live stats hash ref, counting bans,
#                                  unbans, cidr_bans, cidr_unbans, errors,
#                                  expired, and cidr_expired.
#     banned_count              :: How many single IPs the firewall carries.
#     bans_timed                :: How many of the booked IP bans expire.
#     bans_permanent            :: How many never do.
#     next_expiry               :: Soonest epoch any sentence ends, across
#                                  BOTH families, 0 when everything is
#                                  permanent or nothing is banned.
#     cidr_enabled              :: Whether the operator opted in to ranges.
#     cidr_supported            :: Whether the backend can carry them.
#     cidr_banned_count         :: How many ranges the firewall carries.
#     cidr_bans_timed           :: How many booked range bans expire.
#     cidr_bans_permanent       :: How many never do.
#     unban_retries             :: How many unbans are still owed to the
#                                  firewall on the IP side.
#     unban_retries_oldest      :: first_tried of the longest owed of those,
#                                  0 when none, from _retries_oldest.
#     cidr_unban_retries        :: The range equivalent of unban_retries.
#     cidr_unban_retries_oldest :: The range equivalent of the above.
#
# Dies only if listing the backend fails, that being a bare _backend_do call.
#
#     my $status = $self->_cmd_status;
#     # $status->{banned_count} is 3, $status->{unban_retries} is 0, ...
sub _cmd_status {
	my ($self) = @_;

	my @banned = $self->_backend_do('list');

	my $timed       = 0;
	my $permanent   = 0;
	my $next_expiry = 0;
	foreach my $ip ( keys( %{ $self->{bans} } ) ) {
		if ( $self->{bans}{$ip}{expires} ) {
			$timed++;
			if ( !$next_expiry || $self->{bans}{$ip}{expires} < $next_expiry ) {
				$next_expiry = $self->{bans}{$ip}{expires};
			}
		} else {
			$permanent++;
		}
	} ## end foreach my $ip ( keys( %{ $self->{bans} } ) )

	my @banned_cidr    = $self->_backend_do('list_cidr');
	my $cidr_timed     = 0;
	my $cidr_permanent = 0;
	foreach my $cidr ( keys( %{ $self->{cidr_bans} } ) ) {
		if ( $self->{cidr_bans}{$cidr}{expires} ) {
			$cidr_timed++;
			if ( !$next_expiry || $self->{cidr_bans}{$cidr}{expires} < $next_expiry ) {
				$next_expiry = $self->{cidr_bans}{$cidr}{expires};
			}
		} else {
			$cidr_permanent++;
		}
	} ## end foreach my $cidr ( keys( %{ $self->{cidr_bans} ...}))

	return {
		'name'                => $self->{name},
		'backend'             => $self->{backend},
		'ports'               => $self->{ports},
		'protocols'           => $self->{protocols},
		'prefix'              => $self->{prefix},
		'ban_time'            => $self->{ban_time},
		'checkpoint'          => $self->{checkpoint},
		'last_checkpoint'     => $self->{last_checkpoint},
		'pid'                 => $$,
		'uptime'              => time - $self->{started},
		'stats'               => $self->{stats},
		'banned_count'        => scalar(@banned),
		'bans_timed'          => $timed,
		'bans_permanent'      => $permanent,
		'next_expiry'         => $next_expiry,
		'cidr_enabled'        => $self->{enable_cidr},
		'cidr_supported'      => $self->{cidr_supported},
		'cidr_banned_count'   => scalar(@banned_cidr),
		'cidr_bans_timed'     => $cidr_timed,
		'cidr_bans_permanent' => $cidr_permanent,
		# unbans that failed at expiry and are still owed to the firewall...
		# oldest is the first_tried of the longest owed, so an operator can
		# tell a blip from something wedged without asking for banned
		'unban_retries'             => scalar( keys( %{ $self->{unban_retries} } ) ),
		'unban_retries_oldest'      => $self->_retries_oldest( $family_spec{ip} ),
		'cidr_unban_retries'        => scalar( keys( %{ $self->{cidr_unban_retries} } ) ),
		'cidr_unban_retries_oldest' => $self->_retries_oldest( $family_spec{cidr} ),
	};
} ## end sub _cmd_status

# Handles the flush command off the socket, emptying this kur entirely. The
# manager drives it from unban --all, which is the only way a client reaches
# it... there is no flush subcommand of its own.
#
# The backend's flush clears both single IP and range rules in one go, so
# both ban books are emptied alongside it rather than being unbanned one at a
# time. Both retry books go too... a debt is a rule the firewall was still
# carrying, and flush has just removed every rule this kur owns, so nothing
# is owed any more. All four tablets are then rewritten, which is what stops a
# restart bringing any of it back.
#
# Takes no arguments beyond the invocant.
#
# Returns a hash ref of { flushed => 1 }. There is no count... the backend's
# flush does not report one, and the book sizes before the wipe would not
# necessarily match what the firewall actually removed.
#
# Dies if the kur is stopping, or if the backend refuses the flush, in which
# case nothing is emptied... the books and tablets are only touched after the
# backend has agreed.
#
#     my $result = $self->_cmd_flush;
#     # $result is { flushed => 1 } and this kur now holds nothing
sub _cmd_flush {
	my ($self) = @_;

	$self->_refuse_when_stopping;

	# the backend flush clears both single IP and CIDR rules, so the CIDR
	# tracking is cleared and checkpointed alongside the single IP tracking,
	# and pending unban retries are moot
	$self->_backend_do('flush');
	$self->{bans}               = {};
	$self->{cidr_bans}          = {};
	$self->{unban_retries}      = {};
	$self->{cidr_unban_retries} = {};
	$self->_checkpoint;
	$self->_checkpoint_cidr;
	$self->_checkpoint_retries;
	$self->_checkpoint_cidr_retries;
	log_drek( 'info', 'flushed all bans', undef, 'kur-' . $self->{name} );

	return { 'flushed' => 1 };
} ## end sub _cmd_flush

# Handles the re_init command off the socket, the repair for a firewall setup
# something outside Ereshkigal has interfered with... a shorewall restart, a
# pf -F all, a firewalld reload, a hand flushed ipset. The backend tears its
# table, set, chain or list down and builds it again, then re-bans everything
# the ban books carry, so the books are the authority and the firewall is
# brought back into line with them.
#
# Bans are not enforced for the moment the rebuild takes, which is brief but
# real, and is the reason this is a command rather than something done
# routinely.
#
# Both retry books are emptied afterwards and their tablets rewritten,
# because tearing the setup down takes any rule a failed unban left orphaned
# in it... those debts have just been settled by the teardown itself. Only the
# books are re-banned, so nothing that was owed comes back.
#
# Takes no arguments beyond the invocant.
#
# Returns a hash ref of { re_init => 1 }.
#
# Dies if the kur is stopping, or if the backend's re_init fails, in which
# case the retry books are left alone... a failed rebuild may well have left
# the orphaned rules exactly where they were.
#
#     my $result = $self->_cmd_re_init;
#     # $result is { re_init => 1 } and the firewall matches the books again
sub _cmd_re_init {
	my ($self) = @_;

	$self->_refuse_when_stopping;

	# re_init tears down and re-bans only what the book carries, so anything
	# pending an unban retry is no longer in the firewall
	$self->_backend_do('re_init');
	$self->{unban_retries}      = {};
	$self->{cidr_unban_retries} = {};
	$self->_checkpoint_retries;
	$self->_checkpoint_cidr_retries;
	log_drek( 'info', 're_init done', undef, 'kur-' . $self->{name} );

	return { 're_init' => 1 };
} ## end sub _cmd_re_init

# Handles the clear_retries command off the socket, forgetting unbans still
# owed to the firewall. This is the escape hatch for a debt that will never be
# paid, the rule having been removed by hand or the entry having never
# existed as far as the backend is concerned, which would otherwise be
# retried at the 60 second cap forever.
#
# Forgetting a debt does not touch the firewall at all... it only stops this
# kur asking. Anything genuinely still in place stays in place, with nothing
# tracking it, which is why the documentation points people at unban or
# re_init first.
#
# Both families are walked. Naming an entry of one family leaves the other
# entirely alone, rather than clearing it wholesale, which is what the
# other_family_named check is for... without it, naming an ip would empty the
# whole CIDR book as a side effect.
#
# Args, one required...
#
#     $request :: The request hash ref as it came off the socket. A missing
#                 args is fine and means clear everything. args.ip and
#                 args.cidr are both optional, at most one may be given, and
#                 each must be a plain scalar naming a single entry of that
#                 family. Either is normalized before the lookup, since the
#                 retry books are keyed canonically, so naming a variant
#                 spelling still finds the debt. Neither given means every
#                 debt in both families goes.
#
# Returns a hash ref of...
#
#     cleared      :: Total entries forgotten across both families.
#     cleared_ip   :: How many on the single IP side... 1 or 0 when an ip was
#                     named, otherwise however many the book held.
#     cleared_cidr :: The range equivalent.
#
# All three are 0 when nothing was owed, which is not an error... clearing a
# entry that is not owed is a no-op rather than a failure.
#
# Dies if both args.ip and args.cidr are given, if a named entry is a ref, or
# if a named entry will not normalize. Deliberately not gated on
# _refuse_when_stopping, as it touches only book keeping.
#
#     my $result = $self->_cmd_clear_retries( {} );
#     # $result is { cleared => 3, cleared_ip => 2, cleared_cidr => 1 }
#
#     my $result = $self->_cmd_clear_retries(
#         { 'args' => { 'ip' => '1.2.3.4' } }
#     );
#     # $result is { cleared => 1, cleared_ip => 1, cleared_cidr => 0 }
sub _cmd_clear_retries {
	my ( $self, $request ) = @_;

	my $args = defined( $request->{args} ) ? $request->{args} : {};

	if ( defined( $args->{ip} ) && defined( $args->{cidr} ) ) {
		die('only one of args.ip and args.cidr may be given');
	}

	my $ident   = 'kur-' . $self->{name};
	my $cleared = { 'ip' => 0, 'cidr' => 0 };

	foreach my $family ( 'ip', 'cidr' ) {
		my $spec               = $family_spec{$family};
		my $named              = $args->{ $spec->{retry_arg} };
		my $other_family_named = defined( $args->{ $family_spec{ $family eq 'ip' ? 'cidr' : 'ip' }->{retry_arg} } );

		# a named entry only clears from its own family, and naming one
		# family means the other is left alone entirely
		if ( defined($named) ) {
			if ( ref($named) ne '' ) {
				die( 'args.' . $spec->{retry_arg} . ' must be a single ' . $spec->{noun} );
			}
			my $entry = $spec->{normalizer}->($named);
			if ( !defined($entry) ) {
				die(      'args.'
						. $spec->{retry_arg} . ', "'
						. $named
						. '", does not appear to be an IPv4 or IPv6 '
						. $spec->{noun} );
			}
			if ( defined( delete( $self->{ $spec->{retry_hash} }{$entry} ) ) ) {
				$cleared->{$family} = 1;
				my $retry_checkpoint_method = $spec->{retry_checkpoint};
				$self->$retry_checkpoint_method;
				log_drek( 'info', 'forgot the owed unban of ' . $spec->{infix} . $entry, undef, $ident );
			}
			next;
		} ## end if ( defined($named) )

		next if ($other_family_named);

		my $count = scalar( keys( %{ $self->{ $spec->{retry_hash} } } ) );
		if ($count) {
			$self->{ $spec->{retry_hash} } = {};
			$cleared->{$family} = $count;
			my $retry_checkpoint_method = $spec->{retry_checkpoint};
			$self->$retry_checkpoint_method;
			log_drek( 'info', 'forgot ' . $count . ' owed ' . $spec->{infix} . 'unbans', undef, $ident );
		}
	} ## end foreach my $family ( 'ip', 'cidr' )

	return {
		'cleared'      => $cleared->{ip} + $cleared->{cidr},
		'cleared_ip'   => $cleared->{ip},
		'cleared_cidr' => $cleared->{cidr},
	};
} ## end sub _cmd_clear_retries

# Handles the checkpoint command off the socket, forcing all four tablets out
# now. The tablets are already written on every mutation and every checkpoint
# seconds, so this is rarely needed... it is here for taking a consistent
# snapshot before a backup or a look at the files by hand.
#
# Takes no arguments beyond the invocant. Deliberately not gated on
# _refuse_when_stopping, as writing tablets is safe at any point and stop
# does exactly this on its way out.
#
# Returns a hash ref of...
#
#     checkpointed       :: Always 1. There is no failure answer... a tablet
#                           write that fails logs and counts an error rather
#                           than reporting back, so this says the command ran,
#                           not that all four files landed.
#     bans               :: How many single IP bans the book holds.
#     cidr_bans          :: How many range bans it holds.
#     unban_retries      :: How many single IP unbans are still owed.
#     cidr_unban_retries :: How many range unbans are still owed.
#
# The counts come from the books rather than the files, so they say what was
# meant to be written.
#
# Does not die.
#
#     my $result = $self->_cmd_checkpoint;
#     # $result is {
#     #     checkpointed => 1, bans => 12, cidr_bans => 2,
#     #     unban_retries => 0, cidr_unban_retries => 0,
#     # }
sub _cmd_checkpoint {
	my ($self) = @_;

	$self->_checkpoint;
	$self->_checkpoint_cidr;
	$self->_checkpoint_retries;
	$self->_checkpoint_cidr_retries;
	log_drek( 'info', 'checkpointed', undef, 'kur-' . $self->{name} );

	return {
		'checkpointed'       => 1,
		'bans'               => scalar( keys( %{ $self->{bans} } ) ),
		'cidr_bans'          => scalar( keys( %{ $self->{cidr_bans} } ) ),
		'unban_retries'      => scalar( keys( %{ $self->{unban_retries} } ) ),
		'cidr_unban_retries' => scalar( keys( %{ $self->{cidr_unban_retries} } ) ),
	};
} ## end sub _cmd_checkpoint

# Handles the stop command off the socket. Unlike every other handler this one
# answers the client itself rather than returning a result to be sent, because
# the response has to be flushed before the shutdown takes the server session
# down with it... returning normally would have the session torn down first
# and the client left hanging. Returning undef is how the JSONUnix handler
# protocol says the handler has already responded.
#
# The teardown happens through _stop_guts, shared with the signal handler, so
# a stop command and a SIGTERM leave the kur in the same state. A teardown
# failure does not stop the shutdown... the process is going either way, so
# the error is reported to the client and logged rather than being allowed to
# strand the kur half up.
#
# Args, one required...
#
#     $ctx :: The POE::Component::Server::JSONUnix per request context object
#             for the connection, handed to the handler by the server. Used
#             for respond_result to send the answer and close to hang up. It
#             must be this request's own context, as that is the connection
#             the answer belongs to.
#
# Returns undef, always, which the server reads as the handler having dealt
# with the response itself.
#
# Does not die. The teardown error, if there was one, reaches the client as a
# teardown_error field alongside stopping => 1, so a client can tell a clean
# stop from a messy one. The shutdown is posted with a one second delay to
# give that response time to flush.
#
#     # from the server's command dispatch table
#     'stop' => sub {
#         my ( undef, undef, $ctx ) = @_;
#         return $self->_cmd_stop($ctx);
#     },
sub _cmd_stop {
	my ( $self, $ctx ) = @_;

	log_drek( 'info', 'stop requested, tearing the backend down', undef, 'kur-' . $self->{name} );

	my $teardown_error = $self->_stop_guts;

	$ctx->respond_result( { 'stopping' => 1, $teardown_error ? ( 'teardown_error' => $teardown_error ) : () } );
	$ctx->close;

	# the current session is the JSONUnix server session, so this fires its
	# shutdown state after the response has had time to flush
	$poe_kernel->delay( 'shutdown', 1 );

	return undef;
} ## end sub _cmd_stop

# The common guts of stopping, shared by the stop command and the TERM/INT
# handler so a signaled kur leaves exactly the state an asked one does...
# tablets on disk and the firewall setup torn down, rather than the process
# dying with its rules dangling.
#
# It sets stopping first, which stops the sweeper rescheduling so its session
# can end and takes _refuse_when_stopping's guard live, then writes all four
# tablets before touching the backend, so the state is safe on disk even if
# the teardown goes badly.
#
# A successful teardown empties both retry books and rewrites their tablets,
# because tearing down takes the whole setup with it, orphaned rules
# included... anything that was owed has just been paid, and leaving the
# tablets in place would have the next run retrying unbans for rules that no
# longer exist. A failed teardown keeps those debts, as it may well have left
# the rules exactly where they were.
#
# Takes no arguments beyond the invocant.
#
# Returns the teardown error as a string when the backend refused to tear
# down, or the empty string when it went cleanly. Callers test it as a boolean
# and pass it on... _cmd_stop puts it in the response, the signal handler
# ignores it, both having logged it here.
#
# Does not die. The teardown is wrapped precisely so a failure cannot strand
# a kur half stopped.
#
#     my $teardown_error = $self->_stop_guts;
#     if ($teardown_error) {
#         # went down messy, the firewall may still carry rules
#     }
sub _stop_guts {
	my ($self) = @_;

	# keeps the ban sweeper from rescheduling so its session can end
	$self->{stopping} = 1;

	# leave a fresh state CSV behind
	$self->_checkpoint;
	$self->_checkpoint_cidr;
	$self->_checkpoint_retries;
	$self->_checkpoint_cidr_retries;

	eval { $self->_backend_do('teardown'); };
	my $teardown_error = $@;
	if ($teardown_error) {
		log_drek( 'err', 'teardown failed... ' . $teardown_error, undef, 'kur-' . $self->{name} );
	} else {
		# teardown takes the whole firewall setup with it, orphaned rules
		# included, so anything that was owed has just been paid... left in
		# place the tablets would have the next run retrying unbans for
		# rules that no longer exist. a failed teardown may well have left
		# them there, so those debts are kept
		$self->{unban_retries}      = {};
		$self->{cidr_unban_retries} = {};
		$self->_checkpoint_retries;
		$self->_checkpoint_cidr_retries;
	} ## end else [ if ($teardown_error) ]

	return $teardown_error;
} ## end sub _stop_guts

# The body of the once a second sweeper alarm started by start_server, and
# the only thing in this module that happens without a client asking for it.
# Everything time driven hangs off here... sentences being served, unban
# retries coming due, and the periodic tablet rewrite.
#
# The sweep runs every tick, while the checkpoint only runs once the
# configured interval has passed since the last successful one, so a busy kur
# is not rewriting four files a second. A checkpoint of 0 disables the
# periodic rewrite entirely, mutations and stop still writing as they go.
#
# Takes no arguments beyond the invocant. The session calling it has already
# checked stopping, so this does not.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, and must not... a die here would take the sweeper session
# down and leave sentences running forever. _sweep_family wraps every backend
# call, and the checkpoints report failure by logging rather than throwing.
#
#     # from the sweeper session
#     'sweep' => sub {
#         return if $self->{stopping};
#         $self->_tick;
#         $_[KERNEL]->delay( 'sweep', 1 );
#     },
sub _tick {
	my ($self) = @_;

	$self->_sweep_bans;

	if ( $self->{checkpoint} && ( time - $self->{last_checkpoint} ) >= $self->{checkpoint} ) {
		$self->_checkpoint;
		$self->_checkpoint_cidr;
		$self->_checkpoint_retries;
		$self->_checkpoint_cidr_retries;
	}

	return;
} ## end sub _tick

# Runs the expiry sweep over both families, which is all it does... the work
# is _sweep_family's, this just saves _tick from knowing there are two
# families to walk.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, _sweep_family wrapping every backend call it makes.
#
#     $self->_sweep_bans;
sub _sweep_bans {
	my ($self) = @_;

	foreach my $family ( 'ip', 'cidr' ) {
		$self->_sweep_family( $family_spec{$family} );
	}

	return;
}

# The shared per family sweep, and where a sentence actually ends. It has two
# halves, both driven off the same current time.
#
# First, every booked entry whose expiry has passed is unbanned via the
# backend and dropped from the book. The drop happens whether or not the
# backend took it... the sentence has been served either way, and a book
# still claiming a ban the kur has finished with would just feed this same
# loop a doomed unban every second. What a refused unban leaves behind
# instead is an entry in the retry book, so the debt to the firewall is
# remembered rather than the rule being orphaned silently.
#
# Second, every retry that has come due is attempted again. A success drops
# it; a failure bumps the counts and pushes next_try out by the current delay,
# doubling that delay to a cap of 60 seconds, the same backoff shape the
# manager uses for respawning a dead kur. Nothing here ever gives up... a debt
# that can never be paid is cleared by the clear_retries command, by a
# re-ban, or by a teardown, not by this loop deciding it has tried enough.
#
# The two tablets are written at most once each per call, and only when
# something actually changed, which is why the two changed flags exist rather
# than checkpointing inside the loops.
#
# Args, one required...
#
#     $spec :: One of the %family_spec entries described above. Uses hash,
#              retry_hash, unban_method, expired_stat, log_label, checkpoint,
#              and retry_checkpoint.
#
# Returns nothing meaningful, an empty return. What it did is visible in the
# books, the stats, and the log.
#
# Does not die. Every backend call is wrapped, since this runs off a POE
# alarm where a die would take the sweeper session down and leave every
# remaining sentence running forever. A refused unban counts an error and
# becomes a retry instead.
#
#     $self->_sweep_family( $family_spec{ip} );
#
#     $self->_sweep_family( $family_spec{cidr} );
sub _sweep_family {
	my ( $self, $spec ) = @_;

	my $ident         = 'kur-' . $self->{name};
	my $now           = time;
	my $changed       = 0;
	my $retry_changed = 0;

	foreach my $banned_entry ( keys( %{ $self->{ $spec->{hash} } } ) ) {
		my $entry = $self->{ $spec->{hash} }{$banned_entry};
		if ( !$entry->{expires} || $entry->{expires} > $now ) {
			next;
		}

		eval { $self->_backend_do( $spec->{unban_method}, ban => $banned_entry ); };
		if ($@) {
			$self->{stats}{errors}++;
			# the sentence is still considered served... the firewall side is
			# left to the retry loop below rather than staying orphaned there
			$self->{ $spec->{retry_hash} }{$banned_entry} = {
				'first_tried' => $now,
				'last_tried'  => $now,
				'times_tried' => 1,
				'next_try'    => $now + 1,
				'delay'       => 2,
			};
			$retry_changed = 1;
			log_drek(
				'err',
				'unbanning expired '
					. $spec->{log_label} . ' of "'
					. $banned_entry
					. '" failed, will retry... '
					. $@,
				undef,
				$ident
			);
		} ## end if ($@)
		delete( $self->{ $spec->{hash} }{$banned_entry} );
		$self->{stats}{ $spec->{expired_stat} }++;
		$changed = 1;
		log_drek( 'info', $spec->{log_label} . ' of ' . $banned_entry . ' expired', undef, $ident );
	} ## end foreach my $banned_entry ( keys( %{ $self->{ $spec...}}))

	# retries unbans that failed at expiry, backing off with the same
	# doubling to a cap of 60 seconds the manager uses for respawns... a
	# re-ban via _ban_many cancels the entry instead
	foreach my $retry_entry ( keys( %{ $self->{ $spec->{retry_hash} } } ) ) {
		my $retry = $self->{ $spec->{retry_hash} }{$retry_entry};
		if ( $retry->{next_try} > $now ) {
			next;
		}

		eval { $self->_backend_do( $spec->{unban_method}, ban => $retry_entry ); };
		if ($@) {
			$self->{stats}{errors}++;
			$retry->{last_tried} = $now;
			$retry->{times_tried}++;
			$retry->{next_try} = $now + $retry->{delay};
			$retry->{delay}    = $retry->{delay} * 2 > 60 ? 60 : $retry->{delay} * 2;
			$retry_changed     = 1;
			log_drek(
				'err',
				'unban retry '
					. $retry->{times_tried} . ' for '
					. $spec->{log_label} . ' of "'
					. $retry_entry
					. '" failed... '
					. $@,
				undef,
				$ident
			);
		} else {
			delete( $self->{ $spec->{retry_hash} }{$retry_entry} );
			$retry_changed = 1;
			log_drek( 'info', 'unban retry for ' . $spec->{log_label} . ' of ' . $retry_entry . ' succeeded',
				undef, $ident );
		}
	} ## end foreach my $retry_entry ( keys( %{ $self->{ $spec...}}))

	if ($changed) {
		my $checkpoint_method = $spec->{checkpoint};
		$self->$checkpoint_method;
	}
	if ($retry_changed) {
		my $retry_checkpoint_method = $spec->{retry_checkpoint};
		$self->$retry_checkpoint_method;
	}

	return;
} ## end sub _sweep_family

# Writes the single IP ban tablet, and the only one of the four checkpoint
# wrappers that tracks when it last succeeded... _tick measures the periodic
# interval against last_checkpoint, so it is deliberately only bumped on a
# successful write. A failing tablet therefore has the periodic timer trying
# again every tick rather than waiting out the interval each time.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return. Whether the write landed is
# visible in $self->{last_checkpoint} and, on failure, the log and the error
# stat.
#
# Does not die, _write_state reporting failure by returning false.
#
#     $self->_checkpoint;
sub _checkpoint {
	my ($self) = @_;

	my $now = time;
	if ( $self->_write_state( $self->state_path, $self->{bans}, $now, 'ip' ) ) {
		$self->{last_checkpoint} = $now;
	}

	return;
} ## end sub _checkpoint

# Writes the range ban tablet, the sibling of _checkpoint. The two families
# keep separate files so the single IP tablet's format stayed exactly as it
# was before ranges existed, rather than growing a family column that older
# state would not carry.
#
# It does not touch last_checkpoint... that is _checkpoint's alone, the two
# being written together everywhere so one timestamp covers both.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, _write_state reporting failure by returning false.
#
#     $self->_checkpoint_cidr;
sub _checkpoint_cidr {
	my ($self) = @_;

	$self->_write_state( $self->cidr_state_path, $self->{cidr_bans}, time, 'cidr' );

	return;
}

# Writes the single IP unban retry tablet, so a debt to the firewall survives
# a restart... the rule is still in place after one, so the obligation is
# just as real. It is a separate file from the ban tablet because the two hold
# different things: one is who is banned, the other is who should not be but
# still is.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, _write_retry_state reporting failure by returning false.
#
#     $self->_checkpoint_retries;
sub _checkpoint_retries {
	my ($self) = @_;

	$self->_write_retry_state( $family_spec{ip} );

	return;
}

# Writes the range unban retry tablet, mirroring _checkpoint_retries for the
# other family. The four checkpoint wrappers exist as named methods rather
# than the callers reaching for _write_state and _write_retry_state directly
# because %family_spec stores them by name, so a shared helper can write the
# right family's tablet without knowing which family it is working on.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, _write_retry_state reporting failure by returning false.
#
#     $self->_checkpoint_cidr_retries;
#
#     # or reached by name from a shared helper
#     my $method = $spec->{retry_checkpoint};
#     $self->$method;
sub _checkpoint_cidr_retries {
	my ($self) = @_;

	$self->_write_retry_state( $family_spec{cidr} );

	return;
}

# Writes one family's retry book out as a CSV, the debts owed to the firewall
# made durable. Atomic the same way _write_state is, a temp file in the same
# directory renamed over the target, so a reader never sees a half written
# tablet and a failure leaves the last good one in place.
#
# The times are stored absolute rather than as a remaining figure, unlike the
# ban tablet's ban_time_left. A debt has no sentence to re-anchor against...
# it is simply owed until paid, and a next_try left in the past after a long
# downtime just means the retry is due at once, which is the wanted behavior.
#
# An empty retry book unlinks the tablet rather than leaving a header only file
# behind, so the file existing at all means something is owed. That is worth
# knowing before changing it, as an operator can and does check for the file.
#
# The row format, one per debt, after a header line of
# <label>,first_tried,last_tried,times_tried,next_try,delay ...
#
#     <entry>,<first_tried>,<last_tried>,<times_tried>,<next_try>,<delay>
#
# with the entry in canonical form and the rest integers, the times epochs and
# delay the seconds the backoff had reached. Rows are sorted by entry so the
# file is stable between writes and diffs cleanly.
#
# Args, one required...
#
#     $spec :: One of the %family_spec entries described above. Uses
#              retry_path, retry_hash, label, and infix.
#
# Returns 1 on success, including the nothing owed case where the file was
# removed or was already absent, and 0 when the write failed, having logged
# it and counted an error. Every caller ignores the return, the logging being
# the real reporting, but it is there for one that wants it.
#
# Does not die. An open, print, close, rename or unlink failure is caught,
# logged, counted, and reported by the return value... a tablet write is
# housekeeping and must never take down a ban or a sweep.
#
#     $self->_write_retry_state( $family_spec{ip} );
#     # writes /var/cache/ereshkigal/kur.<name>.retry.csv, or removes it when
#     # nothing is owed
sub _write_retry_state {
	my ( $self, $spec ) = @_;

	my $path_method = $spec->{retry_path};
	my $state_file  = $self->$path_method;
	my $retries     = $self->{ $spec->{retry_hash} };

	if ( !%{$retries} ) {
		if ( -e $state_file && !unlink($state_file) ) {
			$self->{stats}{errors}++;
			log_drek( 'err',
				'removing the empty ' . $spec->{infix} . 'retry tablet "' . $state_file . '" failed... ' . $!,
				undef, 'kur-' . $self->{name} );
		}
		return 1;
	}

	my $tmp_file = $state_file . '.tmp';
	eval {
		open( my $fh, '>', $tmp_file ) || die( 'open failed... ' . $! );
		print $fh $spec->{label} . ",first_tried,last_tried,times_tried,next_try,delay\n";
		foreach my $key ( sort( keys( %{$retries} ) ) ) {
			my $retry = $retries->{$key};
			print $fh join( ',',
				$key,                  $retry->{first_tried}, $retry->{last_tried},
				$retry->{times_tried}, $retry->{next_try},    $retry->{delay} ) . "\n";
		}
		# as with the ban tablets, buffered print failures only surface at
		# close, and skipping the rename keeps the last good file in place
		close($fh)                       || die( 'close failed... ' . $! );
		rename( $tmp_file, $state_file ) || die( 'rename failed... ' . $! );
	};
	if ($@) {
		unlink($tmp_file);
		$self->{stats}{errors}++;
		log_drek( 'err',
			'checkpointing ' . $spec->{infix} . 'unban retry state to "' . $state_file . '" failed... ' . $@,
			undef, 'kur-' . $self->{name} );
		return 0;
	}

	return 1;
} ## end sub _write_retry_state

# Writes one family's ban book out as a CSV, which is what makes a timed ban
# survive a restart with the right time left on it. Shared by both ban
# checkpoints, the only difference between them being the file, the hash, and
# the first column's name, which is why this takes them as arguments rather
# than a $spec.
#
# Atomic... everything is written to a temp file beside the target and renamed
# over it, so a reader never sees a partial tablet. The close is checked as
# well as the open, because buffered print failures, a full filesystem being
# the usual one, only surface when the handle is closed; skipping the rename
# on any failure keeps the previous good tablet rather than replacing it with
# a truncated one.
#
# The row format, one per ban, after a header line of
# <label>,time,ban_time_left ...
#
#     <entry>,<written>,<left>
#
# where written is the epoch this write happened and left is the seconds of
# sentence remaining at that moment, 0 meaning the ban never expires. Storing
# it relative rather than as an expiry epoch is what lets a restored ban serve
# out its remaining time rather than being anchored to a clock that may have
# moved. A ban expiring within the same second is clamped to 1 rather than
# rounding to 0, since 0 is spoken for by permanent... anything genuinely
# expired is the sweeper's business, not this one's. Rows are sorted by entry
# so the file is stable between writes.
#
# Args, all four required and positional...
#
#     $state_file :: Full path of the tablet to write. The temp file is this
#                    with .tmp appended, so the directory has to be writable.
#     $bans       :: The ban book to write, a hash ref of canonical entry to
#                    { banned_at => epoch, expires => epoch or 0 }. Only
#                    expires is read. An empty hash writes a header only file
#                    rather than removing it, unlike the retry tablets.
#     $now        :: Epoch to record as the write time and to measure each
#                    remaining sentence against. Passed in rather than taken
#                    here so every row of one write agrees.
#     $label      :: Name for the first column, 'ip' or 'cidr'. It is also
#                    what the loader matches to recognise the header line.
#
# Returns 1 on success and 0 on failure, having logged the failure and
# counted an error. _checkpoint uses that to decide whether to bump
# last_checkpoint.
#
# Does not die, for the same reason _write_retry_state does not.
#
#     $self->_write_state(
#         $self->state_path, $self->{bans}, time, 'ip'
#     );
sub _write_state {
	my ( $self, $state_file, $bans, $now, $label ) = @_;

	my $tmp_file = $state_file . '.tmp';
	eval {
		open( my $fh, '>', $tmp_file ) || die( 'open failed... ' . $! );
		print $fh $label . ",time,ban_time_left\n";
		foreach my $key ( sort( keys( %{$bans} ) ) ) {
			my $left = 0;
			if ( $bans->{$key}{expires} ) {
				$left = $bans->{$key}{expires} - $now;
				# clamped so a nearly expired ban can't collide with 0 meaning
				# permanent... anything actually expired is the sweeper's job
				if ( $left < 1 ) {
					$left = 1;
				}
			}
			print $fh $key . ',' . $now . ',' . $left . "\n";
		} ## end foreach my $key ( sort( keys( %{$bans} ) ) )
		# checked as buffered print failures, a full filesystem for example,
		# only surface here... skipping the rename keeps the previous good
		# state file in place rather than replacing it with a truncated one
		close($fh)                       || die( 'close failed... ' . $! );
		rename( $tmp_file, $state_file ) || die( 'rename failed... ' . $! );
	};
	if ($@) {
		unlink($tmp_file);
		$self->{stats}{errors}++;
		log_drek( 'err', 'checkpointing ' . $label . ' ban state to "' . $state_file . '" failed... ' . $@,
			undef, 'kur-' . $self->{name} );
		return 0;
	}

	return 1;
} ## end sub _write_state

# Restores the single IP ban book from its tablet at startup, which is what
# makes a restart invisible to anyone serving a sentence. Called from new
# once the backend is up, so the re-bans it drives land on a freshly inited
# firewall.
#
# The work is _load_state's. This is just the single IP half of the pair with
# _load_cidr_bans, kept as its own named sub so new reads as three plain
# calls rather than a loop over families it would otherwise have to know
# about.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return. What was restored is visible in
# $self->{bans} and the log.
#
# Does not die, _load_state surviving an unreadable tablet, a malformed row,
# and a backend that refuses a re-ban.
#
#     $self->_load_bans;
sub _load_bans {
	my ($self) = @_;

	$self->_load_state( $self->state_path, $family_spec{ip} );

	return;
}

# Restores the range ban book from its tablet at startup, mirroring
# _load_bans for the other family, with one deliberate difference... it is
# skipped entirely when ranges are not available to this instance.
#
# That skip matters because of what not skipping would do. Loading is not
# passive: every restored row is re-banned through the backend. Handing a
# tablet full of ranges to a backend that cannot carry them, or to a kur
# whose operator has since turned enable_cidr off, would be a burst of
# failures at every startup. Skipping leaves the file untouched instead, so a
# later run that turns ranges back on finds its state exactly as it was.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return, including the skipped case,
# which is not reported... _cidr_available already logged the mismatch at
# init if there was one.
#
# Does not die.
#
#     $self->_load_cidr_bans;
sub _load_cidr_bans {
	my ($self) = @_;

	if ( !$self->_cidr_available ) {
		return;
	}

	$self->_load_state( $self->cidr_state_path, $family_spec{cidr} );

	return;
} ## end sub _load_cidr_bans

# Restores both retry books from their tablets at startup. An unban that was
# still owed when the kur went down is owed just as much now, the rule having
# outlived the process, so the entries come back with their counts and their
# backoff intact rather than starting over at one attempt and a one second
# delay.
#
# Both families are loaded unconditionally, which is the one place the range
# side is not gated on _cidr_available. The reason is that a debt is to the
# firewall rather than to the feature... a rule this kur failed to remove is
# sitting there regardless of whether the operator has since turned ranges
# off, and unlike _load_cidr_bans this restores no bans and asks the backend
# for nothing, so there is no failure burst to avoid.
#
# Takes no arguments beyond the invocant.
#
# Returns nothing meaningful, an empty return.
#
# Does not die, _load_retry_state surviving an unreadable tablet and skipping
# rows it cannot parse.
#
#     $self->_load_retries;
sub _load_retries {
	my ($self) = @_;

	foreach my $family ( 'ip', 'cidr' ) {
		$self->_load_retry_state( $family_spec{$family} );
	}

	return;
}

# The shared per family retry tablet loader, reading back what
# _write_retry_state put down. Unlike the ban loader it asks the backend for
# nothing... a debt is book keeping about a rule that is already there, so
# restoring one means only putting the entry back in the retry book for the
# sweeper to pick up.
#
# Each row is parsed and checked twice. The shape check wants exactly six
# fields with a non-empty entry and five integers, and the normalize check
# wants the entry itself to validate, which keeps the retry books canonical
# only in the same way the ban books are... a raw spelling booked here would
# be a debt the clear_retries command could never name, as that normalizes
# what it is asked to forget. A row failing either is logged and skipped
# rather than taking the file down with it.
#
# A restored delay is brought inside the same bounds the backoff keeps
# itself in, since only its own doubling is clamped and a tablet can carry
# anything. A 0, which only a hand edited one would, is floored back to 2...
# left alone it would peg the backoff at zero forever and have the sweeper
# retrying that entry every single tick. Anything past the 60 second cap is
# brought back to it, a delay of say 999999 having otherwise put the next
# attempt a week and a half out.
#
# The tablet is rewritten at the end so what is on disk matches what was
# actually restored, which is how skipped rows get dropped rather than
# lingering to be skipped again at every future startup.
#
# Args, one required...
#
#     $spec :: One of the %family_spec entries described above. Uses
#              retry_path, retry_hash, label, normalizer, noun, infix, and
#              retry_checkpoint.
#
# Returns nothing meaningful, an empty return, including when the tablet does
# not exist, which is the ordinary case of nothing being owed.
#
# Does not die. A tablet that cannot be opened or read is logged and the load
# abandoned, leaving the book empty rather than the kur refusing to start over
# a file it only needed for housekeeping.
#
#     $self->_load_retry_state( $family_spec{ip} );
#     # a row of 1.2.3.4,1785918152,1785919052,9,1785919112,60 comes back as
#     # $self->{unban_retries}{'1.2.3.4'} with those counts and that backoff
sub _load_retry_state {
	my ( $self, $spec ) = @_;

	my $path_method = $spec->{retry_path};
	my $state_file  = $self->$path_method;

	if ( !-f $state_file ) {
		return;
	}

	my $ident = 'kur-' . $self->{name};

	my @lines;
	eval {
		open( my $fh, '<', $state_file ) || die( 'open failed... ' . $! );
		@lines = <$fh>;
		close($fh);
	};
	if ($@) {
		log_drek( 'err', 'loading ' . $spec->{infix} . 'unban retry state from "' . $state_file . '" failed... ' . $@,
			undef, $ident );
		return;
	}

	my $line_number = 0;
	foreach my $line (@lines) {
		$line_number++;
		chomp($line);
		if ( $line eq '' ) {
			next;
		}
		if ( $line_number == 1 && $line =~ /^$spec->{label},/ ) {
			# the header
			next;
		}

		my @row = split( /,/, $line );
		if ( @row != 6 || $row[0] eq '' || grep { $row[$_] !~ /^[0-9]+$/ } ( 1 .. 5 ) ) {
			log_drek( 'err', 'skipping malformed line ' . $line_number . ' in "' . $state_file . '"... "' . $line . '"',
				undef, $ident );
			next;
		}
		my ( $entry, $first_tried, $last_tried, $times_tried, $next_try, $delay ) = @row;

		my $normalized = $spec->{normalizer}->($entry);
		if ( !defined($normalized) ) {
			log_drek(
				'err',
				'skipping line '
					. $line_number . ' in "'
					. $state_file
					. '"... "'
					. $entry
					. '" is not a valid '
					. $spec->{noun},
				undef,
				$ident
			);
			next;
		} ## end if ( !defined($normalized) )

		$self->{ $spec->{retry_hash} }{$normalized} = {
			'first_tried' => $first_tried,
			'last_tried'  => $last_tried,
			'times_tried' => $times_tried,
			'next_try'    => $next_try,
			# a tablet written by hand could carry anything, and the backoff
			# only clamps what its own doubling produces, so a restored
			# value is brought inside the same bounds here... a 0 would peg
			# the backoff at 0 forever and is floored to where a first
			# failure would have left it, while anything past the cap would
			# put next_try days out and is brought back to the cap
			'delay' => $delay ? ( $delay > 60 ? 60 : $delay ) : 2,
		};
		log_drek(
			'info',
			'unban of '
				. $spec->{infix}
				. $normalized
				. ' still owed from a previous run, tried '
				. $times_tried
				. ' times',
			undef,
			$ident
		);
	} ## end foreach my $line (@lines)

	# rewrite so the tablet reflects what actually got restored
	my $checkpoint_method = $spec->{retry_checkpoint};
	$self->$checkpoint_method;

	return;
} ## end sub _load_retry_state

# The shared per family ban tablet loader behind _load_bans and
# _load_cidr_bans, and the one loader that actually touches the firewall...
# restoring a ban means re-banning it, the backend having just been inited
# empty.
#
# Each row's remaining sentence is reconstructed as written + left, which is
# what makes a ban serve out the time it had rather than restarting its
# sentence, and that expiry decides which of two things happens. A row that
# ran out while the kur was down is unbanned rather than restored, in case
# the firewall still carries the rule from before, and counted as expired. A
# row still serving is re-banned and booked.
#
# A re-ban the backend refuses is deliberately not booked, matching how a
# live ban behaves... a book claiming a ban the firewall does not carry would
# only feed the sweeper a doomed unban later.
#
# Rows are checked the same two ways the retry loader checks its own, for
# shape and then for an entry that will normalize, and a failure of either is
# logged and skipped. Everything is normalized before being booked, so a
# tablet carrying a non-canonical spelling has that row dropped rather than
# booked raw, which would leave a ban the unban path could never name.
#
# The tablet is rewritten at the end so it reflects what actually got
# restored, dropping the expired and the skipped.
#
# Args, both required and positional...
#
#     $state_file :: Full path of the tablet to read. A missing file is the
#                    ordinary first run case and returns quietly.
#     $spec       :: One of the %family_spec entries described above. Uses
#                    label, normalizer, noun, infix, log_label, ban_method,
#                    unban_method, hash, expired_stat, and checkpoint.
#
# Returns nothing meaningful, an empty return. What was restored is visible in
# that family's ban book, the expired stat, and the log.
#
# Does not die. An unreadable tablet is logged and the load abandoned, and
# every backend call is wrapped, so neither a bad file nor a firewall in a bad
# mood can stop the kur starting.
#
#     $self->_load_state( $self->state_path, $family_spec{ip} );
#
#     $self->_load_state( $self->cidr_state_path, $family_spec{cidr} );
sub _load_state {
	my ( $self, $state_file, $spec ) = @_;

	if ( !-f $state_file ) {
		return;
	}

	my $ident = 'kur-' . $self->{name};

	my @lines;
	eval {
		open( my $fh, '<', $state_file ) || die( 'open failed... ' . $! );
		@lines = <$fh>;
		close($fh);
	};
	if ($@) {
		log_drek( 'err', 'loading ' . $spec->{infix} . 'ban state from "' . $state_file . '" failed... ' . $@,
			undef, $ident );
		return;
	}

	my $now         = time;
	my $line_number = 0;
	foreach my $line (@lines) {
		$line_number++;
		chomp($line);
		if ( $line eq '' ) {
			next;
		}
		if ( $line_number == 1 && $line =~ /^$spec->{label},/ ) {
			# the header
			next;
		}

		my @row = split( /,/, $line );
		if ( @row != 3 || $row[0] eq '' || $row[1] !~ /^[0-9]+$/ || $row[2] !~ /^[0-9]+$/ ) {
			log_drek( 'err', 'skipping malformed line ' . $line_number . ' in "' . $state_file . '"... "' . $line . '"',
				undef, $ident );
			next;
		}
		my ( $banned_entry, $written, $left ) = @row;
		# everything is normalized before being booked, so a row that will
		# not normalize is a hand edit or a corrupt tablet... it is skipped
		# rather than booked raw, which would leave an entry the unban path
		# can never name, as it normalizes what it is asked to remove
		my $normalized = $spec->{normalizer}->($banned_entry);
		if ( !defined($normalized) ) {
			log_drek(
				'err',
				'skipping line '
					. $line_number . ' in "'
					. $state_file
					. '"... "'
					. $banned_entry
					. '" is not a valid '
					. $spec->{noun},
				undef,
				$ident
			);
			next;
		} ## end if ( !defined($normalized) )
		$banned_entry = $normalized;

		my $expires = $left ? $written + $left : 0;

		if ( $expires && $expires <= $now ) {
			# expired while not running... the backend may still carry the rule
			eval { $self->_backend_do( $spec->{unban_method}, ban => $banned_entry ); };
			if ($@) {
				log_drek( 'err',
					'unbanning expired ' . $spec->{log_label} . ' of "' . $banned_entry . '" failed... ' . $@,
					undef, $ident );
			}
			$self->{stats}{ $spec->{expired_stat} }++;
			log_drek( 'info', $spec->{log_label} . ' of ' . $banned_entry . ' expired while not running',
				undef, $ident );
			next;
		} ## end if ( $expires && $expires <= $now )

		eval { $self->_backend_do( $spec->{ban_method}, ban => $banned_entry ); };
		if ($@) {
			# not recorded in the book on failure, matching how a live ban
			# behaves... a book claiming a ban the firewall does not carry
			# would just feed the sweeper a doomed unban later
			log_drek( 'err',
				're-banning ' . $spec->{infix} . '"' . $banned_entry . '" from saved state failed... ' . $@,
				undef, $ident );
			next;
		}
		# banned_at is not persisted, so the row's time stands in for it
		$self->{ $spec->{hash} }{$banned_entry} = { 'banned_at' => $written, 'expires' => $expires };
	} ## end foreach my $line (@lines)

	# write an updated one back out so the file reflects what got restored
	my $checkpoint_method = $spec->{checkpoint};
	$self->$checkpoint_method;

	return;
} ## end sub _load_state

=head1 ERROR CODES / ERROR FLAGS

Error handling is provided by L<Error::Helper>. All errors
are considered fatal.

=head2 1, NErunBaseDir

The run base dir or the kur dir under it does not exist or is not a directory.

=head2 2, invalidName

Name not defined or does not match /^[a-zA-Z0-9\-]+$/.

=head2 3, backendInitFailed

Failed to initialize the backend.

=head2 4, nonRWrunBaseDir

The run base dir or the kur dir under it is not readable or writable by the
current user.

=head2 5, NEcacheBaseDir

The cache base dir does not exist or is not a directory.

=head2 6, nonRWcacheBaseDir

The cache base dir is not readable or writable by the current user.

=head2 7, invalidBanTime

ban_time is not a non-negative int of seconds.

=head2 8, invalidCheckpoint

checkpoint is not a non-negative int of seconds.

=cut

1;    # End of Ereshkigal::Kur
