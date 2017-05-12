# $Id: MP3Play.pm,v 1.49 2008/03/30 10:26:13 joern Exp $

package MPEG::MP3Play;

use strict;
use Carp;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS @ISA $AUTOLOAD);

require Exporter;
require DynaLoader;

$VERSION = '0.16';

@ISA = qw(Exporter DynaLoader);

@EXPORT_OK = qw(
	XA_MSG_UNKNOWN
	XA_MSG_COMMAND_EXIT
	XA_MSG_COMMAND_PING
	XA_MSG_COMMAND_PLAY
	XA_MSG_COMMAND_PAUSE
	XA_MSG_COMMAND_STOP
	XA_MSG_COMMAND_SEEK
	XA_MSG_COMMAND_INPUT_OPEN
	XA_MSG_COMMAND_INPUT_CLOSE
	XA_MSG_COMMAND_INPUT_SEND_MESSAGE
	XA_MSG_COMMAND_INPUT_ADD_FILTER
	XA_MSG_COMMAND_INPUT_REMOVE_FILTER
	XA_MSG_COMMAND_INPUT_FILTERS_LIST
	XA_MSG_COMMAND_INPUT_MODULE_REGISTER
	XA_MSG_COMMAND_INPUT_MODULE_QUERY
	XA_MSG_COMMAND_INPUT_MODULES_LIST
	XA_MSG_COMMAND_OUTPUT_OPEN
	XA_MSG_COMMAND_OUTPUT_CLOSE
	XA_MSG_COMMAND_OUTPUT_SEND_MESSAGE
	XA_MSG_COMMAND_OUTPUT_MUTE
	XA_MSG_COMMAND_OUTPUT_UNMUTE
	XA_MSG_COMMAND_OUTPUT_RESET
	XA_MSG_COMMAND_OUTPUT_DRAIN
	XA_MSG_COMMAND_OUTPUT_ADD_FILTER
	XA_MSG_COMMAND_OUTPUT_REMOVE_FILTER
	XA_MSG_COMMAND_OUTPUT_FILTERS_LIST
	XA_MSG_COMMAND_OUTPUT_MODULE_REGISTER
	XA_MSG_COMMAND_OUTPUT_MODULE_QUERY
	XA_MSG_COMMAND_OUTPUT_MODULES_LIST
	XA_MSG_SET_PLAYER_MODE
	XA_MSG_GET_PLAYER_MODE
	XA_MSG_SET_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_GET_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_SET_PLAYER_ENVIRONMENT_STRING
	XA_MSG_GET_PLAYER_ENVIRONMENT_STRING
	XA_MSG_UNSET_PLAYER_ENVIRONMENT
	XA_MSG_SET_INPUT_NAME
	XA_MSG_GET_INPUT_NAME
	XA_MSG_SET_INPUT_MODULE
	XA_MSG_GET_INPUT_MODULE
	XA_MSG_SET_INPUT_POSITION_RANGE
	XA_MSG_GET_INPUT_POSITION_RANGE
	XA_MSG_SET_INPUT_TIMECODE_GRANULARITY
	XA_MSG_GET_INPUT_TIMECODE_GRANULARITY
	XA_MSG_SET_OUTPUT_NAME
	XA_MSG_GET_OUTPUT_NAME
	XA_MSG_SET_OUTPUT_MODULE
	XA_MSG_GET_OUTPUT_MODULE
	XA_MSG_SET_OUTPUT_VOLUME
	XA_MSG_GET_OUTPUT_VOLUME
	XA_MSG_SET_OUTPUT_CHANNELS
	XA_MSG_GET_OUTPUT_CHANNELS
	XA_MSG_SET_OUTPUT_PORTS
	XA_MSG_GET_OUTPUT_PORTS
	XA_MSG_SET_CODEC_EQUALIZER
	XA_MSG_GET_CODEC_EQUALIZER
	XA_MSG_SET_NOTIFICATION_MASK
	XA_MSG_GET_NOTIFICATION_MASK
	XA_MSG_SET_DEBUG_LEVEL
	XA_MSG_GET_DEBUG_LEVEL
	XA_MSG_NOTIFY_READY
	XA_MSG_NOTIFY_ACK
	XA_MSG_NOTIFY_NACK
	XA_MSG_NOTIFY_PONG
	XA_MSG_NOTIFY_EXITED
	XA_MSG_NOTIFY_PLAYER_STATE
	XA_MSG_NOTIFY_PLAYER_MODE
	XA_MSG_NOTIFY_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_NOTIFY_PLAYER_ENVIRONMENT_STRING
	XA_MSG_NOTIFY_INPUT_STATE
	XA_MSG_NOTIFY_INPUT_NAME
	XA_MSG_NOTIFY_INPUT_CAPS
	XA_MSG_NOTIFY_INPUT_POSITION
	XA_MSG_NOTIFY_INPUT_POSITION_RANGE
	XA_MSG_NOTIFY_INPUT_TIMECODE
	XA_MSG_NOTIFY_INPUT_TIMECODE_GRANULARITY
	XA_MSG_NOTIFY_INPUT_MODULE
	XA_MSG_NOTIFY_INPUT_MODULE_INFO
	XA_MSG_NOTIFY_INPUT_DEVICE_INFO
	XA_MSG_NOTIFY_INPUT_FILTER_INFO
	XA_MSG_NOTIFY_OUTPUT_STATE
	XA_MSG_NOTIFY_OUTPUT_NAME
	XA_MSG_NOTIFY_OUTPUT_CAPS
	XA_MSG_NOTIFY_OUTPUT_VOLUME
	XA_MSG_NOTIFY_OUTPUT_BALANCE
	XA_MSG_NOTIFY_OUTPUT_PCM_LEVEL
	XA_MSG_NOTIFY_OUTPUT_MASTER_LEVEL
	XA_MSG_NOTIFY_OUTPUT_CHANNELS
	XA_MSG_NOTIFY_OUTPUT_PORTS
	XA_MSG_NOTIFY_OUTPUT_MODULE
	XA_MSG_NOTIFY_OUTPUT_MODULE_INFO
	XA_MSG_NOTIFY_OUTPUT_DEVICE_INFO
	XA_MSG_NOTIFY_OUTPUT_FILTER_INFO
	XA_MSG_NOTIFY_CODEC_EQUALIZER
	XA_MSG_NOTIFY_NOTIFICATION_MASK
	XA_MSG_NOTIFY_DEBUG_LEVEL
	XA_MSG_NOTIFY_PROGRESS
	XA_MSG_NOTIFY_DEBUG
	XA_MSG_NOTIFY_ERROR
	XA_MSG_LAST
	XA_PLAYER_STATE_STOPPED
	XA_PLAYER_STATE_PLAYING
	XA_PLAYER_STATE_PAUSED
	XA_PLAYER_STATE_EOF
	XA_INPUT_STATE_OPEN
	XA_INPUT_STATE_CLOSED
	XA_OUTPUT_STATE_OPEN
	XA_OUTPUT_STATE_CLOSED
	XA_OUTPUT_CHANNELS_STEREO
	XA_OUTPUT_CHANNELS_MONO_LEFT
	XA_OUTPUT_CHANNELS_MONO_RIGHT
	XA_OUTPUT_CHANNELS_MONO_MIX
	XA_TIMEOUT_INFINITE
	XA_NOTIFY_MASK_ERROR
	XA_NOTIFY_MASK_DEBUG
	XA_NOTIFY_MASK_PROGRESS
	XA_NOTIFY_MASK_ACK
	XA_NOTIFY_MASK_NACK
	XA_NOTIFY_MASK_PLAYER_STATE
	XA_NOTIFY_MASK_INPUT_STATE
	XA_NOTIFY_MASK_INPUT_NAME
	XA_NOTIFY_MASK_INPUT_CAPS
	XA_NOTIFY_MASK_INPUT_DURATION
	XA_NOTIFY_MASK_INPUT_POSITION
	XA_NOTIFY_MASK_INPUT_POSITION_RANGE
	XA_NOTIFY_MASK_INPUT_TIMECODE
	XA_NOTIFY_MASK_INPUT_TIMECODE_GRANULARITY
	XA_NOTIFY_MASK_INPUT_STREAM_INFO
	XA_NOTIFY_MASK_OUTPUT_STATE
	XA_NOTIFY_MASK_OUTPUT_NAME
	XA_NOTIFY_MASK_OUTPUT_CAPS
	XA_NOTIFY_MASK_OUTPUT_VOLUME
	XA_NOTIFY_MASK_OUTPUT_BALANCE
	XA_NOTIFY_MASK_OUTPUT_PCM_LEVEL
	XA_NOTIFY_MASK_OUTPUT_MASTER_LEVEL
	XA_NOTIFY_MASK_OUTPUT_PORTS
	XA_NOTIFY_MASK_CODEC_EQUALIZER
	XA_NOTIFY_MASK_FEEDBACK_EVENT
	XA_OUTPUT_VOLUME_IGNORE_FIELD
	XA_CMSEND
	XA_NOTIFY_PROGRESS
	XA_NOTIFY_DEBUG
	XA_NOTIFY_ERROR
	XA_EXPORT
	XA_IMPORT
	XA_API_ID_SYNC
	XA_API_ID_ASYNC
	XA_SUCCESS
	XA_FAILURE
	XA_ERROR_BASE_GENERAL
	XA_ERROR_OUT_OF_MEMORY
	XA_ERROR_INVALID_PARAMETERS
	XA_ERROR_INTERNAL
	XA_ERROR_TIMEOUT
	XA_ERROR_VERSION_EXPIRED
	XA_ERROR_BASE_NETWORK
	XA_ERROR_CONNECT_TIMEOUT
	XA_ERROR_CONNECT_FAILED
	XA_ERROR_CONNECTION_REFUSED
	XA_ERROR_ACCEPT_FAILED
	XA_ERROR_LISTEN_FAILED
	XA_ERROR_SOCKET_FAILED
	XA_ERROR_SOCKET_CLOSED
	XA_ERROR_BIND_FAILED
	XA_ERROR_HOST_UNKNOWN
	XA_ERROR_HTTP_INVALID_REPLY
	XA_ERROR_HTTP_ERROR_REPLY
	XA_ERROR_HTTP_FAILURE
	XA_ERROR_FTP_INVALID_REPLY
	XA_ERROR_FTP_ERROR_REPLY
	XA_ERROR_FTP_FAILURE
	XA_ERROR_BASE_CONTROL
	XA_ERROR_PIPE_FAILED
	XA_ERROR_FORK_FAILED
	XA_ERROR_SELECT_FAILED
	XA_ERROR_PIPE_CLOSED
	XA_ERROR_PIPE_READ_FAILED
	XA_ERROR_PIPE_WRITE_FAILED
	XA_ERROR_INVALID_MESSAGE
	XA_ERROR_CIRQ_FULL
	XA_ERROR_POST_FAILED
	XA_ERROR_BASE_URL
	XA_ERROR_URL_UNSUPPORTED_SCHEME
	XA_ERROR_URL_INVALID_SYNTAX
	XA_ERROR_BASE_IO
	XA_ERROR_OPEN_FAILED
	XA_ERROR_CLOSE_FAILED
	XA_ERROR_READ_FAILED
	XA_ERROR_WRITE_FAILED
	XA_ERROR_PERMISSION_DENIED
	XA_ERROR_NO_DEVICE
	XA_ERROR_IOCTL_FAILED
	XA_ERROR_MODULE_NOT_FOUND
	XA_ERROR_UNSUPPORTED_INPUT
	XA_ERROR_UNSUPPORTED_OUTPUT
	XA_ERROR_DEVICE_BUSY
	XA_ERROR_NO_SUCH_DEVICE
	XA_ERROR_NO_SUCH_FILE
	XA_ERROR_INPUT_EOF
	XA_ERROR_BASE_BITSTREAM
	XA_ERROR_INVALID_FRAME
	XA_ERROR_BASE_DYNLINK
	XA_ERROR_DLL_NOT_FOUND
	XA_ERROR_SYMBOL_NOT_FOUND
	XA_ERROR_BASE_ENVIRONMENT
	XA_ERROR_NO_SUCH_ENVIRONMENT
	XA_ERROR_ENVIRONMENT_TYPE_MISMATCH
	XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_STOP
	XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_PAUSE
);

