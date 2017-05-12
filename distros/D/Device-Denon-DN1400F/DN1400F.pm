package Device::Denon::DN1400F;

use 5.006;
use strict;
use vars qw(@ISA $VERSION @EXPORT_OK %EXPORT_TAGS %COMMANDS);
use warnings;
use Exporter;
use Data::Dumper;
use Device::SerialPort qw(:PARAM :STAT);
use Time::HiRes qw(usleep time);

@ISA = qw(Exporter);
@EXPORT_OK = qw();
%EXPORT_TAGS = ('all' => \@EXPORT_OK);
$VERSION = '0.02';

%COMMANDS = (
	MOVE_FRONT				=> {
			Command	=> [ qw(ID 0xb2) ],
			Answer	=> [ qw(0x80 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	CLEAR_CHANGER_BUFFER	=> {
			Command	=> [ qw(ID 0xC0) ],
			Answer	=> [ qw(0x80 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	_1BYTE_ERROR_CODE		=> {
			Command	=> [ qw(ID 0xC1) ],
			Answer	=> [ qw(ERR0 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	_2BYTE_ERROR_CODE		=> {
			Command	=> [ qw(ID 0xC2) ],
			Answer	=> [ qw(ERR0 ERR1 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	DISC_NUMBER				=> {
			Command	=> [ qw(ID 0xC3) ],
			Answer	=> [ qw(DNO_F DNO_R ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	SELECT_A_DISC			=> {
			Command	=> [ qw(ID 0xC4 DSCP DSCN DID) ],
			Answer	=> [ qw(CST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	RETURN_A_DISC			=> {
			Command	=> [ qw(ID 0xC5 DSCP DSCN DID) ],
			Answer	=> [ qw(CST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	RETURN_ALL_DISC			=> {
			Command	=> [ qw(ID 0xC6) ],
			Answer	=> [ qw(CST0 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	RESET_DN_1400F			=> {
			Command	=> [ qw(ID 0xCA) ],
			Answer	=> [ qw() ],
			Busy	=> [ qw(INVD ID) ],
				},
	CHANGER_MICON_VERSION	=> {
			Command	=> [ qw(ID 0xCB 0x00) ],
			Answer	=> [ qw(VER0 VER1 ID) ],
			Busy	=> [ qw(INVD ID) ],
				},
	DISCNUMBER_CHANGER_STATUS=>{
			Command	=> [ qw(ID 0xCC) ],
			Answer	=> [ qw(DSCP_0 DSCN_0 CST0_0
							DSCP_1 DSCN_1 CST0_1 CST1 ID)],
			Busy	=> [ qw(INVD ID) ],
				},
	DRIVE_STATUS			=> {
			Command	=> [ qw(ID 0xCB DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	DRIVE_MICON_VERSION		=> {
			Command	=> [ qw(ID 0xD1 DID) ],
			Answer	=> [ qw(VER0 VER1 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	DRIVE_STATUS_SERVOONOFF	=> {
			Command	=> [ qw(ID 0xD2 DID) ],
			Answer	=> [ qw(DST0 DST1 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	SUB_CODE_QMODE3			=> {
			Command	=> [ qw(ID 0xD6 DID) ],
			Answer	=> [ qw(DST0 CTR_L),
						map{"ISRC_$_"}(0..7),
						qw(AFR_M ID DID)],
			Busy	=> [ qw(INVD ID DID) ],
				},
	SUB_CODE_QMODE2			=> {
			Command	=> [ qw(ID 0xD7 DID) ],
			Answer	=> [ qw(DST0 CTR_L),
						map{"UPC_$_"}(0..7),
						qw(AFR_M ID DID)],
			Busy	=> [ qw(INVD ID DID) ],
				},
	SUB_CODE_QCHANNEL		=> {
			Command	=> [ qw(ID 0xD9 DID) ],
			Answer	=> [ qw(DST0 CTRL TNO INX MIN SEC FRM 0x00
							AMIN ASEC AFRM ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	ALL_TOC_DATA			=> {
			Command	=> [ qw(ID 0xDA DID) ],
			Answer	=> [ qw(0xA0 PMIN 0x00 0x00 CTRL
							YADDA EOT 0x00
							YADDA DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
			Variable=> 1,
				},
	SHORT_TOC_DATA			=> {
			Command	=> [ qw(ID 0xDB DID) ],
			Answer	=> [ qw(0xA0 PMIN 0x00 0x00
							CTRL YADDA EOT DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
			Variable=> 1,
				},
	PLAY_AUDIO			=> {
			Command	=> [ qw(ID 0xE2 AMIN ASEC AFRM TNO INX MODE DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	AUDIO_SCAN			=> {
			Command	=> [ qw(ID 0xE3 AMIN ASEC AFRM TNO INX MODE DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	PAUSE					=> {
			Command	=> [ qw(ID 0xE5 MODE DID) ],	# Docs are buggy
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	SEEK					=> {
			Command	=> [ qw(ID 0xE6 AMIN ASEC AFRM DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	STOP					=> {
			Command	=> [ qw(ID 0xE7 DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	# 25-26 reserved
	TRACK_SEARCH		=> {
			Command	=> [ qw(ID 0xEC AMIN ASEC AFRM TNO INX MODE DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	AUDIO_CHANNEL_CONTROL	=> {
			Command	=> [ qw(ID 0xED) ],
			Answer	=> [ qw(CST0 ID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	# 29 reserved
	FADE_INOUT_PLAY		=> {
			Command	=> [ qw(ID 0xF2 AMIN ASEC AFRM TNO INX MODE DID) ],
			Answer	=> [ qw(DST0 ID DID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
	SYSTEM_MICON_VERSION	=> {
			Command	=> [ qw(ID 0xF3) ],
			Answer	=> [ qw(VER0 VER1 ID) ],
			Busy	=> [ qw(INVD ID DID) ],
				},
		);


sub new {
	my $class = shift;
	my $self = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	die "No SerialPort specified" unless $self->{SerialPort};

	# Device::SerialPort->debug(1);

	my $port = new Device::SerialPort(
					$self->{SerialPort},
					0,
					undef);
	die "Failed to open device $self->{SerialPort}" unless $port;

	$port->user_msg(1);
	$port->error_msg(1);
	# $port->debug(1);

	$port->baudrate(19200);
	$port->parity("even");
	$port->parity_enable("yes");
	$port->databits(8);
	$port->stopbits(1);
	$port->handshake("none");

	$port->write_settings or die "Failed to write settings\n";

	$port->status;

	$self->{Port} = $port;

	$self->{LastCommand} = time;

	return bless $self, $class;
}

sub commands {
	return keys(%COMMANDS);
}

sub _cmd {
	my $self = shift;
	my $command = shift;
	my $args = ($#_ == 0) ? { %{ (shift) } } : { @_ };

	# We can't send the commands to it too fast. It confuses it.
	while (time - $self->{LastCommand} < 0.2) {
		usleep(50);
	}
	$self->{LastCommand} = time;

	my $data = $COMMANDS{$command};
	die "No such command $command" unless $data;

	print "Executing command $command\n";

	my @template = @{ $data->{Command} };
	my @bytes = ();
	foreach (@template) {
		if ($_ =~ /^0x[[:xdigit:]]+$/) {
			push(@bytes, hex($_));
		}
		elsif ($_ eq 'ID') {
			push(@bytes, $self->{Id} + 0x50);
		}
		else {
			die "No value for required parameter $_"
							unless exists $args->{$_};
			print "$_ = $args->{$_}\n";
			push(@bytes, $args->{$_});
		}
	}

	my @hex = map { sprintf("%2.2x", $_) } @bytes;
	my $string = pack("C*", @bytes);
	my $count = $self->{Port}->write($string);
	print "<< @hex\n";
	die "Wrote only $count bytes" unless $count == length $string;

	return { } if $command eq 'RESET_DN_1400F';

	my $prefix;
	my $timer = 0;
	while (1) {
		usleep(10);
		($count, $prefix) = $self->{Port}->read(1);
		last if $count;
		die "Got no response to command!" if ++$timer > 100;
	}

	if ($prefix eq "\xdd") {
		print "Response is an error code.\n";
		@template = @{ $data->{Busy} };
	}
	else {
		@template = @{ $data->{Answer} };
	}

	my $readlength;
	if ($data->{Variable}) {
		# Wait long enough for the data to come down the line.
		usleep(400000);
		# Long enough for ALL_TOC_DATA. In theory we should read
		# and lex, rather than trying to slurp, then we would know
		# when the end of the data is.
		$readlength = 1000;
	}
	else {
		$readlength = scalar(@template) - 1;
	}

	($count, $string) = $self->{Port}->read($readlength);
	my @response = unpack("C*", $prefix . $string);

	@hex = map { sprintf("%2.2x", $_) } @response;
	print ">> @hex\n";

	# A slight kludge to get this out of the system.
	return { Data => \@response } if $data->{Variable};

	die "Reponse template not same size as response"
					unless @template == @response;

	my %out = map { $template[$_] => $response[$_] } (0..$#template);
	return \%out;
}

sub command {
	my $self = shift;
	my $response = $self->_cmd(@_);
	$self->print_response($response);
	return $response;
}

my %ID = map { $_ + 0x50 => "Unit $_" } (0..15);

my %CST0 = (
	0x80	=> "Command complete, reception normally completed.",
	0x81	=> "No Disc",
	0x82	=> "Busy, Disc transport section is in disc transport processing",
	0x83	=> "Completed Disc Set with No Error",
	0x84	=> "Reserved",
	0x85	=> "Reserved",
	0x86	=> "Reserved",
	0x8A	=> "Initial Busy, After power on and Reset DN-1400F",
	0x8B	=> "Changer Error",
	0x8C	=> "Disc Rack in not set",
	0x8E	=> "Wait transportation",
	0x8F	=> "Changer Error",
	0xDD	=> "INVD, Command Busy or Invalid Command",
		);

my %DST0 = (
	0xB0	=> "Ready, Reception normally completed.",
	0xB1	=> "Fade In / Out Play, In the process of fade in/out play",
	0xB2	=> "Seek, In the process of search.",
	0xB3	=> "Reserved",
	0xB4	=> "Pause, Pause condition during audio play.",
	0xB5	=> "Scan, In the process of scan play execution.",
	0xB6	=> "Play, In the process of audio play.",
	0xB7	=> "Reserved",
	0xB8	=> "Disc Change. Disc has been changed.",
	0xB9	=> "No Disc, Disc is not set in the disc loading section.",
	0xBA	=> "Reserved",
	0xBB	=> "Seek Error",
	0xBC	=> "EOT: End of TOC",
	0xBF	=> "CD-ROM Data Area",
	0xD0	=> "RAM Error (CD-DRIVE Hardware Error)",
	0xD1	=> "FOK Error (CD-DRIVE Hardware Error)",
	0xD2	=> "FZC Error (CD-DRIVE Hardware Error)",
	0xD3	=> "GFS Error (CD-DRIVE Hardware Error)",
	0xD5	=> "Slide Error (CD-DRIVE Hardware Error)",
	0xD6	=> "Eject Sequence Error (CD-DRIVE Hardware Error)",
	0xD7	=> "Gain Control Error (CD-DRIVE Hardware Error)",
	0xD8	=> "Reserved",
	0xD9	=> "Reserved",
	0xDA	=> "Reserved",
	0xDB	=> "Invalid Command or Invalid Parameter",
	0xDC	=> "Invalid Parameter",
	0xDD	=> "INVD: Command busy or Invalid Command.",
		);

my %DST1 = (
	0x00	=> "Servo off",
	0x01	=> "Servo on",
		);

my %DID = (
	0x00	=> "Drive 1: Front",
	0x01	=> "Drive 2: Rear",
		);

my %ERR = (
	0x00	=> "No error",
		);

sub print_response_item {
	my ($self, $response, $key, $values) = @_;
	if (exists $response->{$key}) {
		my $value = $values
				? ($values->{$response->{$key}} || "VALUE UNKNOWN!")
				: $response->{$key};
		print "* $key: " .
				sprintf("%x", $response->{$key}) . " : $value\n";
		delete $response->{$key};
	}
}

sub print_response {
	my ($self, $response) = @_;

	my %copy = %$response;
	$self->print_response_item(\%copy, "ID", \%ID);
	$self->print_response_item(\%copy, "DID", \%DID);
	$self->print_response_item(\%copy, "CST0", \%CST0);
	$self->print_response_item(\%copy, "DST0", \%DST0);
	$self->print_response_item(\%copy, "DST1", \%DST1);
	$self->print_response_item(\%copy, "DID", \%DID);
	$self->print_response_item(\%copy, "ERR0", \%ERR);
	$self->print_response_item(\%copy, "ERR1", \%ERR);
	foreach (keys %copy) {
		if ($_ =~ /^0x/) {
			if (hex($_) != $response->{$_}) {
				print "Expected $_, got " .
								sprintf("%2.2x\n", $response->{$_});
			}
		}
		else {
			$self->print_response_item(\%copy, $_, undef);
		}
	}
}

sub _dscpn {
	my $discno = shift;

	my ($dscp, $dscn);

	if ($discno < 0) {
		die "Invalid disc number $discno\n";
	}
	elsif ($discno <= 50) {
		$dscp = 0;
		$dscn = $discno - 1;
	}
	elsif ($discno <= 100) {
		$dscp = 1;
		$dscn = $discno - 51;
	}
	elsif ($discno <= 150) {
		$dscp = 2;
		$dscn = $discno - 101;
	}
	elsif ($discno <= 200) {
		$dscp = 3;
		$dscn = $discno - 151;
	}
	else {
		die "Invalid disc number $discno\n";
	}

	return ($dscp, $dscn);
}

sub _discno {
	my ($dscp, $dscn) = @_;
	return -1 if $dscp == 255;
	return $dscp * 50 + $dscn + 1;
}

sub _from_bcd {
	my $val = shift;
	return 0+ sprintf("%x", $val);
}

# Interpreting a number as hex essentially codes it as BCD.
sub _to_bcd {
	my $val = shift;
	return hex($val);
}

sub move_front {
	my ($self) = @_;
	return $self->command('MOVE_FRONT');
}

sub clear_changer_buffer {
	my ($self) = @_;
	return $self->command('CLEAR_CHANGER_BUFFER');
}

sub debug {
	my ($self) = @_;
	$self->command('_1BYTE_ERROR_CODE');
	$self->command('_2BYTE_ERROR_CODE');
}

sub loaded_discs {
	my ($self) = @_;
	my $response = $self->command('DISC_NUMBER');
	return ($response->{DNO_F}, $response->{DNO_R});
}

sub load_disc {
	my ($self, $drive, $discno, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	($args->{DSCP}, $args->{DSCN}) = _dscpn($discno);
	return $self->command('SELECT_A_DISC', $args);
}

sub unload_disc {
	my ($self, $drive, $discno, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	($args->{DSCP}, $args->{DSCN}) = _dscpn($discno);
	return $self->command('RETURN_A_DISC', $args);
}

sub unload_discs {
	my ($self) = @_;
	return $self->command('RETURN_ALL_DISC');
}

sub reset {
	my ($self) = @_;
	return $self->command('RESET_DN_1400F');
}

# Calling this immediately after loaded_discs barfs. Firmware bug?
sub changer_version {
	my ($self) = @_;
	# This command seems to be broken on mine.
	my $response = $self->command('CHANGER_MICON_VERSION');
	return ($response->{VER0}, $response->{VER1})
}

sub status {
	my ($self) = @_;
	# This command seems to be broken on mine.
	my $response = $self->command('DISCNUMBER_CHANGER_STATUS');
	return {
				Disc0	=> _discno($response->{DSCP_0},
									$response->{DSCN_0}),
				Disc1	=> _discno($response->{DSCP_1},
									$response->{DSCN_1}),
				Status0	=> $CST0{$response->{CST0_0}},
				Status1	=> $CST0{$response->{CST0_1}},
					};
}

# As far as I can work out, the firmware on this one is buggy too.
sub drive_status {
	my ($self, $drive, $args) = @_;
	die "Buggy firmware in the drive_status command.";
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('DRIVE_STATUS', $args);
}

sub drive_version {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('DRIVE_MICON_VERSION', $args);
}

sub drive_status_servo_onoff {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('DRIVE_STATUS_SERVOONOFF', $args);
}

sub drive_subcode_qchannel {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('SUB_CODE_QCHANNEL', $args);
	return {
		Status		=> $DST0{$response->{DST0}},
		QControl	=> $response->{CTRL} >> 4,
		QAddress	=> $response->{CTRL} & 0xf,
		Track		=> _from_bcd($response->{TNO}),
		Index		=> _from_bcd($response->{INX}),
		Minute		=> _from_bcd($response->{MIN}),
		Second		=> _from_bcd($response->{SEC}),
		Frame		=> _from_bcd($response->{FRM}),
		AbsoluteMinute	=> _from_bcd($response->{AMIN}),
		AbsoluteSecond	=> _from_bcd($response->{ASEC}),
		AbsoluteFrame	=> _from_bcd($response->{AFRM}),
			};
}

sub toc_data_long {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('ALL_TOC_DATA', $args);
	return $response->{Data};
}

sub toc_data_short {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	my $response = $self->command('SHORT_TOC_DATA', $args);
	return $response->{Data};
}

sub drive_play {
	my ($self, $drive, $track, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	$args->{TNO} = _to_bcd($track);
	$args->{MODE} = 0x29;
	$args->{INX} = 1;	# What is this?
	foreach (qw(AMIN ASEC AFRM)) {
		$args->{$_} = 0 unless exists $args->{$_};
	}
	return $self->command('PLAY_AUDIO', $args);
}

sub drive_scan {
	my ($self, $drive, $track, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	$args->{TNO} = _to_bcd($track);
	$args->{MODE} = 0x29;
	$args->{INX} = 1;	# What is this?
	foreach (qw(AMIN ASEC AFRM)) {
		$args->{$_} = 0 unless exists $args->{$_};
	}
	return $self->command('AUDIO_SCAN', $args);
}

sub drive_pause {
	my ($self, $drive, $mode, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	$args->{MODE} = $mode ? 0x01 : 0x00;
	return $self->command('PAUSE', $args);
}

sub drive_stop {
	my ($self, $drive, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	return $self->command('STOP', $args);
}

sub drive_search {
	my ($self, $drive, $track, $args) = @_;
	$args = {} unless ref($args) eq 'HASH';
	$args->{DID} = $drive;
	$args->{TNO} = _to_bcd($track);
	$args->{MODE} = 0x29;
	$args->{INX} = 1;	# What is this?
	foreach (qw(AMIN ASEC AFRM)) {
		$args->{$_} = 0 unless exists $args->{$_};
	}
	return $self->command('TRACK_SEARCH', $args);
}

1;

__END__

=head1 NAME

Device::Denon::DN1400F - Control a Denon DN-1400F CD player

=head1 SYNOPSIS

  use Device::Denon::DN1400F;

  my $denon = new Device::Denon::DN1400F(
  				SerialPort	=> '/dev/ttyS0',
				Id		=> $deviceid,
					);

  $denon->load_disc($drive, $discno);
  $denon->drive_play($drive, $track);
  $denon->drive_pause($drive, $paused);
  $denon->drive_stop($drive);
  $denon->unload_disc($drive, $discno);
  $denon->unload_discs;

  print $denon->drive_status($drive);
  print $denon->drive_subcode_qchannel($drive);
  print $denon->toc_data_long($drive);
  print $denon->toc_data_short($drive);

  $denon->debug;
  $denon->reset;
  $denon->move_front;

=head1 DESCRIPTION

This module gives an object oriented interface to control the Denon
DN-1400F, an RS232 controlled 200 CD two-turntable jukebox designed
for nonstop playout.

Many methods are available, it is currently still best to browse the
source to find the details.

=head2 EXPORT

None by default.


=head1 AUTHOR

Shevek E<lt>cpan@anarres.orgE<gt>

=head1 SEE ALSO

L<perl>.

=cut