%EXPORT_TAGS = (
msg => [qw (
	XA_MSG_UNKNOWN
	XA_MSG_COMMAND_EXIT
	XA_MSG_COMMAND_PING
	XA_MSG_COMMAND_PLAY
	XA_MSG_COMMAND_PAUSE
	XA_MSG_COMMAND_STOP
	XA_MSG_COMMAND_SEEK
	XA_MSG_COMMAND_INPUT_OPEN
	XA_MSG_COMMAND_INPUT_CLOSE
	XA_MSG_COMMAND_INPUT_SEND_MESSAGE
	XA_MSG_COMMAND_INPUT_ADD_FILTER
	XA_MSG_COMMAND_INPUT_REMOVE_FILTER
	XA_MSG_COMMAND_INPUT_FILTERS_LIST
	XA_MSG_COMMAND_INPUT_MODULE_REGISTER
	XA_MSG_COMMAND_INPUT_MODULE_QUERY
	XA_MSG_COMMAND_INPUT_MODULES_LIST
	XA_MSG_COMMAND_OUTPUT_OPEN
	XA_MSG_COMMAND_OUTPUT_CLOSE
	XA_MSG_COMMAND_OUTPUT_SEND_MESSAGE
	XA_MSG_COMMAND_OUTPUT_MUTE
	XA_MSG_COMMAND_OUTPUT_UNMUTE
	XA_MSG_COMMAND_OUTPUT_RESET
	XA_MSG_COMMAND_OUTPUT_DRAIN
	XA_MSG_COMMAND_OUTPUT_ADD_FILTER
	XA_MSG_COMMAND_OUTPUT_REMOVE_FILTER
	XA_MSG_COMMAND_OUTPUT_FILTERS_LIST
	XA_MSG_COMMAND_OUTPUT_MODULE_REGISTER
	XA_MSG_COMMAND_OUTPUT_MODULE_QUERY
	XA_MSG_COMMAND_OUTPUT_MODULES_LIST
	XA_MSG_NOTIFY_READY
	XA_MSG_NOTIFY_ACK
	XA_MSG_NOTIFY_NACK
	XA_MSG_NOTIFY_PONG
	XA_MSG_NOTIFY_EXITED
	XA_MSG_NOTIFY_PLAYER_STATE
	XA_MSG_NOTIFY_PLAYER_MODE
	XA_MSG_NOTIFY_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_NOTIFY_PLAYER_ENVIRONMENT_STRING
	XA_MSG_NOTIFY_INPUT_STATE
	XA_MSG_NOTIFY_INPUT_NAME
	XA_MSG_NOTIFY_INPUT_CAPS
	XA_MSG_NOTIFY_INPUT_POSITION
	XA_MSG_NOTIFY_INPUT_POSITION_RANGE
	XA_MSG_NOTIFY_INPUT_TIMECODE
	XA_MSG_NOTIFY_INPUT_TIMECODE_GRANULARITY
	XA_MSG_NOTIFY_INPUT_MODULE
	XA_MSG_NOTIFY_INPUT_MODULE_INFO
	XA_MSG_NOTIFY_INPUT_DEVICE_INFO
	XA_MSG_NOTIFY_INPUT_FILTER_INFO
	XA_MSG_NOTIFY_OUTPUT_STATE
	XA_MSG_NOTIFY_OUTPUT_NAME
	XA_MSG_NOTIFY_OUTPUT_CAPS
	XA_MSG_NOTIFY_OUTPUT_VOLUME
	XA_MSG_NOTIFY_OUTPUT_BALANCE
	XA_MSG_NOTIFY_OUTPUT_PCM_LEVEL
	XA_MSG_NOTIFY_OUTPUT_MASTER_LEVEL
	XA_MSG_NOTIFY_OUTPUT_CHANNELS
	XA_MSG_NOTIFY_OUTPUT_PORTS
	XA_MSG_NOTIFY_OUTPUT_MODULE
	XA_MSG_NOTIFY_OUTPUT_MODULE_INFO
	XA_MSG_NOTIFY_OUTPUT_DEVICE_INFO
	XA_MSG_NOTIFY_OUTPUT_FILTER_INFO
	XA_MSG_NOTIFY_CODEC_EQUALIZER
	XA_MSG_NOTIFY_NOTIFICATION_MASK
	XA_MSG_NOTIFY_DEBUG_LEVEL
	XA_MSG_NOTIFY_PROGRESS
	XA_MSG_NOTIFY_DEBUG
	XA_MSG_NOTIFY_ERROR
	XA_MSG_SET_PLAYER_MODE
	XA_MSG_GET_PLAYER_MODE
	XA_MSG_SET_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_GET_PLAYER_ENVIRONMENT_INTEGER
	XA_MSG_SET_PLAYER_ENVIRONMENT_STRING
	XA_MSG_GET_PLAYER_ENVIRONMENT_STRING
	XA_MSG_UNSET_PLAYER_ENVIRONMENT
	XA_MSG_SET_INPUT_NAME
	XA_MSG_GET_INPUT_NAME
	XA_MSG_SET_INPUT_MODULE
	XA_MSG_GET_INPUT_MODULE
	XA_MSG_SET_INPUT_POSITION_RANGE
	XA_MSG_GET_INPUT_POSITION_RANGE
	XA_MSG_SET_INPUT_TIMECODE_GRANULARITY
	XA_MSG_GET_INPUT_TIMECODE_GRANULARITY
	XA_MSG_SET_OUTPUT_NAME
	XA_MSG_GET_OUTPUT_NAME
	XA_MSG_SET_OUTPUT_MODULE
	XA_MSG_GET_OUTPUT_MODULE
	XA_MSG_SET_OUTPUT_VOLUME
	XA_MSG_GET_OUTPUT_VOLUME
	XA_MSG_SET_OUTPUT_CHANNELS
	XA_MSG_GET_OUTPUT_CHANNELS
	XA_MSG_SET_OUTPUT_PORTS
	XA_MSG_GET_OUTPUT_PORTS
	XA_MSG_SET_CODEC_EQUALIZER
	XA_MSG_GET_CODEC_EQUALIZER
	XA_MSG_SET_NOTIFICATION_MASK
	XA_MSG_GET_NOTIFICATION_MASK
	XA_MSG_SET_DEBUG_LEVEL
	XA_MSG_GET_DEBUG_LEVEL
	XA_MSG_LAST
	XA_TIMEOUT_INFINITE
	XA_OUTPUT_VOLUME_IGNORE_FIELD
)],
state => [qw (
	XA_PLAYER_STATE_STOPPED
	XA_PLAYER_STATE_PLAYING
	XA_PLAYER_STATE_PAUSED
	XA_PLAYER_STATE_EOF
	XA_INPUT_STATE_OPEN
	XA_INPUT_STATE_CLOSED
	XA_OUTPUT_STATE_OPEN
	XA_OUTPUT_STATE_CLOSED
	XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_STOP
	XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_PAUSE
)],
mask => [qw (
	XA_NOTIFY_MASK_ERROR
	XA_NOTIFY_MASK_DEBUG
	XA_NOTIFY_MASK_PROGRESS
	XA_NOTIFY_MASK_ACK
	XA_NOTIFY_MASK_NACK
	XA_NOTIFY_MASK_PLAYER_STATE
	XA_NOTIFY_MASK_INPUT_STATE
	XA_NOTIFY_MASK_INPUT_NAME
	XA_NOTIFY_MASK_INPUT_CAPS
	XA_NOTIFY_MASK_INPUT_DURATION
	XA_NOTIFY_MASK_INPUT_POSITION
	XA_NOTIFY_MASK_INPUT_POSITION_RANGE
	XA_NOTIFY_MASK_INPUT_TIMECODE
	XA_NOTIFY_MASK_INPUT_TIMECODE_GRANULARITY
	XA_NOTIFY_MASK_INPUT_STREAM_INFO
	XA_NOTIFY_MASK_OUTPUT_STATE
	XA_NOTIFY_MASK_OUTPUT_NAME
	XA_NOTIFY_MASK_OUTPUT_CAPS
	XA_NOTIFY_MASK_OUTPUT_VOLUME
	XA_NOTIFY_MASK_OUTPUT_BALANCE
	XA_NOTIFY_MASK_OUTPUT_PCM_LEVEL
	XA_NOTIFY_MASK_OUTPUT_MASTER_LEVEL
	XA_NOTIFY_MASK_OUTPUT_PORTS
	XA_NOTIFY_MASK_CODEC_EQUALIZER
	XA_NOTIFY_MASK_FEEDBACK_EVENT
)],
misc => [qw(
	XA_OUTPUT_CHANNELS_STEREO
	XA_OUTPUT_CHANNELS_MONO_LEFT
	XA_OUTPUT_CHANNELS_MONO_RIGHT
	XA_OUTPUT_CHANNELS_MONO_MIX
	XA_CMSEND
	XA_NOTIFY_PROGRESS
	XA_NOTIFY_DEBUG
	XA_NOTIFY_ERROR
	XA_EXPORT
	XA_IMPORT
	XA_API_ID_SYNC
	XA_API_ID_ASYNC
)],
error=> [qw (
	XA_SUCCESS
	XA_FAILURE
	XA_ERROR_BASE_GENERAL
	XA_ERROR_OUT_OF_MEMORY
	XA_ERROR_INVALID_PARAMETERS
	XA_ERROR_INTERNAL
	XA_ERROR_TIMEOUT
	XA_ERROR_VERSION_EXPIRED
	XA_ERROR_BASE_NETWORK
	XA_ERROR_CONNECT_TIMEOUT
	XA_ERROR_CONNECT_FAILED
	XA_ERROR_CONNECTION_REFUSED
	XA_ERROR_ACCEPT_FAILED
	XA_ERROR_LISTEN_FAILED
	XA_ERROR_SOCKET_FAILED
	XA_ERROR_SOCKET_CLOSED
	XA_ERROR_BIND_FAILED
	XA_ERROR_HOST_UNKNOWN
	XA_ERROR_HTTP_INVALID_REPLY
	XA_ERROR_HTTP_ERROR_REPLY
	XA_ERROR_HTTP_FAILURE
	XA_ERROR_FTP_INVALID_REPLY
	XA_ERROR_FTP_ERROR_REPLY
	XA_ERROR_FTP_FAILURE
	XA_ERROR_BASE_CONTROL
	XA_ERROR_PIPE_FAILED
	XA_ERROR_FORK_FAILED
	XA_ERROR_SELECT_FAILED
	XA_ERROR_PIPE_CLOSED
	XA_ERROR_PIPE_READ_FAILED
	XA_ERROR_PIPE_WRITE_FAILED
	XA_ERROR_INVALID_MESSAGE
	XA_ERROR_CIRQ_FULL
	XA_ERROR_POST_FAILED
	XA_ERROR_BASE_URL
	XA_ERROR_URL_UNSUPPORTED_SCHEME
	XA_ERROR_URL_INVALID_SYNTAX
	XA_ERROR_BASE_IO
	XA_ERROR_OPEN_FAILED
	XA_ERROR_CLOSE_FAILED
	XA_ERROR_READ_FAILED
	XA_ERROR_WRITE_FAILED
	XA_ERROR_PERMISSION_DENIED
	XA_ERROR_NO_DEVICE
	XA_ERROR_IOCTL_FAILED
	XA_ERROR_MODULE_NOT_FOUND
	XA_ERROR_UNSUPPORTED_INPUT
	XA_ERROR_UNSUPPORTED_OUTPUT
	XA_ERROR_DEVICE_BUSY
	XA_ERROR_NO_SUCH_DEVICE
	XA_ERROR_NO_SUCH_FILE
	XA_ERROR_INPUT_EOF
	XA_ERROR_BASE_BITSTREAM
	XA_ERROR_INVALID_FRAME
	XA_ERROR_BASE_DYNLINK
	XA_ERROR_DLL_NOT_FOUND
	XA_ERROR_SYMBOL_NOT_FOUND
	XA_ERROR_BASE_ENVIRONMENT
	XA_ERROR_NO_SUCH_ENVIRONMENT
	XA_ERROR_ENVIRONMENT_TYPE_MISMATCH
)]);

sub AUTOLOAD {
	my $constname;
	($constname = $AUTOLOAD) =~ s/.*:://;
 	croak "& not defined" if $constname eq 'constant';

	my $val = constant($constname, 0);

	if ($! != 0) {
		if ($! =~ /Invalid/) {
			croak "MP3Play autoload error: '$constname' unknown";
	        } else {
			croak "Your vendor has not defined test macro $constname";
		}
	}
	no strict 'refs';
	*$AUTOLOAD = sub { $val };

	goto &$AUTOLOAD;
}

bootstrap MPEG::MP3Play $VERSION;

sub new {
	my $type = shift;
	my %par = @_;
	
	croak "debug => { 'err' | 'all' }"
		if $par{'debug'} and $par{'debug'} ne 'err'
			       and $par{'debug'} ne 'all';
	
	my $self = {
		player => new_player(),
		debug => $par{'debug'} || ''
	};
	
	bless $self, $type;
	
	$self->equalizer();
	
	return $self;
}

sub DESTROY {
	my $self = shift;
	
	destroy_player ($self->{player});
}

sub debug {
	my $self = shift;
	
	my ($debug) = @_;
	
	croak "debug => { 'err' | 'all' | 'none' | '' }"
		if $debug ne '' and $debug ne 'err' and
		   $debug ne 'all' and $debug ne 'none';
	$debug = '' if $debug eq 'none';

	$self->{'debug'} = $debug;

	1;
}

sub get_xaudio_implementation {
	my $self = shift;
	
	require MPEG::MP3Play::XA_Version;
	
	return @MPEG::MP3Play::XA_Version::VERSION if wantarray;
	return $MPEG::MP3Play::XA_Version::VERSION;
}

sub print_xaudio_implementation {
	my $self = shift;
	
	my $version = $self->get_xaudio_implementation;
	print "Xaudio Implementation: $version\n";
	
	1;
}

sub open {
	my $self = shift;

	my ($filename) = @_;

	control_message_send_S (
		$self->{player},
		&XA_MSG_COMMAND_INPUT_OPEN,
		$filename
	) == &XA_SUCCESS;
}

sub close {
	my $self = shift;

	my ($filename) = @_;
	
	control_message_send_N (
		$self->{player},
		&XA_MSG_COMMAND_INPUT_CLOSE
	) == &XA_SUCCESS;;
}

sub exit {
	my $self = shift;

	my ($filename) = @_;
	
	control_message_send_N (
		$self->{player},
		&XA_MSG_COMMAND_EXIT
	) == &XA_SUCCESS;
}

sub play {
	my $self = shift;

	control_message_send_N (
		$self->{player},
		&XA_MSG_COMMAND_PLAY
	) == &XA_SUCCESS;
}

sub stop {
	my $self = shift;

	control_message_send_N (
		$self->{player},
		&XA_MSG_COMMAND_STOP
	) == &XA_SUCCESS;
}

sub pause {
	my $self = shift;

	control_message_send_N (
		$self->{player},
		&XA_MSG_COMMAND_PAUSE
	) == &XA_SUCCESS;
}

sub seek {
	my $self = shift;
	
	my ($offset, $range) = @_;
	
	control_message_send_II (
		$self->{player},
		&XA_MSG_COMMAND_SEEK,
		$offset,
		$range
	) == &XA_SUCCESS;
}

sub volume {
	my $self = shift;
	
	my ($pcm_level, $master_level, $balance) = @_;
	
	$pcm_level    = &XA_OUTPUT_VOLUME_IGNORE_FIELD
			unless defined $pcm_level;
	$master_level = &XA_OUTPUT_VOLUME_IGNORE_FIELD
			unless defined $master_level;
	$balance      = &XA_OUTPUT_VOLUME_IGNORE_FIELD
			unless defined $balance;
	
	control_message_send_III (
		$self->{player},
		&XA_MSG_SET_OUTPUT_VOLUME,
		$balance,
		$pcm_level,
		$master_level
	) == &XA_SUCCESS;
}

sub equalizer {
	my $self = shift;
	
	my ($left_lref, $right_lref) = @_;
	
	# disable the equalizer?
	
	if ( not defined $left_lref or
	     not defined $right_lref ) {
		return disable_equalizer_codec (
			$self->{player}
		) == &XA_SUCCESS;
	}
	
	# parameter checking
	
	if ( @{$left_lref} != 32 or @{$right_lref} != 32 ) {
		croak "invalid number of equalizer values passed";
	}
	
	# check value band of -128 .. +127
	my $ok = 1;
	for (my $i=0; $ok and $i < 32; ++$i) {
		$left_lref->[$i] = int($left_lref->[$i]);
		$right_lref->[$i] = int($right_lref->[$i]);
		$ok = 0 if $left_lref->[$i] < -128 or $left_lref->[$i] > 127 or
		           $right_lref->[$i] < -128 or $right_lref->[$i] > 127;
	}
	
	croak "invalid equalizer values passed" unless $ok;

	# ok, all parameters are fine

	my $eq_left  = pack('c32', @{$left_lref});
	my $eq_right = pack('c32', @{$right_lref});

	my $ret = control_message_send_S (
		$self->{player},
		&XA_MSG_SET_CODEC_EQUALIZER,
		$eq_left.$eq_right
	);
        
#	my $ret = set_equalizer_codec (
#		$self->{player},
#		$eq_left,
#		$eq_right
#	);
	
	return $ret == &XA_SUCCESS;
}

sub get_equalizer {
	my $self = shift;
	
	control_message_send_N (
		$self->{player},
		&XA_MSG_GET_CODEC_EQUALIZER
	) == &XA_SUCCESS;
	
}

sub get_message {
	my $self = shift;
	
	return control_message_get (
		$self->{player}
	) || undef;
}

sub get_message_wait {
	my $self = shift;
	my ($timeout) = @_;

	$timeout ||= &XA_TIMEOUT_INFINITE;

	return control_message_wait (
		$self->{player},
		$timeout
	) || undef;
	
}

sub set_notification_mask {
	my $self = shift;
	
	my $mask = 0;
	
	if ( $self->{'debug'} ) {
		$mask  = &XA_NOTIFY_MASK_NACK;
		$mask |= &XA_NOTIFY_MASK_ACK if $self->{'debug'} eq 'all';
	}
	
	for (@_) { $mask |= $_ }
	
	$self->{notification_mask} = $mask;

	control_message_send_I (
		$self->{player},
		&XA_MSG_SET_NOTIFICATION_MASK,
		$mask
	) == &XA_SUCCESS;
}

sub set_player_mode {
	my $self = shift;
	
	my $mask = 0;
	for (@_) { $mask |= $_ }
	
	$self->{player_mode} = $mask;

	control_message_send_I (
		$self->{player},
		&XA_MSG_SET_PLAYER_MODE,
		$mask
	) == &XA_SUCCESS;
}

sub set_input_position_range {
        my $self = shift;
        my($ipr) = @_;

        control_message_send_I (
                $self->{player},
                &XA_MSG_SET_INPUT_POSITION_RANGE,
                $ipr
        ) == &XA_SUCCESS;       
}  

sub get_command_read_pipe {
	my $self = shift;
	
	return command_read_pipe ($self->{player});
}

sub set_user_data {
	my $self = shift;

	my ($data) = @_;

	$self->{user_data} = $data;
	
	1;
}

sub get_user_data {
	my $self = shift;

	return $self->{user_data};
}

sub message_handler {
	my $self = shift;
	
	my ($timeout) = @_;
	
	while ( 1 ) {
		my $msg = $self->get_message_wait ($timeout);
		if ( defined $msg ) {
			$self->_convert_msg ($msg);
			last if not $self->_process_message ($msg);
			last if $msg->{code} == &XA_MSG_NOTIFY_EXITED;
		}
		if ( $timeout ) {
			last if not $self->_process_message ({
				_method_name => "work"
			});
		}
	}
}

sub _convert_msg {
	my $self = shift;
	
	my ($msg) = @_;
	
	# convert equalizer messages to make them more Perl'ish
	if ( $msg->{code} == &XA_MSG_NOTIFY_CODEC_EQUALIZER ) {
		my $eq = $msg->{'equalizer'};
		my $left  = substr($eq,0,32);
		my $right = substr($eq,32,32);
		$msg->{'equalizer'} = {
			left  => [ unpack('c32',$left) ],
			right => [ unpack('c32',$right) ]
		};
	}
}

sub process_messages_nowait {
	my $self = shift;
	
	my $msg = 1;
	while ( $msg ) {
		$msg = $self->get_message;
		if ( defined $msg ) {
			last if not $self->_process_message ($msg);
			last if $msg->{code} == &XA_MSG_NOTIFY_EXITED;
		}
	}
}

sub _process_message {
	my $self = shift;
	
	my ($msg) = @_;
	my $method = $msg->{_method_name};

	print STDERR "unkown message recieved\n"
		if $self->{debug} and not defined $method;
	return 1 if not defined $method;

	my $retval = eval { $self->$method ($msg) };
	croak $@ if $@ and $@ !~ /^MP3Play autoload error/;
	$retval = 1 if $@;

	return $retval;
}

{
	# this is for caching message names
	my %MESSAGE_NAME;
	my $MESSAGE_NAME_BUILT;

	sub _message_name {
		my $self = shift;
	
		my ($code) = @_;
	
		# return message name if available
		return $MESSAGE_NAME{$code} if $MESSAGE_NAME_BUILT;
		
		# ok, first build %MESSAGE_NAME
		my $eval;
		foreach my $msg (@{$EXPORT_TAGS{msg}}) {
			$eval .= qq{\$MESSAGE_NAME{&$msg} = '$msg';};
		}

		eval $eval;
		
		$MESSAGE_NAME_BUILT = 1;
		
		# now return message name
		return $MESSAGE_NAME{$code};
	}
}

{
	# this is for caching error names
	my %ERROR_NAME;
	my $ERROR_NAME_BUILT;

	sub _error_name {
		my $self = shift;
	
		my ($code) = @_;
	
		# return error name if available
		return $ERROR_NAME{$code} if $ERROR_NAME_BUILT;
		
		# ok, first build %ERROR_NAME
		my $eval;
		foreach my $err (@{$EXPORT_TAGS{error}}) {
			$eval .= qq{\$ERROR_NAME{&$err} = '$err';\n};
		}
		eval $eval;
		
		$ERROR_NAME_BUILT = 1;

		# now return error name
		return $ERROR_NAME{$code};
	}
}

# default message handlers

sub msg_notify_player_state {
	my $self = shift;
	my ($msg) = @_;
	
	# return false on EOF, so the message handler will exit
	return if $msg->{state} == &XA_PLAYER_STATE_EOF;

	# always return true in a message handler
	1;
}

sub msg_notify_ack {
	my $self = shift;

	return 1 if not $self->{'debug'} eq 'all';
	
	my ($msg) = @_;
	
	use Data::Dumper;print Dumper($msg);
	
	my $msg_name = $self->_message_name ($msg->{ack});

	carp "message '$msg_name' acknowledged";

	# always return true in a message handler
	1;
}

sub msg_notify_nack {
	my $self = shift;

	return 1 if not $self->{'debug'};
	
	my ($msg) = @_;
	
	my $msg_name = $self->_message_name ($msg->{nack_command});
	my $err_name = $self->_error_name ($msg->{nack_code});

	carp "message '$msg_name' error: $err_name";

	# always return true in a message handler
	1;
}

1;
__END__

=head1 NAME

MPEG::MP3Play - Perl extension for playing back MPEG music

=head1 SYNOPSIS

  use MPEG::MP3Play;
  my $mp3 = new MPEG::MP3Play;
  
  $mp3->open ("test.mp3");
  $mp3->play;
  $mp3->message_handler;

=head1 DESCRIPTION

This Perl module enables you to playback MPEG music.

This README and the documention cover version 0.15 of the
MPEG::MP3Play module.

=head1 PREREQUISITES

B<Xaudio SDK>

MPEG::MP3Play is build against the 3.0.8 and 3.2.1 versions of
the Xaudio SDK and uses the async interface of the Xaudio library.

The SDK is not part of this distribution, so get and install it first
(http://www.xaudio.com/).

B<ATTENTION: Xaudio Version 3.2.x SUPPORT IS ACTUALLY BETA>

Unfortunately Xaudio changed many internals of the API since
version 3.0.0, and many of them are not documented. So I had to
hack around, but everything seem to work now. Even so I think 3.2.x
support is actually beta. If you have problems with this
version, please send me an email (see bug report section below)
and downgrade to 3.0.x if you can't get sleep ;)

For Linux Users:

Xaudio removed the 3.0.8 Linux version from their developer page.
Please read and agree to the license restrictions under
http://www.xaudio.com/developers/license.php and download the
package from here:

  http://www.netcologne.de/~nc-joernre/-/xasdk-3.0.8.x86-unknown-linux-glibc.tar.gz

B<Perl>

I built and tested this module using Perl 5.6.1, Perl 5.005_03, Perl 5.004_04.
It should work also with Perl 5.004_05 and Perl 5.6.0, but I did not test this. If
someone builds MPEG::MP3Play successfully with other versions of Perl,
please drop me a note.

B<Optionally used Perl modules>

  samples/play.pl uses Term::ReadKey if it's installed.
  samples/handler.pl requires Term::ReadKey.
  samples/gtk*.pl require Gtk.

=head1 DOWNLOADING

You can download MPEG::MP3Play from any CPAN mirror. You will
find it in the following directories:

  http://www.perl.com/CPAN/modules/by-module/MPEG/
  http://www.perl.com/CPAN/modules/by-authors/id/J/JR/JRED/

You'll also find recent information and download links on
my homepage:

  http://www.netcologne.de/~nc-joernre/

=head1 INSTALLATION

First, generate the Makefile:

  perl Makefile.PL

You will be prompted for the location of the Xaudio SDK. The directory
must contain the include and lib subdirectories, where the Xaudio header
and library files are installed.

  make
  make test
  cp /a/sample/mp3/file.mp3 test.mp3
  ./runsample play.pl
  ./runsample handler.pl
  ./runsample gtk.pl
  ./runsample gtkhandler.pl
  ./runsample gtkinherit.pl
  ./runsample synopsis.pl
  make install

=head1 SAMPLE SCRIPTS

There are some small test scripts in the samples directory.
You can run these scripts before 'make install' with the
runsample script (or directly with 'perl', after running
'make install'). For runsample usage: see above.

All scripts expect a mp3 file 'test.mp3' in the actual
directory.

=over 8

=item B<play.pl>

Textmodus playback. Displays the timecode. Simple
volume control with '+' and '-' keys.

=item B<handler.pl>

Does nearly the same as play.pl, but uses the builtin
message handler. You'll see, that this solution is much
more elegant. It I<requires> Term::ReadKey.

This script makes use of the debugging facility, the
equalizer features and is best documented so far.

=item B<gtk.pl>

This script demonstrates the usage of MPEG::MP3Play with
the Gtk module. It produces a simple window with a
progress bar while playing back the test.mp3 file.

=item B<gtkhandler.pl>

This script does the same as gtk.pl but uses the builtin
message handler concept instead of implementing message
handling by itself. Advantage of using the builtin message
handler: no global variables are necessary anymore.

Because 'runsample' uses 'C<perl -w>' you'll get a warning
message here complaining about a subroutine redefinition.
See the section USING THE BUILTIN MESSAGE HANDLER for a
discussion about this.

=item B<gtkinherit.pl>

This is 'gtkhandler.pl' but throwing no warnings, because it
uses subclassing for implementing messages handlers.

=item B<synopsis.pl>

Just proving it ;)

=back

=head1 BASIC CONCEPT

The concept of the Xaudio async API is based on forking
an extra process (or thread) for the MPEG decoding and
playing. The parent process controls this process
by sending and recieving messages. This message passing
is asynchronous.

This module interface provides methods for sending common messages
to the MPEG process, eg. play, pause, stop. Also
it implements a message handler to process the messages sent
back. Eg. every message sent to the subprocess will be
acknowledged by sending back an XA_MSG_NOTIFY_ACK message (or
XA_MSG_NOTIFY_NACK on error). Error handling must be set up
by handling this messages.

=head1 CONSTRUCTOR / DEBUGGING

=over 8

=item B<new>

$mp3 = new MPEG::MP3Play (
    [ debug => 'err' | 'all' ]
 );

This is the constructor of this class. It optionally takes
the argument 'debug' to set a debugging level. If debugging
is set to 'err', XA_MSG_NOTIFY_NACK messages will be carp'ed.
Additionally XA_MSG_NOTIFY_ACK messages will be carp'ed if
debugging is set to 'all'.

The debugging is implemented by the methods B<msg_notify_ack>
and B<msg_notify_nack> and works only if you use the builtin
message handler. You can overload them to set up a private error
handling (see chapter USING THE BUILTIN MESSAGE HANDLER for
details).

=item B<debug>

$mp3->debug (
    'err' | 'all' | 'none' | ''
 );

With this method you can set the debugging level at any time.
If you pass an empty string or 'none' debugging will be disabled.

=item B<get_xaudio_implementation>

$xaudio_imp = $mp3->get_xaudio_implementation
@xaudio_imp = $mp3->get_xaudio_implementation

Returns the internal major/minor/revision numbers of your Xaudio
SDK implementation. Returns 0.0.0 if not supported by your Xaudio
version.

=item B<print_xaudio_implementation>

Prints the implementation number to STDOUT.

=back

=head1 CONTROL METHODS

The following methods control the audio playback. Internally
they send messages to the Xaudio subsystem. This message passing
is asynchronous. The result value of these methods indicates
only if the message was sent, but not if it was successfully
processed. Instead the Xaudio subsystem sends back acknowledge
messages. See the chapter MESSAGE HANDLING for details and refer
to the Xaudio documentation.

=over 8

=item B<open>

$sent = $mp3->open ($filename);

Opens the MPEG file $filename. No playback is started at this time.

=item B<close>

$sent = $mp3->close;

Closes an opened file.

=item B<exit>

$sent = $mp3->exit;

The Xaudio thread or process will be canceled.
Use this with care. If you attempt to read or
send messages after using this, you'll get
a broken pipe error.

Generally you need not to use $mp3->exit. The DESTROY
method of MPEG::MP3play cleans up everything well.

=item B<play>

$sent = $mp3->play;

Starts playing back an opened file. Must be called B<after>
$mp3->open.

=item B<stop>

$sent = $mp3->stop;

Stops playing back a playing file. The player rewinds
to the beginning.

=item B<pause>

$sent = $mp3->pause;

Pauses. $mp3->play will go further at the actual position.

=item B<seek>

$sent = $mp3->seek ($offset, $range);

Sets the play position to a specific value. $offset is the
position relative to $range. If $range is 100 and $offset is 50,
it will be positioned in the middle of the song.

=item B<volume>

$sent = $mp3->volume ($pcm_level, $master_level, $balance);

Sets volume parameters. Works only if playing is active.
$pcm_level is the level of the actual MPEG audio stream.
$master_level is the master level of the sound subsystem.
Both values must be set between 0 (silence) and 100
(ear breaking loud).

A $balance of 50 is the middle, smaller is more left, higher
is more right.

You can supply undef for any parameter above and the corresponding
value will not change.

=item B<equalizer>

$sent = $mp3->equalizer ( [ $left_eq_lref, $right_eq_lref ] )

Use this method to control the builtin equalizer codec. If you
omit any parameters, the equalizer will be deactivated, which
preserves CPU time.

The two array references for left and right channel must contain
32 integer elements between -128 and +127. The method will croak
an exception if you pass illegal values.

=item B<get_equalizer>

$sent = $mp3->get_equalizer

This advises the Xaudio subsystem to send us a message back
which contains the acual equalizer settings.

The corresponding message handler method to handle the
message is named

  msg_notify_codec_equalizer

See the chapter about the generic method handler for details
about the message handling mechanism.

The passed message hash will contain a key named 'equalizer',
which is a hash reference with the following content:

  equalizer => {
    left  => $left_eq_lref,
    right => $right_eq_lref
  }

The two lref's are arrays of 32 signed char values, see
$self->equalizer.

=item B<set_player_mode>

$sent = $mp3->set_player_mode ( $flag, ... )

This method sets flags that modify the player's behavior.
It expects a list of XA_PLAYER_MODE_* constants. Currently
supported constants are:

  XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_STOP
  XA_PLAYER_MODE_OUTPUT_AUTO_CLOSE_ON_PAUSE

Refer to the Xaudio documentation for details about this flags.

You can import this constants to your namespace using the ':state' tag
(see CONSTANTS section below).

=item B<set_input_position_range>

$sent = $mp3->set_input_position_range ( $range )

This method sets the player's position range. This is used by the
player to know how frequently to send back XA_MSG_NOTIFY_INPUT_POSITION
message (see details about message handling below) to notify of the
current stream's position. The default is 400, which means
that the input stream has 400 discrete positions that can be notified.

Example: if you wish to display the current position in a
display that is 200 pixels wide, you should set the position range to
200, so the player will not send unnecessary notifications.

=back

=head1 SIMPLE MESSAGE HANDLING

There are two methods to retrieve messages from
the Xaudio subsystem. You can use them to implement
your own message handler. Alternatively you can use
the builtin message handler, described in the next chapter.
Using the builtin message handler is recommended. Your
programm looks better if you use it. Also the debugging
facilitites of MPEG::MP3Play only work in this case.

=over 8

=item B<get_message>

$msg_href = $mp3->get_message;

If there is a message in the players message queue, it will
be returned as a hash reference immediately. This method will
B<not> block if there is no message. It will return undef
instead.

=item B<get_message_wait>

$msg_href = $mp3->get_message_wait ( [$timeout] );

This method will wait max. $timeout microseconds, if there
is no message in the queue. If $timeout is omitted it will
block until the next message appears. The message will be
returned as a hash reference.

B<The message hash>

The returned messages are references to hashes. Please refer
to the Xaudio SDK documentation for details. The message
hashes are build 1:1 out of the structs (in fact a union)
documented there, using _ as a seperator for nested structs.

(Simply use Data::Dumper to learn more about the message
hashes, e.g. that the name of the internal message handler
is stored as $msg_href->{_method_name} ;)

=item B<set_notification_mask>

$sent = $mp3->set_notification_mask ($flag, ...);

By default all messages generated by the Xaudio subsystem
are sent to you. This method sends a message to block or unblock certain
types of notification messages. It expects a list of XA_NOTIFY_MASK_*
constants corresponding to the messages you want to recieve. You
can import this constants to your namespace using the ':mask' tag
(see CONSTANTS section below).

Valid notification mask flags are:

  XA_NOTIFY_MASK_ERROR 
  XA_NOTIFY_MASK_DEBUG 
  XA_NOTIFY_MASK_PROGRESS 
  XA_NOTIFY_MASK_ACK 
  XA_NOTIFY_MASK_NACK 
  XA_NOTIFY_MASK_PLAYER_STATE 
  XA_NOTIFY_MASK_INPUT_STATE 
  XA_NOTIFY_MASK_INPUT_CAPS 
  XA_NOTIFY_MASK_INPUT_NAME 
  XA_NOTIFY_MASK_INPUT_DURATION 
  XA_NOTIFY_MASK_INPUT_POSITION_RANGE 
  XA_NOTIFY_MASK_INPUT_POSITION 
  XA_NOTIFY_MASK_INPUT_TIMECODE_GRANULARITY 
  XA_NOTIFY_MASK_INPUT_TIMECODE 
  XA_NOTIFY_MASK_INPUT_STREAM_INFO 
  XA_NOTIFY_MASK_OUTPUT_STATE 
  XA_NOTIFY_MASK_OUTPUT_NAME 
  XA_NOTIFY_MASK_OUTPUT_VOLUME 
  XA_NOTIFY_MASK_OUTPUT_BALANCE 
  XA_NOTIFY_MASK_OUTPUT_PCM_LEVEL 
  XA_NOTIFY_MASK_OUTPUT_MASTER_LEVEL 
  XA_NOTIFY_MASK_OUTPUT_PORTS 
  XA_NOTIFY_MASK_OUTPUT_CAPS 
  XA_NOTIFY_MASK_CODEC_EQUALIZER 
  XA_NOTIFY_MASK_FEEDBACK_EVENT 

B<Note:>

If debugging is set to 'err' you cannot unset the XA_NOTIFY_MASK_NACK
flag. If debugging ist set to 'all' also unsetting XA_NOTIFY_MASK_NACK
is impossible.

=item B<get_command_read_pipe>

$read_fd = $mp3->get_command_read_pipe;

This method returns the file descriptor of the internal
message pipe as an integer. You can use this to monitor
the message pipe for incoming messages, e.g. through
Gdk in a Gtk application. See samples/gtk*.pl for an
example how to use this feature.

=back

=head1 USING THE BUILTIN MESSAGE HANDLER

You can implement your own message handler based upon the
methods described above. In many cases its easier to use
the builtin message handler.

=over 8

=item B<message_handler>

$mp3->message_handler ( [$timeout] );

This method implements a message handler for all
messages the Xaudio subsystem sends. It infinitely calls
$mp3->get_message_wait and checks if a method according
to the recieved message exists. If the method exists
it will be invoked with the object instance and the
recieved message as parameters. If no method exists, the
message will be ignored.

The infinite message loop exits, if a message method
returns false. B<So, all your message methods must
return true, otherwise the message_handler will
exit very soon ;)>

The names of the message methods are derived from
message names (a complete list of messages is part of
the Xaudio SDK documentation).
The prefix XA_ will be removed, the rest of the name
will be converted to lower case.

B<Example:>
the message handler method for

  XA_MSG_INPUT_POSITION

is

  $mp3->msg_input_position ($msg_href)

The message handler is called with two parameters:
the object instance $mp3 and the $msg_href returned by
the get_message_wait method.

B<Redefining or Subclassing?>

It's implicitly said above, but I want to mention it
explicitly: you must define your message handlers
in the MPEG::MP3Play package, because they are methods
of the MPEG::MP3Play class. So say 'B<package MPEG::MP3Play>'
before writing your handlers.

Naturally you can subclass the MPEG::MP3Play module and
implement your message handlers this way. See
'samples/gtkinherit.pl' as a sample for this.

The disadvantage of simply placing your message handler
subroutines into the MPEG::MP3Play package is that 'C<perl -w>'
throws warning messages like

  Subroutine msg_notify_player_state redefined

if you redefine methods that are already defined by
MPEG::MP3Play. Real subclassing is much prettier but
connected with a little more effort. It's up to you.

As a sample for the "dirty" approach see 'samples/gtkhandler.pl'
It throws the message mentioned above.

B<Doing some work>

If the parameter $timeout is set when calling
$mp3->message_handler, $mp3->get_message_wait
is called with this timeout value. Additionally the method
B<$mp3-E<gt>work> ist invoked after waiting or processing
messages, so you can implement some logic
here to control the module. The work method should not
spend much time, because it blocks the rest of the
control process (not the MPEG audio stream, its processed
in its own thread, respectively process).

If the work method returns false, the method handler
exits.

=item B<work>

$mp3->work;

See explantation in the paragraph above.

=item B<process_messages_nowait>

$mp3->process_messages_nowait;

This method processes all messages in the queue using
the invocation mechanism described above. It returns
immediately when there are no messages to process.
You can use this as an input handler for the
Gtk::Gdk->input_add call, see 'samples/gtkhandler.pl'
for an example of this.

=back

=head2 User data for the message handlers

Often it is necessary that the message handlers can
access some user data, e.g. to manipulate a Gtk widget.
There are two methods to set and get user data. The
user data will be stored in the MPEG::MP3Play object
instance, so it can easily accessed where the instance
handle is available.

=over 8

=item B<set_user_data>

$mp3->set_user_data ( $data );

This sets the user data of the $mp3 handle to $data. It
is a good idea to set $data to a hash reference, so you
can easily store a handful parameters.

B<Example:>

  $mp3->set_user_data ( {
  	pbar_widget   => $pbar,
	win_widget    => $window,
	gdk_input_tag => $input_tag
  } );

=item B<get_user_data>

$data = $mp3->get_user_data;

This returns the data previously set with $mp3->set_user_data
or undef, if no user data was set before.

=back

=head1 DEFAULT MESSAGE HANDLERS

The module provides simple message handlers for some default
behavior. You can overload them, if want to implement your
own functionality.

=over 8

=item B<msg_notify_player_state>

If the current file reaches EOF this handler returns false,
so the message handler will exit.

=item B<msg_notify_ack>

If debugging is set to 'all' this handler will print the
acknowledged message using carp.

=item B<msg_notify_nack>

If debugging is set to 'err' or 'all' this handler will
print the not acknowledged message plus an error string
using carp.

=back

=head1 CONSTANTS

There are many, many constants defined in the Xaudio header
files. E.g. the message codes are defined there as constants.
MPEG::MP3Play knows all defined constants, but does not
export them to the callers namespace by default.

MPEG::MP3Play uses the standard Exporter mechanisms to export
symbols to your namespace. There are some tags defined to
group the symbols (see Exporter manpage on how to use them):

=over 8

=item B<msg>

This exports all symbols you need to do message handling on
your own, particularly all message codes are exported here.
Refer to the source code for a complete listing.

=item B<state>

XA_PLAYER_STATE_*, XA_INPUT_STATE_* and XA_OUTPUT_STATE_*.
Use this to check the actual player state in a
XA_MSG_NOTIFY_PLAYER_STATE message handler.

=item B<mask>

This are all notify mask constants. The're needed to specify
a notification mask. (see B<set_notification_mask>)

=item B<error>

All symbols for Xaudio error handling, incl. success code. I
never needed them so far.

=item B<misc>

Some symbols cannot be assigned to the tags above. They're
collected here (look into the source for a complete list).

=back

=head2 Note:

If you use the builtin message handler mechanism, B<you need not
to import message symbols to your namespace>. Alle message handlers
are methods of the MPEG::MP3Play class, so they can access all
symbols directly.

No import to your namespace at all is needed unless you want to
use $mp3->set_notification_mask or $mp3->set_player_mode!

=head1 USING THE MODULE WITH GTK+

If you want to develop your own MP3 player using MPEG::MP3Play
in conjunction with Gtk+ this is generally a really good idea.
However, there is one small issue regarding this configuration.

First off you have to connect the Xaudio message queue to the
Gtk message handler using something like this (see the example
program 'gtkhandler.pl'):

  my $input_fd = $mp3->get_command_read_pipe;
  my $input_tag = Gtk::Gdk->input_add (
          $input_fd,
          'read',
          sub { $mp3->process_messages_nowait }
  );

Through this the Xaudio process is directly connected by a pipe
to Gtk+.

I don't know exactly what happens, but if you *first* call
Gtk->init and then create a MPEG::MP3Play object you'll get
some Gdk warning messages (BadIDChoice) or a 'Broken Pipe'
error when your program exits.

Obviously Xaudio and Gtk+ disagree about the correct order
of closing the pipe. You're welcome if you know a better
explanation for this.

However, if you *first* create a MPEG::MP3Play object and then
call Gtk->init everything works well (see the samples/gtk*
programs).

=head1 TODO

  - Win32 support
  - support of the full Xaudio API, with input/output
    modules, etc.
  - documentation: more details about the messages
    hashes

Ideas, code and any help are very appreciated.

=head1 BUGS

  - treble control through the equalizer is weak. I checked
    the sent data several times and cannot see any error
    on my side, maybe something with my sound setup is strange,
    or my ears are just broken :)
    Please tell me, if the treble control is OK for you, or not.

=head1 PROBLEMS AND REPORTING BUGS

First check if you're using the most recent version of this
module, maybe the bug you're about to report is already
fixed. Also please read the documentation entirely.

If you find a bug please send me a report. I will fix this as
soon as possible. You'll make my life easier if you provide
the following information along with your bugreport:

  - your OS and Perl version (please send me the output
    of 'perl -V')
  - exact version number of the Xaudio development kit
    you're using (including libc version, if this is relevant
    for your OS, e.g. Linux)
  - for bug reports regarding the GTK+ functionality
    I need the version number of your GTK+ library and
    the version number of your Perl Gtk module.

If you have a solution to fix the bug you're welcome to
send me a unified context diff of your changes, so I can
apply them to the trunk. You'll get a credit in the Changes
file.

If you have problems with your soundsystem (you hear nothing,
or the sound is chopped up) please try to compile the sample
programs that are part of the Xaudio development kit. Do they
work properly? If not, this is most likely a problem of your
sound configuration and not a MPEG::MP3Play issue. Please check
the Xaudio documentation in this case, before contacting me.
Thanks.

=head1 MPEG::MP3Play APPLICATIONS

I'm very interested to know, if someone write applications
based on MPEG::MP3Play. So don't hesitate to send me an email, if
you like (or not like ;) this module.

=head1 TESTED ENVIRONMENTS

This section lists the environments where users reported
me that this module functions well:

  - Perl 5.005_03 and Perl 5.004_04, Linux 2.0.33 and
    Linux 2.2.10, Xaudio SDK 3.01 glibc6,
    gtk+ 1.2.3, Perl Gtk 0.5121

  - FreeBSD 3.2 and 3.3. See README.FreeBSD for details
    about building MPEG::MP3Play for this platform.

  - Irix 6.x, Perl built with -n32

=head1 AUTHOR

Joern Reder <joern@zyn.de>

=head1 COPYRIGHT

Copyright (C) 1999-2001 by Joern Reder, All Rights Reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

The Xaudio SDK is copyright by MpegTV,LLC. Please refer to the
LICENSE text published on http://www.xaudio.com/.

=head1 SEE ALSO

perl(1).

=cut
