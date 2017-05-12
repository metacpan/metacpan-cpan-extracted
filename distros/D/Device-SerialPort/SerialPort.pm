# This is a POSIX version of the Win32::Serialport module
# ported by Joe Doss, Kees Cook 
# Originally for use with the MisterHouse and Sendpage programs
#
# $Id: SerialPort.pm 313 2007-10-24 05:50:46Z keescook $
#
# Copyright (C) 1999, Bill Birthisel
# Copyright (C) 2000-2007 Kees Cook
# kees@outflux.net, http://outflux.net/
# 
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
# http://www.gnu.org/copyleft/gpl.html
#
package Device::SerialPort;

use 5.006;
use strict;
use warnings;
use POSIX qw(:termios_h);
use IO::Handle;
use Carp;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 1.04;

require Exporter;

@ISA = qw(Exporter);
@EXPORT= qw();
@EXPORT_OK= qw();
%EXPORT_TAGS = (STAT	=> [qw( MS_CTS_ON	MS_DSR_ON
                                MS_RING_ON	MS_RLSD_ON
                                MS_DTR_ON   MS_RTS_ON
                                ST_BLOCK	ST_INPUT
                                ST_OUTPUT	ST_ERROR
                                TIOCM_CD TIOCM_RI
                                TIOCM_DSR TIOCM_DTR
                                TIOCM_CTS TIOCM_RTS
                                TIOCM_LE
                               )],

                PARAM	=> [qw( LONGsize	SHORTsize	OS_Error
                                nocarp		yes_true )]);

Exporter::export_ok_tags('STAT', 'PARAM');

$EXPORT_TAGS{ALL} = \@EXPORT_OK;

require XSLoader;
XSLoader::load('Device::SerialPort', $VERSION);

#### Package variable declarations ####

use vars qw($IOCTL_VALUE_RTS $IOCTL_VALUE_DTR $IOCTL_VALUE_TERMIOXFLOW 
            $ms_per_tick);

# Load all the system bits we need
my $bits=Device::SerialPort::Bits::get_hash();
my $ms_per_tick=undef;

# ioctl values
$IOCTL_VALUE_RTS = pack('L', $bits->{'TIOCM_RTS'} || 0);
$IOCTL_VALUE_DTR = pack('L', $bits->{'TIOCM_DTR'} || 0);
$IOCTL_VALUE_TERMIOXFLOW = (($bits->{'CTSXON'}||0) | ($bits->{'RTSXOFF'}||0));

# non-POSIX constants commonly defined in termios.ph
sub CRTSCTS { return $bits->{'CRTSCTS'} || 0; }

sub OCRNL { return $bits->{'OCRNL'} || 0; }

sub ONLCR { return $bits->{'ONLCR'} || 0; }

sub ECHOKE { return $bits->{'ECHOKE'} || 0; }

sub ECHOCTL { return $bits->{'ECHOCTL'} || 0; }

sub TIOCM_LE { return $bits->{'TIOCSER_TEMT'} || $bits->{'TIOCM_LE'} || 0; }

# Set alternate bit names
$bits->{'portable_TIOCINQ'} = $bits->{'TIOCINQ'} || $bits->{'FIONREAD'};

## Next 4 use Win32 names for compatibility

sub MS_RLSD_ON { return TIOCM_CD(); }
sub TIOCM_CD { return $bits->{'TIOCM_CAR'} || $bits->{'TIOCM_CD'} || 0; }

sub MS_RING_ON { return TIOCM_RI(); }
sub TIOCM_RI { return $bits->{'TIOCM_RNG'} || $bits->{'TIOCM_RI'} || 0; }

sub MS_CTS_ON { return TIOCM_CTS(); }
sub TIOCM_CTS { return $bits->{'TIOCM_CTS'} || 0; }

sub MS_DSR_ON { return TIOCM_DSR(); }
sub TIOCM_DSR { return $bits->{'TIOCM_DSR'} || 0; }

# For POSIX completeness
sub MS_RTS_ON { return TIOCM_RTS(); }
sub TIOCM_RTS { return $bits->{'TIOCM_RTS'} || 0; }

sub MS_DTR_ON { return TIOCM_DTR(); }
sub TIOCM_DTR { return $bits->{'TIOCM_DTR'} || 0; }

# "status"
sub ST_BLOCK	{0}	# status offsets for caller
sub ST_INPUT	{1}
sub ST_OUTPUT	{2}
sub ST_ERROR	{3}	# latched

# parameters that must be included in a "save" and "checking subs"

my %validate =	(
		ALIAS		=> "alias",
		E_MSG		=> "error_msg",
		RCONST		=> "read_const_time",
		RTOT		=> "read_char_time",
		U_MSG		=> "user_msg",
		DVTYPE		=> "devicetype",
		HNAME		=> "hostname",
		HADDR		=> "hostaddr",
		DATYPE		=> "datatype",
		CFG_1		=> "cfg_param_1",
		CFG_2		=> "cfg_param_2",
		CFG_3		=> "cfg_param_3",
		);

my @termios_fields = (
		     "C_CFLAG",
		     "C_IFLAG",
		     "C_ISPEED",
		     "C_LFLAG",
		     "C_OFLAG",
		     "C_OSPEED"
		     );

my %c_cc_fields = (
		   VEOF     => &POSIX::VEOF,
		   VEOL     => &POSIX::VEOL,
		   VERASE   => &POSIX::VERASE,
		   VINTR    => &POSIX::VINTR,
		   VKILL    => &POSIX::VKILL,
		   VQUIT    => &POSIX::VQUIT,
		   VSUSP    => &POSIX::VSUSP,
		   VSTART   => &POSIX::VSTART,
		   VSTOP    => &POSIX::VSTOP,
		   VMIN     => &POSIX::VMIN,
		   VTIME    => &POSIX::VTIME,
		   );

my @baudrates = qw(
    0 50 75 110 134 150 200 300 600
    1200 1800 2400 4800 9600 19200 38400 57600
    115200 230400 460800 500000 576000 921600 1000000
    1152000 2000000 2500000 3000000 3500000 4000000
);

# Build list of "valid" system baudrates
my %bauds;
foreach my $baud (@baudrates) {
    my $baudvar="B$baud";
    $bauds{$baud}=$bits->{$baudvar} if (defined($bits->{$baudvar}));
}

my $Babble = 0;
my $testactive = 0;	# test mode active

my @Yes_resp = (
		"YES", "Y",
		"ON",
		"TRUE", "T",
		"1"
		);

my @binary_opt = ( 0, 1 );
my @byte_opt = (0, 255);

my $cfg_file_sig="Device::SerialPort_Configuration_File -- DO NOT EDIT --\n";

## my $null=[];
my $null=0;
my $zero=0;

# Preloaded methods go here.

sub init_ms_per_tick
{
	my $from_posix=undef;
	my $errors="";

	# To find the real "CLK_TCK" value, it is *best* to query sysconf
	# for it.  However, this requires access to _SC_CLK_TCK.  In
	# modern versions of Perl (and libc) these this is correctly found
	# in the POSIX module.  On really old versions, the hard-coded
	# "CLK_TCK" can be found.  So, first attempt to use the POSIX
	# module to get what we need, and then try our internal bit
	# detection code, and finally fall back to the hard-coded value
	# before totally giving up.
	for (;;) {
		eval { $from_posix = POSIX::sysconf(&POSIX::_SC_CLK_TCK); };
		last if (!$@);
		$errors.="$@\n";

		if (defined($bits->{'_SC_CLK_TCK'})) {
			$from_posix = POSIX::sysconf($bits->{'_SC_CLK_TCK'});
			last;
		}
		$errors.="_SC_CLK_TCK not found during compilation\n";

		# According to POSIX, "CLK_TCK" is obsolete now.  See
		# "man 2 times" and the POSIX-1996 standard
		eval { $from_posix = &POSIX::CLK_TCK; };
		last if (!$@);
		$errors.="$@\n";

		last;
	}
	if (!defined($from_posix) || $from_posix == 0) {
		die "Cannot find a useful value for _SC_CLK_TCK:\n$errors";
	}
	$ms_per_tick = 1000.0 / $from_posix;
}

sub get_tick_count {
	# clone of Win32::GetTickCount - perhaps same 49 day problem

    if (!defined($ms_per_tick)) {
	init_ms_per_tick();
    }

    my ($real2, $user2, $system2, $cuser2, $csystem2) = POSIX::times();
    $real2 *= $ms_per_tick;
    ## printf "real2 = %8.0f\n", $real2;
    return int $real2;
}

sub SHORTsize { 0xffff; }	# mostly for AltPort test
sub LONGsize { 0xffffffff; }	# mostly for AltPort test

sub OS_Error { print "Device::SerialPort OS_Error\n"; }

# test*.pl only - suppresses default messages
sub set_test_mode_active {
    return unless (@_ == 2);
    $testactive = $_[1];     # allow "off"
    my @fields = @termios_fields;
    my $item;
    foreach $item (keys %c_cc_fields) {
        push @fields, "C_$item";
    }
    foreach $item (keys %validate) {
        push @fields, "$item";
    }
    return @fields;
}

sub nocarp { return $testactive }

sub yes_true {
    my $choice = uc shift;
    my $ans = 0;
    foreach (@Yes_resp) { $ans = 1 if ( $choice eq $_ ) }
    return $ans;
}

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self  = {};
    my $ok    = 0;		# API return value

    my $item = 0;

    my $nameOrConf = shift;
    return start($class, $nameOrConf, @_) if (-f $nameOrConf && ! -c $nameOrConf );

    $self->{NAME}     = $nameOrConf;


    shift; # ignore "$quiet" parameter
    my $lockfile = shift;
    if ($lockfile) {
        $self->{LOCK} = $lockfile;
        my $lockf = POSIX::open($self->{LOCK}, 
				    &POSIX::O_WRONLY |
				    &POSIX::O_CREAT |
				    &POSIX::O_NOCTTY |
				    &POSIX::O_EXCL);
        return undef if (!defined($lockf));

        my $pid = "$$\n";
        $ok = POSIX::write($lockf, $pid, length $pid);
        my $ok2 = POSIX::close($lockf);
        return unless ($ok && (defined $ok2));
        sleep 2;	# wild guess for Version 0.05
    }
    else {
        $self->{LOCK} = "";
    }

    $self->{FD}= POSIX::open($self->{NAME}, 
				    &POSIX::O_RDWR |
				    &POSIX::O_NOCTTY |
				    &POSIX::O_NONBLOCK);

    unless (defined $self->{FD}) { $self->{FD} = -1; }
    unless ($self->{FD} >= 0) {
        # the "unlink" will destroy the err code, so preserve it
        my $save_err=$!+0;

        if ($self->{LOCK}) {
            unlink $self->{LOCK};
            $self->{LOCK} = "";
        }

        $!=$save_err+0;
        return undef;
    }

    $self->{TERMIOS} = POSIX::Termios->new();

    # a handle object for ioctls: read-only ok
    $self->{HANDLE} = new_from_fd IO::Handle ($self->{FD}, "r");
    
    # get the current attributes
    $ok = $self->{TERMIOS}->getattr($self->{FD});

    unless ( $ok ) {
        carp "can't getattr: $!";
        undef $self;
        return undef;
    }

    # save the original values
    $self->{"_CFLAG"} = $self->{TERMIOS}->getcflag();
    $self->{"_IFLAG"} = $self->{TERMIOS}->getiflag();
    $self->{"_ISPEED"} = $self->{TERMIOS}->getispeed();
    $self->{"_LFLAG"} = $self->{TERMIOS}->getlflag();
    $self->{"_OFLAG"} = $self->{TERMIOS}->getoflag();
    $self->{"_OSPEED"} = $self->{TERMIOS}->getospeed();

    # build termiox flag anyway
    $self->{'TERMIOX'} = 0;

    # copy the original values into "current" values
    foreach $item (keys %c_cc_fields) {
        $self->{"_$item"} = $self->{TERMIOS}->getcc($c_cc_fields{$item});
    }
    foreach $item (keys %c_cc_fields) {
        $self->{"C_$item"} = $self->{"_$item"};
    }
    $self->{"C_CFLAG"} = $self->{"_CFLAG"};
    $self->{"C_IFLAG"} = $self->{"_IFLAG"};
    $self->{"C_ISPEED"} = $self->{"_ISPEED"};
    $self->{"C_LFLAG"} = $self->{"_LFLAG"};
    $self->{"C_OFLAG"} = $self->{"_OFLAG"};
    $self->{"C_OSPEED"} = $self->{"_OSPEED"};

    # Finally, default to "raw" mode for this package
    $self->{"C_IFLAG"} &= ~(IGNBRK|BRKINT|PARMRK|IGNPAR|INPCK|ISTRIP|INLCR|IGNCR|ICRNL|IXON);
    $self->{"C_OFLAG"} &= ~OPOST;
    $self->{"C_LFLAG"} &= ~(ECHO|ECHONL|ICANON|ISIG|IEXTEN);

    # "minicom" does some alarming things for setting up "raw", which is mostly
    # just the direct manipulation of the i, o, and l termios flags
    #$self->{"C_IFLAG"} = 0;
    #$self->{"C_OFLAG"} = 0;
    #$self->{"C_LFLAG"} = 0;

    # Sane port
    $self->{"C_IFLAG"} |= IGNBRK;
    $self->{"C_CFLAG"} |= (CLOCAL|CREAD);

    # 9600 baud
    $self->{"C_OSPEED"} = $bauds{"9600"};
    $self->{"C_ISPEED"} = $bauds{"9600"};

    # 8data bits
    $self->{"C_CFLAG"} &= ~CSIZE;
    $self->{"C_CFLAG"} |= CS8;

    # disable parity
    $self->{"C_CFLAG"} &= ~(PARENB | PARODD);

    # 1 stop bit
    $self->{"C_CFLAG"} &= ~CSTOPB;

    # by default, disable the OSX arbitrary baud settings
    $self->{"IOSSIOSPEED_BAUD"} = -1;

    &write_settings($self);

    $self->{ALIAS} = $self->{NAME};	# so "\\.\+++" can be changed

    # "private" data
    $self->{"_DEBUG"}    	= 0;
    $self->{U_MSG}     		= 0;
    $self->{E_MSG}     		= 0;
    $self->{RCONST}   		= 0;
    $self->{RTOT}   		= 0;
    $self->{"_T_INPUT"}		= "";
    $self->{"_LOOK"}		= "";
    $self->{"_LASTLOOK"}	= "";
    $self->{"_LASTLINE"}	= "";
    $self->{"_CLASTLINE"}	= "";
    $self->{"_SIZE"}		= 1;
    $self->{OFS}		= "";
    $self->{ORS}		= "";
    $self->{"_LMATCH"}		= "";
    $self->{"_LPATT"}		= "";
    $self->{"_PROMPT"}		= "";
    $self->{"_MATCH"}		= [];
    $self->{"_CMATCH"}		= [];
    @{ $self->{"_MATCH"} }	= "\n";
    @{ $self->{"_CMATCH"} }	= "\n";
    $self->{DVTYPE}		= "none";
    $self->{HNAME}		= "localhost";
    $self->{HADDR}		= 0;
    $self->{DATYPE}		= "raw";
    $self->{CFG_1}		= "none";
    $self->{CFG_2}		= "none";
    $self->{CFG_3}		= "none";

    bless ($self, $class);

    unless ($self->can_ioctl()) {
       nocarp or carp "disabling ioctl methods - system constants not found\n";
    }

#	These might be a good idea (but we'll need to change the tests)
#    $self->read_char_time(0); 	  # no time
#    $self->read_const_time(100); # 10th of a second

    return $self;
}

# Returns "1" on success
sub write_settings {
    my $self = shift;
    my ($item, $result);

    # put current values into Termios structure
    $self->{TERMIOS}->setcflag($self->{"C_CFLAG"});
    $self->{TERMIOS}->setlflag($self->{"C_LFLAG"});
    $self->{TERMIOS}->setiflag($self->{"C_IFLAG"});
    $self->{TERMIOS}->setoflag($self->{"C_OFLAG"});
    $self->{TERMIOS}->setispeed($self->{"C_ISPEED"});
    $self->{TERMIOS}->setospeed($self->{"C_OSPEED"});

    foreach $item (keys %c_cc_fields) {
        $self->{TERMIOS}->setcc($c_cc_fields{$item}, $self->{"C_$item"});
    }

    # setattr returns undef on failure
    $result = defined($self->{TERMIOS}->setattr($self->{FD}, &POSIX::TCSANOW));

    # IOSSIOSPEED settings are overwritten by setattr, so this needs to be
    # called last.
    if ($self->{"IOSSIOSPEED_BAUD"} != -1 && $self->can_arbitrary_baud()) {
        my $speed = pack( "L", $self->{"IOSSIOSPEED_BAUD"});
        $self->ioctl('IOSSIOSPEED', \$speed );
    }

    if ($Babble) {
        print "wrote settings to $self->{ALIAS}\n";
    }

    return $result; 
}

sub save {
    my $self = shift;
    my $item;
    my $getsub;
    my $value;

    return unless (@_);

    my $filename = shift;
    unless ( open CF, ">$filename" ) {
        #carp "can't open file: $filename"; 
        return undef;
    }
    print CF "$cfg_file_sig";
    print CF "$self->{NAME}\n";
	# used to "reopen" so must be DEVICE=NAME
    print CF "$self->{LOCK}\n";
	# use lock to "open" if established

    # put current values from Termios structure FIRST
    foreach $item (@termios_fields) {
        printf CF "$item,%d\n", $self->{"$item"};
    }
    foreach $item (keys %c_cc_fields) {
        printf CF "C_$item,%d\n", $self->{"C_$item"};
    }
    
    no strict 'refs';		# for $gosub
    while (($item, $getsub) = each %validate) {
        chomp $getsub;
        $value = scalar &$getsub($self);
        print CF "$item,$value\n";
    }
    use strict 'refs';
    close CF;
    if ($Babble) {
        print "wrote file $filename for $self->{ALIAS}\n";
    }
    1;
}

# parse values for start/restart
sub get_start_values {
    return unless (@_ == 2);
    my $self = shift;
    my $filename = shift;

    unless ( open CF, "<$filename" ) {
        carp "can't open file: $filename: $!"; 
        return;
    }
    my ($signature, $name, $lockfile, @values) = <CF>;
    close CF;
    
    unless ( $cfg_file_sig eq $signature ) {
        carp "Invalid signature in $filename: $signature"; 
        return;
    }
    chomp $name;
    unless ( $self->{NAME} eq $name ) {
        carp "Invalid Port DEVICE=$self->{NAME} in $filename: $name"; 
        return;
    }
    chomp $lockfile;
    if ($Babble or not $self) {
        print "signature = $signature";
        print "name = $name\n";
        if ($Babble) {
            print "values:\n";
            foreach (@values) { print "    $_"; }
        }
    }
    my $item;
    my @fields = @termios_fields;
    foreach $item (keys %c_cc_fields) {
        push @fields, "C_$item";
    }
    my %termios;
    foreach $item (@fields) {
        $termios{$item} = 1;
    }
    my $key;
    my $value;
    my $gosub;
    my $fault = 0;
    no strict 'refs';		# for $gosub
    foreach $item (@values) {
        chomp $item;
        ($key, $value) = split (/,/, $item);
        if ($value eq "") { $fault++ }
	elsif (defined $termios{$key}) {
	    $self->{"$key"} = $value;
	}
    else {
            $gosub = $validate{$key};
            unless (defined &$gosub ($self, $value)) {
    	        carp "Invalid parameter for $key=$value   "; 
    	        return;
            }
        }
    }
    use strict 'refs';
    if ($fault) {
        carp "Invalid value in $filename"; 
        undef $self;
        return;
    }
    1;
}

sub restart {
    return unless (@_ == 2);
    my $self = shift;
    my $filename = shift;
    get_start_values($self, $filename);
    write_settings($self);
}

sub start {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return unless (@_);
    my $filename = shift;

    unless ( open CF, "<$filename" ) {
        carp "can't open file: $filename: $!"; 
        return;
    }
    my ($signature, $name, $lockfile, @values) = <CF>;
    close CF;
    
    unless ( $cfg_file_sig eq $signature ) {
        carp "Invalid signature in $filename: $signature"; 
        return;
    }
    chomp $name;
    chomp $lockfile;
    my $self  = new ($class, $name, 1, $lockfile); # quiet for lock
    return 0 if ($lockfile and not $self);
    if ($Babble or not $self) {
        print "signature = $signature";
        print "class = $class\n";
        print "name = $name\n";
        print "lockfile = $lockfile\n";
        if ($Babble) {
            print "values:\n";
            foreach (@values) { print "    $_"; }
        }
    }
    if ($self) {
        if ( get_start_values($self, $filename) ) {
            write_settings ($self);
	}
        else {
            carp "Invalid value in $filename"; 
            undef $self;
            return;
        }
    }
    return $self;
}

# true/false capabilities (read only)
# currently just constants in the POSIX case

sub can_baud			{ return 1; }
sub can_databits		{ return 1; }
sub can_stopbits		{ return 1; }
sub can_dtrdsr			{ return 1; }
sub can_handshake		{ return 1; }
sub can_parity_check		{ return 1; }
sub can_parity_config		{ return 1; }
sub can_parity_enable		{ return 1; }
sub can_rlsd			{ return 0; } # currently
sub can_16bitmode		{ return 0; } # Win32-specific
sub is_rs232			{ return 1; }
sub is_modem			{ return 0; } # Win32-specific
sub can_rtscts			{ return 1; } # this is a flow option
sub can_xonxoff			{ return 1; } # this is a flow option
sub can_xon_char		{ return 1; } # use stty
sub can_spec_char		{ return 0; } # use stty
sub can_interval_timeout	{ return 0; } # currently
sub can_total_timeout		{ return 1; } # currently
sub binary			{ return 1; }
  
sub reset_error			{ return 0; } # for compatibility

sub can_ioctl {
    if (defined($bits->{'TIOCMBIS'}) &&         # Turn on
        defined($bits->{'TIOCMBIC'}) &&         # Turn off
        defined($bits->{'TIOCM_RTS'}) &&        # RTS value
        ( ( defined($bits->{'TIOCSDTR'}) &&     # DTR ability/value
            defined($bits->{'TIOCCDTR'}) ) ||
          defined($bits->{'TIOCM_DTR'})
        )
       ) {
        return 1;
    }
    return 0;

    #return 0 unless ($bitset && $bitclear && $rtsout && 
	#    (($dtrset && $dtrclear) || $dtrout));
    #return 1;
}

sub can_modemlines {
    return 1 if (defined($bits->{'TIOCMGET'}));
    return 0;
}

sub can_wait_modemlines {
    return 1 if (defined($bits->{'TIOCMIWAIT'}));
    return 0;
}

sub can_intr_count {
    return 1 if (defined($bits->{'TIOCGICOUNT'}));
    return 0;
}

sub can_status {
    return 1 if (defined($bits->{'portable_TIOCINQ'}) &&
                 defined($bits->{'TIOCOUTQ'}));
    return 0;
    #return 0 unless ($incount && $outcount);
    #return 1;
}

sub can_write_done {
    my ($self)=@_;
    return 1 if ($self->can_status &&
                 defined($bits->{'TIOCSERGETLSR'}) &&
                 TIOCM_LE);
    return 0;
}

# can we control the rts line?
sub can_rts {
    if (defined($bits->{'TIOCMBIS'}) &&
        defined($bits->{'TIOCMBIC'}) &&
        defined($bits->{'TIOCM_RTS'})) {
            return 1;
    }
    return 0;

    # why are we testing for _lack_ of dtrset/clear?  can BSD NOT control RTS?
    #return 0 unless($bitset && $bitclear && $rtsout && !($dtrset && $dtrclear));
    #return 1;
}

# can we set arbitrary baud rates? (OSX)
sub can_arbitrary_baud {
    return 1 if (defined($bits->{'IOSSIOSPEED'}));
    return 0;
}

sub termiox {
    my $self = shift;
    return unless ($IOCTL_VALUE_TERMIOXFLOW);
    my $on = shift;
    my $rc;

    $self->{'TERMIOX'}=$on ? $IOCTL_VALUE_TERMIOXFLOW : 0;

    my $flags=pack('SSSS',0,0,0,0);
    return undef unless $self->ioctl('TCGETX', \$flags);
    #if (!($rc=ioctl($self->{HANDLE}, $tcgetx, $flags))) {
	#warn "TCGETX($tcgetx) ioctl: $!\n";
    #}

    my @vals=unpack('SSSS',$flags);
    $vals[0]= $on ? $IOCTL_VALUE_TERMIOXFLOW : 0;
    $flags=pack('SSSS',@vals);

    return undef unless $self->ioctl('TCSETX', \$flags);
    #if (!($rc=ioctl($self->{HANDLE}, $tcsetx, $flags))) {
	#warn "TCSETX($tcsetx) ioctl: $!\n";
    #}
    return 1;
}
  
sub handshake {
    my $self = shift;
    
    if (@_) {
	if ( $_[0] eq "none" ) {
	    $self->{"C_IFLAG"} &= ~(IXON | IXOFF);
	    $self->termiox(0) if ($IOCTL_VALUE_TERMIOXFLOW);
	    $self->{"C_CFLAG"} &= ~CRTSCTS;
	}
	elsif ( $_[0] eq "xoff" ) {
	    $self->{"C_IFLAG"} |= (IXON | IXOFF);
	    $self->termiox(0) if ($IOCTL_VALUE_TERMIOXFLOW);
	    $self->{"C_CFLAG"} &= ~CRTSCTS;
	}
	elsif ( $_[0] eq "rts" ) {
	    $self->{"C_IFLAG"} &= ~(IXON | IXOFF);
	    $self->termiox(1) if ($IOCTL_VALUE_TERMIOXFLOW);
	    $self->{"C_CFLAG"} |= CRTSCTS;
	}
        else {
            if ($self->{U_MSG} or $Babble) {
                carp "Can't set handshake on $self->{ALIAS}";
            }
	    return undef;
        }
	write_settings($self);
    }
    if (wantarray) { return ("none", "xoff", "rts"); }
    my $mask = (IXON|IXOFF);
    return "xoff" if ($mask == ($self->{"C_IFLAG"} & $mask));
    if ($IOCTL_VALUE_TERMIOXFLOW) {
	return "rts" if ($self->{'TERMIOX'} & $IOCTL_VALUE_TERMIOXFLOW);
    } else {
    	return "rts" if ($self->{"C_CFLAG"} & CRTSCTS);
    }
    return "none";
}

sub baudrate {
    my ($self,$rate) = @_;
    my $item = 0;

    if (defined($rate)) {
        # specific baud rate
        if (defined $bauds{$rate}) {
            $self->{"C_OSPEED"} = $bauds{$rate};
            $self->{"C_ISPEED"} = $bauds{$rate};
            $self->{"IOSSIOSPEED_BAUD"} = -1;
            write_settings($self);
        }
        # arbitrary baud rate
        elsif ($self->can_arbitrary_baud()) {
            $self->{"IOSSIOSPEED_BAUD"} = $rate;
            write_settings($self);
            return $rate;
        }
        # no such baud rate
        else {
            if ($self->{U_MSG} or $Babble) {
                carp "Can't set baudrate ($rate) on $self->{ALIAS}";
            }
            return 0;
        }
    }
    if (wantarray) { return (keys %bauds); }
    foreach $item (keys %bauds) {
        return $item if ($bauds{$item} == $self->{"C_OSPEED"});
    }
    return 0;
}

# Interesting note about parity.  It seems that while the "correct" thing
# to do is to enable inbound parity checking (INPCK) and to strip the bits,
# this doesn't seem to be sane for a large number of systems, modems,
# whatever.  If "INPCK" or "ISTRIP" is needed, please use the stty_inpck
# and stty_istrip functions
sub parity {
    my $self = shift;
    if (@_) {
        if ( $_[0] eq "none" ) {
            $self->{"C_CFLAG"} &= ~(PARENB|PARODD);
        }
        elsif ( $_[0] eq "odd" ) {
            $self->{"C_CFLAG"} |= (PARENB|PARODD);
        }
        elsif ( $_[0] eq "even" ) {
	        $self->{"C_CFLAG"} |= PARENB;
            $self->{"C_CFLAG"} &= ~PARODD;
        }
        else {
            if ($self->{U_MSG} or $Babble) {
                carp "Can't set parity on $self->{ALIAS}";
            }
            return undef;
        }
        return undef if (!(write_settings($self)));
    }
    if (wantarray) { return ("none", "odd", "even"); }
    return "none" unless ($self->{"C_CFLAG"} & PARENB);
    my $mask = (PARENB|PARODD);
    return "odd"  if ($mask == ($self->{"C_CFLAG"} & $mask));
    $mask = (PARENB);
    return "even" if ($mask == ($self->{"C_CFLAG"} & $mask));
    return "unknown";
}

sub databits {
    my $self = shift;
    if (@_) {
	if ( $_[0] == 8 ) {
	    $self->{"C_CFLAG"} &= ~CSIZE;
	    $self->{"C_CFLAG"} |= CS8;
	}
	elsif ( $_[0] == 7 ) {
	    $self->{"C_CFLAG"} &= ~CSIZE;
	    $self->{"C_CFLAG"} |= CS7;
	}
	elsif ( $_[0] == 6 ) {
	    $self->{"C_CFLAG"} &= ~CSIZE;
	    $self->{"C_CFLAG"} |= CS6;
	}
	elsif ( $_[0] == 5 ) {
	    $self->{"C_CFLAG"} &= ~CSIZE;
	    $self->{"C_CFLAG"} |= CS5;
	}
        else {
            if ($self->{U_MSG} or $Babble) {
                carp "Can't set databits on $self->{ALIAS}";
            }
	    return undef;
        }
	write_settings($self);
    }
    if (wantarray) { return (5, 6, 7, 8); }
    my $mask = ($self->{"C_CFLAG"} & CSIZE);
    return 8 if ($mask == CS8);
    return 7 if ($mask == CS7);
    return 6 if ($mask == CS6);
    return 5;
}

sub stopbits {
    my $self = shift;
    if (@_) {
	if ( $_[0] == 2 ) {
	    $self->{"C_CFLAG"} |= CSTOPB;
	}
	elsif ( $_[0] == 1 ) {
	    $self->{"C_CFLAG"} &= ~CSTOPB;
	}
        else {
            if ($self->{U_MSG} or $Babble) {
                carp "Can't set stopbits on $self->{ALIAS}";
            }
	    return undef;
        }
	write_settings($self);
    }
    if (wantarray) { return (1, 2); }
    return 2 if ($self->{"C_CFLAG"} & CSTOPB);
    return 1;
}

sub is_xon_char {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VSTART"} = $v;
	write_settings($self);
    }
    return $self->{"C_VSTART"};
}

sub is_xoff_char {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VSTOP"} = $v;
	write_settings($self);
    }
    return $self->{"C_VSTOP"};
}

sub is_stty_intr {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VINTR"} = $v;
	write_settings($self);
    }
    return $self->{"C_VINTR"};
}

sub is_stty_quit {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VQUIT"} = $v;
	write_settings($self);
    }
    return $self->{"C_VQUIT"};
}

sub is_stty_eof {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VEOF"} = $v;
	write_settings($self);
    }
    return $self->{"C_VEOF"};
}

sub is_stty_eol {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VEOL"} = $v;
	write_settings($self);
    }
    return $self->{"C_VEOL"};
}

sub is_stty_erase {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VERASE"} = $v;
	write_settings($self);
    }
    return $self->{"C_VERASE"};
}

sub is_stty_kill {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VKILL"} = $v;
	write_settings($self);
    }
    return $self->{"C_VKILL"};
}

sub is_stty_susp {
    my $self = shift;
    if (@_) {
	my $v = int shift;
	return if (($v < 0) or ($v > 255));
	$self->{"C_VSUSP"} = $v;
	write_settings($self);
    }
    return $self->{"C_VSUSP"};
}

sub stty_echo {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHO;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHO;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHO) ? 1 : 0;
}

sub stty_echoe {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHOE;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHOE;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHOE) ? 1 : 0;
}

sub stty_echok {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHOK;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHOK;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHOK) ? 1 : 0;
}

sub stty_echonl {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHONL;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHONL;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHONL) ? 1 : 0;
}

	# non-POSIX
sub stty_echoke {
    my $self = shift;
    return unless ECHOKE;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHOKE;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHOKE;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHOKE) ? 1 : 0;
}

	# non-POSIX
sub stty_echoctl {
    my $self = shift;
    return unless ECHOCTL;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ECHOCTL;
        } else {
	    $self->{"C_LFLAG"} &= ~ECHOCTL;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ECHOCTL) ? 1 : 0;
}

# Mark parity errors with a leading "NULL" character
sub stty_parmrk {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_IFLAG"} |= PARMRK;
        } else {
            $self->{"C_IFLAG"} &= ~PARMRK;
        }
        write_settings($self);
    }
    return wantarray ? @binary_opt : ($self->{"C_IFLAG"} & PARMRK);
}

# Ignore parity errors (considered dangerous)
sub stty_ignpar {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_IFLAG"} |= IGNPAR;
        } else {
            $self->{"C_IFLAG"} &= ~IGNPAR;
	    }
        write_settings($self);
    }
    return wantarray ? @binary_opt : ($self->{"C_IFLAG"} & IGNPAR);
}

# Ignore breaks
sub stty_ignbrk {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_IFLAG"} |= IGNBRK;
        } else {
            $self->{"C_IFLAG"} &= ~IGNBRK;
        }
        write_settings($self);
    }
    return ($self->{"C_IFLAG"} & IGNBRK) ? 1 : 0;
}

# Strip parity bit
sub stty_istrip {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_IFLAG"} |= ISTRIP;
        } else {
            $self->{"C_IFLAG"} &= ~ISTRIP;
        }
        write_settings($self);
    }
    return ($self->{"C_IFLAG"} & ISTRIP) ? 1 : 0;
}

# check incoming parity bit
sub stty_inpck {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_IFLAG"} |= INPCK;
        } else {
            $self->{"C_IFLAG"} &= ~INPCK;
        }
        write_settings($self);
    }
    return ($self->{"C_IFLAG"} & INPCK) ? 1 : 0;
}

sub stty_icrnl {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_IFLAG"} |= ICRNL;
        } else {
	    $self->{"C_IFLAG"} &= ~ICRNL;
	}
	write_settings($self);
    }
    return ($self->{"C_IFLAG"} & ICRNL) ? 1 : 0;
}

sub stty_igncr {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_IFLAG"} |= IGNCR;
        } else {
	    $self->{"C_IFLAG"} &= ~IGNCR;
	}
	write_settings($self);
    }
    return ($self->{"C_IFLAG"} & IGNCR) ? 1 : 0;
}

sub stty_inlcr {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_IFLAG"} |= INLCR;
        } else {
	    $self->{"C_IFLAG"} &= ~INLCR;
	}
	write_settings($self);
    }
    return ($self->{"C_IFLAG"} & INLCR) ? 1 : 0;
}

	# non-POSIX
sub stty_ocrnl {
    my $self = shift;
    return unless OCRNL;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_OFLAG"} |= OCRNL;
        } else {
	    $self->{"C_OFLAG"} &= ~OCRNL;
	}
	write_settings($self);
    }
    return ($self->{"C_OFLAG"} & OCRNL) ? 1 : 0;
}

	# non-POSIX
sub stty_onlcr {
    my $self = shift;
    return unless ONLCR;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_OFLAG"} |= ONLCR;
        } else {
	    $self->{"C_OFLAG"} &= ~ONLCR;
	}
	write_settings($self);
    }
    return ($self->{"C_OFLAG"} & ONLCR) ? 1 : 0;
}

sub stty_opost {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_OFLAG"} |= OPOST;
        } else {
	    $self->{"C_OFLAG"} &= ~OPOST;
	}
	write_settings($self);
    }
    return ($self->{"C_OFLAG"} & OPOST) ? 1 : 0;
}

sub stty_isig {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ISIG;
        } else {
	    $self->{"C_LFLAG"} &= ~ISIG;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ISIG) ? 1 : 0;
}

sub stty_icanon {
    my $self = shift;
    if (@_) {
	if ( yes_true( shift ) ) {
	    $self->{"C_LFLAG"} |= ICANON;
        } else {
	    $self->{"C_LFLAG"} &= ~ICANON;
	}
	write_settings($self);
    }
    return ($self->{"C_LFLAG"} & ICANON) ? 1 : 0;
}

sub alias {
    my $self = shift;
    if (@_) { $self->{ALIAS} = shift; }	# should return true for legal names
    return $self->{ALIAS};
}

sub devicetype {
    my $self = shift;
    if (@_) { $self->{DVTYPE} = shift; } # return true for legal names
    return $self->{DVTYPE};
}

sub hostname {
    my $self = shift;
    if (@_) { $self->{HNAME} = shift; }	# return true for legal names
    return $self->{HNAME};
}

sub hostaddr {
    my $self = shift;
    if (@_) { $self->{HADDR} = shift; }	# return true for assigned port
    return $self->{HADDR};
}

sub datatype {
    my $self = shift;
    if (@_) { $self->{DATYPE} = shift; } # return true for legal types
    return $self->{DATYPE};
}

sub cfg_param_1 {
    my $self = shift;
    if (@_) { $self->{CFG_1} = shift; }	# return true for legal param
    return $self->{CFG_1};
}

sub cfg_param_2 {
    my $self = shift;
    if (@_) { $self->{CFG_2} = shift; }	# return true for legal param
    return $self->{CFG_2};
}

sub cfg_param_3 {
    my $self = shift;
    if (@_) { $self->{CFG_3} = shift; }	# return true for legal param
    return $self->{CFG_3};
}

sub buffers {
    my $self = shift;
    if (@_) { return unless (@_ == 2); }
    return wantarray ?  (4096, 4096) : 1;
}

sub read_const_time {
    my $self = shift;
    if (@_) {
	$self->{RCONST} = (shift)/1000; # milliseconds -> select_time
	$self->{"C_VTIME"} = $self->{RCONST} * 10000; # wants tenths of sec
	$self->{"C_VMIN"} = 0;
	write_settings($self);
    }
    return $self->{RCONST}*1000;
}

sub read_char_time {
    my $self = shift;
    if (@_) {
	$self->{RTOT} = (shift)/1000; # milliseconds -> select_time
    }
    return $self->{RTOT}*1000;
}

sub read {
    return undef unless (@_ == 2);
    my $self = shift;
    my $wanted = shift;
    my $result = "";
    my $ok     = 0;
    return (0, "") unless ($wanted > 0);

    my $done = 0;
    my $count_in = 0;
    my $string_in = "";
    my $in2 = "";
    my $bufsize = 255;	# VMIN max (declared as char)

    while ($done < $wanted) {
	my $size = $wanted - $done;
        if ($size > $bufsize) { $size = $bufsize; }
	($count_in, $string_in) = $self->read_vmin($size);
	if ($count_in) {
            $in2 .= $string_in;
	    $done += $count_in;
	}
	elsif ($done) {
	    last;
	}
        else {
            return if (!defined $count_in);
	    last;
        }
    }
    return ($done, $in2);
}

sub read_vmin {
    return undef unless (@_ == 2);
    my $self = shift;
    my $wanted = shift;
    my $result = "";
    my $ok     = 0;
    return (0, "") unless ($wanted > 0);

#	This appears dangerous under Solaris
#    if ($self->{"C_VMIN"} != $wanted) {
#	$self->{"C_VMIN"} = $wanted;
#        write_settings($self);
#    }
    my $rin = "";
    vec($rin, $self->{FD}, 1) = 1;
    my $ein = $rin;
    my $tin = $self->{RCONST} + ($wanted * $self->{RTOT});
    my $rout;
    my $wout;
    my $eout;
    my $tout;
    my $ready = select($rout=$rin, $wout=undef, $eout=$ein, $tout=$tin);

    my $got=0;

    if ($ready>0) {
        $got = POSIX::read ($self->{FD}, $result, $wanted);

        if (! defined $got) {
            return (0,"") if (&POSIX::EAGAIN == ($ok = POSIX::errno()));
            return (0,"") if (!$ready and (0 == $ok));
		    # at least Solaris acts like eof() in this case
            carp "Error #$ok in Device::SerialPort::read";
            return;
        }
        elsif ($got == 0 && $wanted!=0) {
            # if read returns "0" on a non-zero request, it's EOF
            return;
        }
    }

    print "read_vmin=$got, ready=$ready, result=..$result..\n" if ($Babble);
    return ($got, $result);
}

sub are_match {
    my $self = shift;
    my $pat;
    my $patno = 0;
    my $reno = 0;
    my $re_next = 0;
    if (@_) {
	@{ $self->{"_MATCH"} } = @_;
	if ($] >= 5.005) {
	    @{ $self->{"_CMATCH"} } = ();
	    while ($pat = shift) {
	        if ($re_next) {
		    $re_next = 0;
	            eval 'push (@{ $self->{"_CMATCH"} }, qr/$pat/)';
		} else {
	            push (@{ $self->{"_CMATCH"} }, $pat);
		}
	        if ($pat eq "-re") {
		    $re_next++;
	        }
	    }
	} else {
	    @{ $self->{"_CMATCH"} } = @_;
	}
    }
    return @{ $self->{"_MATCH"} };
}

sub lookclear {
    my $self = shift;
    if (nocarp && (@_ == 1)) {
        $self->{"_T_INPUT"} = shift;
    } 
    $self->{"_LOOK"}	 = "";
    $self->{"_LASTLOOK"} = "";
    $self->{"_LMATCH"}	 = "";
    $self->{"_LPATT"}	 = "";
    return if (@_);
    1;
}

sub linesize {
    my $self = shift;
    if (@_) {
	my $val = int shift;
	return if ($val < 0);
        $self->{"_SIZE"} = $val;
    }
    return $self->{"_SIZE"};
}

sub lastline {
    my $self = shift;
    if (@_) {
        $self->{"_LASTLINE"} = shift;
	if ($] >= 5.005) {
	    eval '$self->{"_CLASTLINE"} = qr/$self->{"_LASTLINE"}/';
	} else {
            $self->{"_CLASTLINE"} = $self->{"_LASTLINE"};
	}
    }
    return $self->{"_LASTLINE"};
}

sub matchclear {
    my $self = shift;
    my $found = $self->{"_LMATCH"};
    $self->{"_LMATCH"}	 = "";
    return if (@_);
    return $found;
}

sub lastlook {
    my $self = shift;
    return if (@_);
    return ( $self->{"_LMATCH"}, $self->{"_LASTLOOK"},
	     $self->{"_LPATT"}, $self->{"_LOOK"} );
}

sub lookfor {
    my $self = shift;
    my $size = 0;
    if (@_) { $size = shift; }
    my $loc = "";
    my $count_in = 0;
    my $string_in = "";
    $self->{"_LMATCH"}	 = "";
    $self->{"_LPATT"}	 = "";

    if ( ! $self->{"_LOOK"} ) {
        $loc = $self->{"_LASTLOOK"};
    }

    if ($size) {
	($count_in, $string_in) = $self->read($size);
	return unless ($count_in);
        $loc .= $string_in;
    }
    else {
	$loc .= $self->input;
    }

    if ($loc ne "") {
	my $n_char;
	my $mpos;
	my $lookbuf;
	my $re_next = 0;
	my $got_match = 0;
	my $pat;
	
	my @loc_char = split (//, $loc);
	while (defined ($n_char = shift @loc_char)) {
		$mpos = ord $n_char;
        $self->{"_LOOK"} .= $n_char;
		$lookbuf = $self->{"_LOOK"};
		$count_in = 0;
		foreach $pat ( @{ $self->{"_CMATCH"} } ) {
		    if ($pat eq "-re") {
			$re_next++;
		        $count_in++;
			next;
		    }
		    if ($re_next) {
			$re_next = 0;
			# always at $lookbuf end when processing single char
		        if ( $lookbuf =~ s/$pat//s ) {
		            $self->{"_LMATCH"} = $&;
                    $got_match++;
                }
		    }
		    elsif (($mpos = index($lookbuf, $pat)) > -1) {
			$got_match++;
			$lookbuf = substr ($lookbuf, 0, $mpos);
		        $self->{"_LMATCH"} = $pat;
		    }
		    if ($got_match) {
		        $self->{"_LPATT"} = $self->{"_MATCH"}[$count_in];
		        if (scalar @loc_char) {
		            $self->{"_LASTLOOK"} = join("", @loc_char);
                }
		        else {
		            $self->{"_LASTLOOK"} = "";
		        }
		        $self->{"_LOOK"}     = "";
		        return $lookbuf;
                    }
		    $count_in++;
		}
####	    }
	}
    }
    return "";
}

sub streamline {
    my $self = shift;
    my $size = 0;
    if (@_) { $size = shift; }
    my $loc = "";
    my $mpos;
    my $count_in = 0;
    my $string_in = "";
    my $re_next = 0;
    my $got_match = 0;
    my $best_pos = 0;
    my $pat;
    my $match = "";
    my $before = "";
    my $after = "";
    my $best_match = "";
    my $best_before = "";
    my $best_after = "";
    my $best_pat = "";
    $self->{"_LMATCH"}	 = "";
    $self->{"_LPATT"}	 = "";

    if ( ! $self->{"_LOOK"} ) {
        $loc = $self->{"_LASTLOOK"};
    }

    if ($size) {
        ($count_in, $string_in) = $self->read($size);
        return unless ($count_in);
        $loc .= $string_in;
    }
    else {
        $loc .= $self->input;
    }

    if ($loc ne "") {
        $self->{"_LOOK"} .= $loc;
        $count_in = 0;
        foreach $pat ( @{ $self->{"_CMATCH"} } ) {
            if ($pat eq "-re") {
                $re_next++;
                $count_in++;
                next;
            }
            if ($re_next) {
                $re_next = 0;
                if ( $self->{"_LOOK"} =~ /$pat/s ) {
                    ( $match, $before, $after ) = ( $&, $`, $' );
                    $got_match++;
                    $mpos = length($before);
                    if ($mpos) {
                        next if ($best_pos && ($mpos > $best_pos));
                        $best_pos = $mpos;
                        $best_pat = $self->{"_MATCH"}[$count_in];
                        $best_match = $match;
                        $best_before = $before;
                        $best_after = $after;
                    }
                    else {
                        $self->{"_LPATT"} = $self->{"_MATCH"}[$count_in];
                        $self->{"_LMATCH"} = $match;
                        $self->{"_LASTLOOK"} = $after;
                        $self->{"_LOOK"}     = "";
                        return $before;
                        # pattern at start will be best
                    }
                }
            }
            elsif (($mpos = index($self->{"_LOOK"}, $pat)) > -1) {
                $got_match++;
                $before = substr ($self->{"_LOOK"}, 0, $mpos);
                if ($mpos) {
                    next if ($best_pos && ($mpos > $best_pos));
                    $best_pos = $mpos;
                    $best_pat = $pat;
                    $best_match = $pat;
                    $best_before = $before;
                    $mpos += length($pat);
                    $best_after = substr ($self->{"_LOOK"}, $mpos);
                }
                else {
                    $self->{"_LPATT"} = $pat;
                    $self->{"_LMATCH"} = $pat;
                    $before = substr ($self->{"_LOOK"}, 0, $mpos);
                    $mpos += length($pat);
                    $self->{"_LASTLOOK"} = substr ($self->{"_LOOK"}, $mpos);
                    $self->{"_LOOK"}     = "";
                    return $before;
                    # match at start will be best
                }
            }
            $count_in++;
        }
        if ($got_match) {
            $self->{"_LPATT"} = $best_pat;
            $self->{"_LMATCH"} = $best_match;
            $self->{"_LASTLOOK"} = $best_after;
            $self->{"_LOOK"}     = "";
            return $best_before;
        }
    }
    return "";
}

sub input {
    return undef unless (@_ == 1);
    my $self = shift;
    my $ok     = 0;
    my $result = "";
    my $wanted = 255;

    if (nocarp && $self->{"_T_INPUT"}) {
        $result = $self->{"_T_INPUT"};
        $self->{"_T_INPUT"} = "";
        return $result;
    }

    if ( $self->{"C_VMIN"} ) {
        $self->{"C_VMIN"} = 0;
        write_settings($self);
    }

    my $got = POSIX::read ($self->{FD}, $result, $wanted);

    unless (defined $got) { $got = -1; }
    if ($got == -1) {
        return "" if (&POSIX::EAGAIN == ($ok = POSIX::errno()));
        return "" if (0 == $ok);	# at least Solaris acts like eof()
        carp "Error #$ok in Device::SerialPort::input"
    }
    return $result;
}

sub write {
    return undef unless (@_ == 2);
    my $self = shift;
    my $wbuf = shift;
    my $ok;

    return 0 if ($wbuf eq "");
    my $lbuf = length ($wbuf);

    my $written = POSIX::write ($self->{FD}, $wbuf, $lbuf);

    return $written;
}

sub write_drain {
    my $self = shift;
    return if (@_);
    return 1 if (defined POSIX::tcdrain($self->{FD}));
    return;
}

sub purge_all {
    my $self = shift;
    return if (@_);
    return 1 if (defined POSIX::tcflush($self->{FD}, TCIOFLUSH));
    return;
}

sub purge_rx {
    my $self = shift;
    return if (@_);
    return 1 if (defined POSIX::tcflush($self->{FD}, TCIFLUSH));
    return;
}

sub purge_tx {
    my $self = shift;
    return if (@_);
    return 1 if (defined POSIX::tcflush($self->{FD}, TCOFLUSH));
    return;
}

sub buffer_max {
    my $self = shift;
    if (@_) {return undef; }
    return (4096, 4096);
}

  # true/false parameters

sub user_msg {
    my $self = shift;
    if (@_) { $self->{U_MSG} = yes_true ( shift ) }
    return wantarray ? @binary_opt : $self->{U_MSG};
}

sub error_msg {
    my $self = shift;
    if (@_) { $self->{E_MSG} = yes_true ( shift ) }
    return wantarray ? @binary_opt : $self->{E_MSG};
}

sub parity_enable {
    my $self = shift;
    if (@_) {
        if ( yes_true( shift ) ) {
            $self->{"C_CFLAG"} |= PARENB;
        } else {
            $self->{"C_CFLAG"} &= ~PARENB;
        }
        write_settings($self);
    }
    return wantarray ? @binary_opt : ($self->{"C_CFLAG"} & PARENB);
}

sub write_done {
    return unless (@_ == 2);
    my $self = shift;
    return unless ($self->can_write_done);
    my $rc;
    my $wait = yes_true ( shift );
    $self->write_drain if ($wait);

    my $mstat = " ";
    my $result;
    for (;;) {
        return unless $self->ioctl('TIOCOUTQ',\$mstat);
        $result = unpack('L', $mstat);
        return (0, 0) if ($result);	# characters pending

        return unless $self->ioctl('TIOCSERGETLSR',\$mstat);
        $result = (unpack('L', $mstat) & TIOCM_LE);
        last unless ($wait);
        last if ($result);		# shift register empty
        select (undef, undef, undef, 0.02);
    }
    return $result ? (1, 0) : (0, 0);
}

sub modemlines {
    return undef unless (@_ == 1);
    my $self = shift;
    return undef unless ($self->can_modemlines);

    my $mstat = pack('L',0);
    return undef unless $self->ioctl('TIOCMGET',\$mstat);
    my $result = unpack('L', $mstat);
    if ($Babble) {
        printf "result = %x\n", $result;
        print "CTS is ON\n"		if ($result & MS_CTS_ON);
        print "DSR is ON\n"		if ($result & MS_DSR_ON);
        print "RING is ON\n"		if ($result & MS_RING_ON);
        print "RLSD is ON\n"		if ($result & MS_RLSD_ON);
    }
    return $result;
}

# Strange thing is, this function doesn't always work for me.  I suspect
# I have a broken serial card.  Everything else in my test system doesn't
# work (USB, floppy) so why not serial too?
sub wait_modemlines {
    return undef unless (@_ == 2);
    my $self = shift;
    my $flags = shift || 0;
    return undef unless ($self->can_wait_modemlines);

    if ($Babble) {
        printf "wait_modemlines flag = %u\n", $flags;
    }
    my $mstat = pack('L',$flags);
    return $self->ioctl('TIOCMIWAIT',\$mstat);
}

sub intr_count {
    return undef unless (@_ == 1);
    my $self = shift;
    return undef unless ($self->can_intr_count);

    my $mstat = pack('L',0);
    return $self->ioctl('TIOCGICOUNT',\$mstat);
    my $result = unpack('L', $mstat);
    if ($Babble) {
        printf "result = %x\n", $result;
    }
    return $result;
}

sub status {
    my $self = shift;
    return if (@_);
    return unless ($self->can_status);
    my @stat = (0, 0, 0, 0);
    my $mstat = " ";

    return unless $self->ioctl('portable_TIOCINQ', \$mstat);

    $stat[ST_INPUT] = unpack('L', $mstat);
    return unless $self->ioctl('TIOCOUTQ', \$mstat);

    $stat[ST_OUTPUT] = unpack('L', $mstat);

    if ( $Babble or $self->{"_DEBUG"} ) {
        printf "Blocking Bits= %d\n", $stat[ST_BLOCK];
        printf "Input Queue= %d\n", $stat[ST_INPUT];
        printf "Output Queue= %d\n", $stat[ST_OUTPUT];
        printf "Latched Errors= %d\n", $stat[ST_ERROR];
    }
    return @stat;
}

sub dtr_active {
    return unless (@_ == 2);
    my $self = shift;
    return unless $self->can_dtrdsr();
    my $on = yes_true( shift );
    my $rc;

    # if we have set DTR and clear DTR, we should use it (OpenBSD)
    my $value=0;
    if (defined($bits->{'TIOCSDTR'}) &&
        defined($bits->{'TIOCCDTR'})) {
        $value=0;
        $rc=$self->ioctl($on ? 'TIOCSDTR' : 'TIOCCDTR', \$value);
    }
    else {
        $value=$IOCTL_VALUE_DTR;
        $rc=$self->ioctl($on ? 'TIOCMBIS' : 'TIOCMBIC', \$value);
    }
    warn "dtr_active($on) ioctl: $!\n"    if (!$rc);

    # ARG!  Solaris destroys termios settings after a DTR toggle!!
    write_settings($self);

    return $rc;
}

sub rts_active {
    return unless (@_ == 2);
    my $self = shift;
    return unless ($self->can_rts());
    my $on = yes_true( shift );
    # returns ioctl result
    my $value=$IOCTL_VALUE_RTS;
    my $rc=$self->ioctl($on ? 'TIOCMBIS' : 'TIOCMBIC', \$value);
    #my $rc=ioctl($self->{HANDLE}, $on ? $bitset : $bitclear, $rtsout);
    warn "rts_active($on) ioctl: $!\n" if (!$rc);
    return $rc; 
}

sub pulse_break_on {
    return unless (@_ == 2);
    my $self = shift;
    my $delay = (shift)/1000;
    my $length = 0;
    my $ok = POSIX::tcsendbreak($self->{FD}, $length);
    warn "could not pulse break on: $!\n" unless ($ok);
    select (undef, undef, undef, $delay);
    return $ok;
}

sub pulse_rts_on {
    return unless (@_ == 2);
    my $self = shift;
    return unless ($self->can_rts());
    my $delay = (shift)/1000;
    $self->rts_active(1) or warn "could not pulse rts on\n";
    select (undef, undef, undef, $delay);
    $self->rts_active(0) or warn "could not restore from rts on\n";
    select (undef, undef, undef, $delay);
    1;
}

sub pulse_dtr_on {
    return unless (@_ == 2);
    my $self = shift;
    return unless $self->can_ioctl();
    my $delay = (shift)/1000;
    $self->dtr_active(1) or warn "could not pulse dtr on\n";
    select (undef, undef, undef, $delay);
    $self->dtr_active(0) or warn "could not restore from dtr on\n";
    select (undef, undef, undef, $delay);
    1;
}

sub pulse_rts_off {
    return unless (@_ == 2);
    my $self = shift;
    return unless ($self->can_rts());
    my $delay = (shift)/1000;
    $self->rts_active(0) or warn "could not pulse rts off\n";
    select (undef, undef, undef, $delay);
    $self->rts_active(1) or warn "could not restore from rts off\n";
    select (undef, undef, undef, $delay);
    1;
}

sub pulse_dtr_off {
    return unless (@_ == 2);
    my $self = shift;
    return unless $self->can_ioctl();
    my $delay = (shift)/1000;
    $self->dtr_active(0) or warn "could not pulse dtr off\n";
    select (undef, undef, undef, $delay);
    $self->dtr_active(1) or warn "could not restore from dtr off\n";
    select (undef, undef, undef, $delay);
    1;
}

sub debug {
    my $self = shift;
    if (ref($self))  {
        if (@_) { $self->{"_DEBUG"} = yes_true ( shift ); }
        if (wantarray) { return @binary_opt; }
        else {
	    my $tmp = $self->{"_DEBUG"};
            nocarp || carp "Debug level: $self->{ALIAS} = $tmp";
            return $self->{"_DEBUG"};
        }
    } else {
        if (@_) { $Babble = yes_true ( shift ); }
        if (wantarray) { return @binary_opt; }
        else {
            nocarp || carp "Debug Class = $Babble";
            return $Babble;
        }
    }
}

sub close {
    my $self = shift;
    my $ok = undef;
    my $item;

    return unless (defined $self->{NAME});

    if ($Babble) {
        carp "Closing $self " . $self->{ALIAS};
    }
    if ($self->{FD}) {
        purge_all ($self);

        # Gracefully handle shutdown without termios
        if (defined($self->{TERMIOS})) {
            # copy the original values into "current" values
            foreach $item (keys %c_cc_fields) {
        	    $self->{"C_$item"} = $self->{"_$item"};
    	    }

        	$self->{"C_CFLAG"} = $self->{"_CFLAG"};
        	$self->{"C_IFLAG"} = $self->{"_IFLAG"};
        	$self->{"C_ISPEED"} = $self->{"_ISPEED"};
        	$self->{"C_LFLAG"} = $self->{"_LFLAG"};
        	$self->{"C_OFLAG"} = $self->{"_OFLAG"};
        	$self->{"C_OSPEED"} = $self->{"_OSPEED"};
	
        	write_settings($self);
        }

        $ok = POSIX::close($self->{FD});

    	# we need to explicitly close this handle
    	$self->{HANDLE}->close if (defined($self->{HANDLE}) &&
                                   $self->{HANDLE}->opened);

    	$self->{FD} = undef;
    	$self->{HANDLE} = undef;
    }
    if ($self->{LOCK}) {
    	unless ( unlink $self->{LOCK} ) {
            nocarp or carp "can't remove lockfile: $self->{LOCK}\n"; 
    	}
        $self->{LOCK} = "";
    }
    $self->{NAME} = undef;
    $self->{ALIAS} = undef;
    return unless ($ok);
    1;
}

sub ioctl
{
    my ($self,$code,$ref) = @_;
    return undef unless (defined $self->{NAME});


    if ($Babble) {
        my $num = $$ref;
        $num = unpack('L', $num);
        carp "ioctl $code($bits->{$code}) $ref: $num";
    }

    my $magic;
    if (!defined($magic = $bits->{$code})) {
        carp "cannot ioctl '$code': no system value found\n";
        return undef;
    }

    if (!ioctl($self->{HANDLE},$magic,$$ref)) {
        carp "$code($magic) ioctl failed: $!";
        return undef;
    }

    return 1;
}

##### tied FileHandle support
 
# DESTROY this
#      As with the other types of ties, this method will be called when the
#      tied handle is about to be destroyed. This is useful for debugging and
#      possibly cleaning up.

sub DESTROY {
    my $self = shift;
    return unless (defined $self->{NAME});
    if ($self->{"_DEBUG"}) {
        carp "Destroying $self->{NAME}";
    }
    $self->close;
}
 
sub TIEHANDLE {
    my $proto = shift;
    my $class = ref($proto) || $proto;

    return unless (@_);

#    my $self = start($class, shift);
    return new($class, @_);
}
 
# WRITE this, LIST
#      This method will be called when the handle is written to via the
#      syswrite function.

sub WRITE {
    return if (@_ < 3);
    my $self = shift;
    my $buf = shift;
    my $len = shift;
    my $offset = 0;
    if (@_) { $offset = shift; }
    my $out2 = substr($buf, $offset, $len);
    return unless ($self->post_print($out2));
    return length($out2);
}

# PRINT this, LIST
#      This method will be triggered every time the tied handle is printed to
#      with the print() function. Beyond its self reference it also expects
#      the list that was passed to the print function.
 
sub PRINT {
    my $self = shift;
    return unless (@_);
    my $ofs = $, ? $, : "";
    if ($self->{OFS}) { $ofs = $self->{OFS}; }
    my $ors = $\ ? $\ : "";
    if ($self->{ORS}) { $ors = $self->{ORS}; }
    my $output = join($ofs,@_);
    $output .= $ors;
    return $self->post_print($output);
}

sub output_field_separator {
    my $self = shift;
    my $prev = $self->{OFS};
    if (@_) { $self->{OFS} = shift; }
    return $prev;
}

sub output_record_separator {
    my $self = shift;
    my $prev = $self->{ORS};
    if (@_) { $self->{ORS} = shift; }
    return $prev;
}

sub post_print {
    my $self = shift;
    return unless (@_);
    my $output = shift;
    my $to_do = length($output);
    my $done = 0;
    my $written = 0;
    while ($done < $to_do) {
        my $out2 = substr($output, $done);
        $written = $self->write($out2);
	if (! defined $written) {
            return;
        }
	return 0 unless ($written);
	$done += $written;
    }
    1;
}
 
# PRINTF this, LIST
#      This method will be triggered every time the tied handle is printed to
#      with the printf() function. Beyond its self reference it also expects
#      the format and list that was passed to the printf function.
 
sub PRINTF {
    my $self = shift;
    my $fmt = shift;
    return unless ($fmt);
    return unless (@_);
    my $output = sprintf($fmt, @_);
    $self->PRINT($output);
}
 
# READ this, LIST
#      This method will be called when the handle is read from via the read
#      or sysread functions.

sub READ {
    return if (@_ < 3);
    my $buf = \$_[1];
    my ($self, $junk, $size, $offset) = @_;
    unless (defined $offset) { $offset = 0; }
    my $count_in = 0;
    my $string_in = "";

    ($count_in, $string_in) = $self->read($size);

    $$buf = '' unless defined $$buf;
    my $buflen = length $$buf;

    my ($tail, $head) = ('','');

    if($offset >= 0){ # positive offset
       if($buflen > $offset + $count_in){
           $tail = substr($$buf, $offset + $count_in);
       }

       if($buflen < $offset){
           $head = $$buf . ("\0" x ($offset - $buflen));
       } else {
           $head = substr($$buf, 0, $offset);
       }
    } else { # negative offset
       $head = substr($$buf, 0, ($buflen + $offset));

       if(-$offset > $count_in){
           $tail = substr($$buf, $offset + $count_in);
       }
    }

    # remaining unhandled case: $offset < 0 && -$offset > $buflen
    $$buf = $head.$string_in.$tail;
    return $count_in;
}

# READLINE this
#      This method will be called when the handle is read from via <HANDLE>.
#      The method should return undef when there is no more data.
 
sub READLINE {
    my $self = shift;
    return if (@_);
    my $count_in = 0;
    my $string_in = "";
    my $match = "";
    my $was;

    if (wantarray) {
	my @lines;
        for (;;) {
            last if ($was = $self->reset_error);	# dummy, currently
	    if ($self->stty_icanon) {
	        ($count_in, $string_in) = $self->read_vmin(255);
                last if (! defined $count_in);
	    }
	    else {
                $string_in = $self->streamline($self->{"_SIZE"});
                last if (! defined $string_in);
	        $match = $self->matchclear;
                if ( ($string_in ne "") || ($match ne "") ) {
		    $string_in .= $match;
                }
	    }
            push (@lines, $string_in);
	    last if ($string_in =~ /$self->{"_CLASTLINE"}/s);
        }
	return @lines if (@lines);
        return;
    }
    else {
	my $last_icanon = $self->stty_icanon;
        $self->stty_icanon(1);
        for (;;) {
            last if ($was = $self->reset_error);	# dummy, currently
            $string_in = $self->lookfor($self->{"_SIZE"});
            last if (! defined $string_in);
	    $match = $self->matchclear;
            if ( ($string_in ne "") || ($match ne "") ) {
		$string_in .= $match; # traditional <HANDLE> behavior
	        $self->stty_icanon(0);
	        return $string_in;
	    }
        }
	$self->stty_icanon($last_icanon);
        return;
    }
}
 
# GETC this
#      This method will be called when the getc function is called.
 
sub GETC {
    my $self = shift;
    my ($count, $in) = $self->read(1);
    if ($count == 1) {
        return $in;
    }
    return;
}
 
# CLOSE this
#      This method will be called when the handle is closed via the close
#      function.
 
sub CLOSE {
    my $self = shift;
    $self->write_drain;
    my $success = $self->close;
    if ($Babble) { printf "CLOSE result:%d\n", $success; }
    return $success;
}

# FILENO this
#	This method will be called if we ever need the FD from the handle

sub FILENO {
    my $self = shift;
    return $self->{FD};
}
 
1;  # so the require or use succeeds

__END__

=pod

=head1 NAME

Device::SerialPort - Linux/POSIX emulation of Win32::SerialPort functions.

=head1 SYNOPSIS

  use Device::SerialPort qw( :PARAM :STAT 0.07 );

=head2 Constructors

  # $lockfile is optional
  $PortObj = new Device::SerialPort ($PortName, $quiet, $lockfile)
       || die "Can't open $PortName: $!\n";

  $PortObj = start Device::SerialPort ($Configuration_File_Name)
       || die "Can't start $Configuration_File_Name: $!\n";

  $PortObj = tie (*FH, 'Device::SerialPort', $Configuration_File_Name)
       || die "Can't tie using $Configuration_File_Name: $!\n";

=head2 Configuration Utility Methods

  $PortObj->alias("MODEM1");

  $PortObj->save($Configuration_File_Name)
       || warn "Can't save $Configuration_File_Name: $!\n";

  # currently optional after new, POSIX version expected to succeed
  $PortObj->write_settings;

  # rereads file to either return open port to a known state
  # or switch to a different configuration on the same port
  $PortObj->restart($Configuration_File_Name)
       || warn "Can't reread $Configuration_File_Name: $!\n";

  # "app. variables" saved in $Configuration_File, not used internally
  $PortObj->devicetype('none');     # CM11, CM17, 'weeder', 'modem'
  $PortObj->hostname('localhost');  # for socket-based implementations
  $PortObj->hostaddr(0);            # false unless specified
  $PortObj->datatype('raw');        # in case an application needs_to_know
  $PortObj->cfg_param_1('none');    # null string '' hard to save/restore
  $PortObj->cfg_param_2('none');    # 3 spares should be enough for now
  $PortObj->cfg_param_3('none');    # one may end up as a log file path

  # test suite use only
  @necessary_param = Device::SerialPort->set_test_mode_active(1);

  # exported by :PARAM
  nocarp || carp "Something fishy";
  $a = SHORTsize;			# 0xffff
  $a = LONGsize;			# 0xffffffff
  $answer = yes_true("choice");		# 1 or 0
  OS_Error unless ($API_Call_OK);	# prints error

=head2 Configuration Parameter Methods

  # most methods can be called two ways:
  $PortObj->handshake("xoff");           # set parameter
  $flowcontrol = $PortObj->handshake;    # current value (scalar)

  # The only "list context" method calls from Win32::SerialPort
  # currently supported are those for baudrate, parity, databits,
  # stopbits, and handshake (which only accept specific input values).
  @handshake_opts = $PortObj->handshake; # permitted choices (list)

  # similar
  $PortObj->baudrate(9600);
  $PortObj->parity("odd");
  $PortObj->databits(8);
  $PortObj->stopbits(1);	# POSIX does not support 1.5 stopbits

  # these are essentially dummies in POSIX implementation
  # the calls exist to support compatibility
  $PortObj->buffers(4096, 4096);	# returns (4096, 4096)
  @max_values = $PortObj->buffer_max;	# returns (4096, 4096)
  $PortObj->reset_error;		# returns 0

  # true/false parameters (return scalar context only)
  # parameters exist, but message processing not yet fully implemented
  $PortObj->user_msg(ON);	# built-in instead of warn/die above
  $PortObj->error_msg(ON);	# translate error bitmasks and carp

  $PortObj->parity_enable(F);	# faults during input
  $PortObj->debug(0);

  # true/false capabilities (read only)
  # most are just constants in the POSIX case
  $PortObj->can_baud;			# 1
  $PortObj->can_databits;		# 1
  $PortObj->can_stopbits;		# 1
  $PortObj->can_dtrdsr;			# 1
  $PortObj->can_handshake;		# 1
  $PortObj->can_parity_check;		# 1
  $PortObj->can_parity_config;		# 1
  $PortObj->can_parity_enable;		# 1
  $PortObj->can_rlsd;    		# 0 currently
  $PortObj->can_16bitmode;		# 0 Win32-specific
  $PortObj->is_rs232;			# 1
  $PortObj->is_modem;			# 0 Win32-specific
  $PortObj->can_rtscts;			# 1
  $PortObj->can_xonxoff;		# 1
  $PortObj->can_xon_char;		# 1 use stty
  $PortObj->can_spec_char;		# 0 use stty
  $PortObj->can_interval_timeout;	# 0 currently
  $PortObj->can_total_timeout;		# 1 currently
  $PortObj->can_ioctl;			# automatically detected
  $PortObj->can_status;			# automatically detected
  $PortObj->can_write_done;		# automatically detected
  $PortObj->can_modemlines;     # automatically detected
  $PortObj->can_wait_modemlines;# automatically detected
  $PortObj->can_intr_count;		# automatically detected
  $PortObj->can_arbitrary_baud; # automatically detected

=head2 Operating Methods

  ($count_in, $string_in) = $PortObj->read($InBytes);
  warn "read unsuccessful\n" unless ($count_in == $InBytes);

  $count_out = $PortObj->write($output_string);
  warn "write failed\n"		unless ($count_out);
  warn "write incomplete\n"	if ( $count_out != length($output_string) );

  if ($string_in = $PortObj->input) { PortObj->write($string_in); }
     # simple echo with no control character processing

  if ($PortObj->can_wait_modemlines) {
    $rc = $PortObj->wait_modemlines( MS_RLSD_ON );
    if (!$rc) { print "carrier detect changed\n"; }
  }

  if ($PortObj->can_modemlines) {
    $ModemStatus = $PortObj->modemlines;
    if ($ModemStatus & $PortObj->MS_RLSD_ON) { print "carrier detected\n"; }
  }

  if ($PortObj->can_intr_count) {
    $count = $PortObj->intr_count();
    print "got $count interrupts\n";
  }

  if ($PortObj->can_arbitrary_baud) {
    print "this port can set arbitrary baud rates\n";
  }

  ($BlockingFlags, $InBytes, $OutBytes, $ErrorFlags) = $PortObj->status;
      # same format for compatibility. Only $InBytes and $OutBytes are
      # currently returned (on linux). Others are 0.
      # Check return value of "can_status" to see if this call is valid.

  ($done, $count_out) = $PortObj->write_done(0);
     # POSIX defaults to background write. Currently $count_out always 0.
     # $done set when hardware finished transmitting and shared line can
     # be released for other use. Ioctl may not work on all OSs.
     # Check return value of "can_write_done" to see if this call is valid.

  $PortObj->write_drain;  # POSIX alternative to Win32 write_done(1)
                          # set when software is finished transmitting
  $PortObj->purge_all;
  $PortObj->purge_rx;
  $PortObj->purge_tx;

      # controlling outputs from the port
  $PortObj->dtr_active(T);		# sends outputs direct to hardware
  $PortObj->rts_active(Yes);		# return status of ioctl call
					# return undef on failure

  $PortObj->pulse_break_on($milliseconds); # off version is implausible
  $PortObj->pulse_rts_on($milliseconds);
  $PortObj->pulse_rts_off($milliseconds);
  $PortObj->pulse_dtr_on($milliseconds);
  $PortObj->pulse_dtr_off($milliseconds);
      # sets_bit, delays, resets_bit, delays
      # returns undef if unsuccessful or ioctls not implemented

  $PortObj->read_const_time(100);	# const time for read (milliseconds)
  $PortObj->read_char_time(5);		# avg time between read char

  $milliseconds = $PortObj->get_tick_count;

=head2 Methods used with Tied FileHandles

  $PortObj = tie (*FH, 'Device::SerialPort', $Configuration_File_Name)
       || die "Can't tie: $!\n";             ## TIEHANDLE ##

  print FH "text";                           ## PRINT     ##
  $char = getc FH;                           ## GETC      ##
  syswrite FH, $out, length($out), 0;        ## WRITE     ##
  $line = <FH>;                              ## READLINE  ##
  @lines = <FH>;                             ## READLINE  ##
  printf FH "received: %s", $line;           ## PRINTF    ##
  read (FH, $in, 5, 0) or die "$!";          ## READ      ##
  sysread (FH, $in, 5, 0) or die "$!";       ## READ      ##
  close FH || warn "close failed";           ## CLOSE     ##
  undef $PortObj;
  untie *FH;                                 ## DESTROY   ##

  $PortObj->linesize(10);		     # with READLINE
  $PortObj->lastline("_GOT_ME_");	     # with READLINE, list only

      ## with PRINT and PRINTF, return previous value of separator
  $old_ors = $PortObj->output_record_separator("RECORD");
  $old_ofs = $PortObj->output_field_separator("COMMA");

=head2 Destructors

  $PortObj->close || warn "close failed";
      # release port to OS - needed to reopen
      # close will not usually DESTROY the object
      # also called as: close FH || warn "close failed";

  undef $PortObj;
      # preferred unless reopen expected since it triggers DESTROY
      # calls $PortObj->close but does not confirm success
      # MUST precede untie - do all three IN THIS SEQUENCE before re-tie.

  untie *FH;

=head2 Methods for I/O Processing

  $PortObj->are_match("text", "\n");	# possible end strings
  $PortObj->lookclear;			# empty buffers
  $PortObj->write("Feed Me:");		# initial prompt
  $PortObj->is_prompt("More Food:");	# not implemented

  my $gotit = "";
  until ("" ne $gotit) {
      $gotit = $PortObj->lookfor;	# poll until data ready
      die "Aborted without match\n" unless (defined $gotit);
      sleep 1;				# polling sample time
  }

  printf "gotit = %s\n", $gotit;		# input BEFORE the match
  my ($match, $after, $pattern, $instead) = $PortObj->lastlook;
      # input that MATCHED, input AFTER the match, PATTERN that matched
      # input received INSTEAD when timeout without match
  printf "lastlook-match = %s  -after = %s  -pattern = %s\n",
                           $match,      $after,        $pattern;

  $gotit = $PortObj->lookfor($count);	# block until $count chars received

  $PortObj->are_match("-re", "pattern", "text");
      # possible match strings: "pattern" is a regular expression,
      #                         "text" is a literal string

=head1 DESCRIPTION

This module provides an object-based user interface essentially
identical to the one provided by the Win32::SerialPort module.

=head2 Initialization

The primary constructor is B<new> with either a F<PortName>, or a
F<Configuretion File> specified.  With a F<PortName>, this
will open the port and create the object. The port is not yet ready
for read/write access. First, the desired I<parameter settings> must
be established. Since these are tuning constants for an underlying
hardware driver in the Operating System, they are all checked for
validity by the methods that set them. The B<write_settings> method
updates the port (and will return True under POSIX). Ports are opened
for binary transfers. A separate C<binmode> is not needed.

  $PortObj = new Device::SerialPort ($PortName, $quiet, $lockfile)
       || die "Can't open $PortName: $!\n";

The C<$quiet> parameter is ignored and is only there for compatibility
with Win32::SerialPort.  The C<$lockfile> parameter is optional.  It will
attempt to create a file (containing just the current process id) at the
location specified. This file will be automatically deleted when the
C<$PortObj> is no longer used (by DESTROY). You would usually request
C<$lockfile> with C<$quiet> true to disable messages while attempting
to obtain exclusive ownership of the port via the lock. Lockfiles are
experimental in Version 0.07. They are intended for use with other
applications. No attempt is made to resolve port aliases (/dev/modem ==
/dev/ttySx) or to deal with login processes such as getty and uugetty.

Using a F<Configuration File> with B<new> or by using second constructor,
B<start>, scripts can be simplified if they need a constant setup. It
executes all the steps from B<new> to B<write_settings> based on a previously
saved configuration. This constructor will return C<undef> on a bad
configuration file or failure of a validity check. The returned object is
ready for access. This is new and experimental for Version 0.055.

  $PortObj2 = start Device::SerialPort ($Configuration_File_Name)
       || die;

The third constructor, B<tie>, will combine the B<start> with Perl's
support for tied FileHandles (see I<perltie>). Device::SerialPort will
implement the complete set of methods: TIEHANDLE, PRINT, PRINTF,
WRITE, READ, GETC, READLINE, CLOSE, and DESTROY. Tied FileHandle
support is new with Version 0.04 and the READ and READLINE methods
were added in Version 0.06. In "scalar context", READLINE sets B<stty_icanon>
to do character processing and calls B<lookfor>. It restores B<stty_icanon>
after the read. In "list context", READLINE does Canonical (line) reads if
B<stty_icanon> is set or calls B<streamline> if it is not. (B<stty_icanon>
is not altered). The B<streamline> choice allows duplicating the operation
of Win32::SerialPort for cross-platform scripts. 

The implementation attempts to mimic STDIN/STDOUT behaviour as closely
as possible: calls block until done and data strings that exceed internal
buffers are divided transparently into multiple calls. In Version 0.06,
the output separators C<$,> and C<$\> are also applied to PRINT if set.
The B<output_record_separator> and B<output_field_separator> methods can set
I<Port-FileHandle-Specific> versions of C<$,> and C<$\> if desired. Since
PRINTF is treated internally as a single record PRINT, C<$\> will be applied.
Output separators are not applied to WRITE (called as
C<syswrite FH, $scalar, $length, [$offset]>).
The input_record_separator C<$/> is not explicitly supported - but an
identical function can be obtained with a suitable B<are_match> setting.

  $PortObj2 = tie (*FH, 'Device::SerialPort', $Configuration_File_Name)
       || die;

The tied FileHandle methods may be combined with the Device::SerialPort
methods for B<read, input>, and B<write> as well as other methods. The
typical restrictions against mixing B<print> with B<syswrite> do not
apply. Since both B<(tied) read> and B<sysread> call the same C<$ob-E<gt>READ>
method, and since a separate C<$ob-E<gt>read> method has existed for some
time in Device::SerialPort, you should always use B<sysread> with the
tied interface (when it is implemented).

=over 8

Certain parameters I<SHOULD> be set before executing B<write_settings>.
Others will attempt to deduce defaults from the hardware or from other
parameters. The I<Required> parameters are:

=item baudrate

Any legal value.

=item parity

One of the following: "none", "odd", "even".

By default, incoming parity is not checked.  This mimics the behavior
of most terminal programs (like "minicom").  If you need parity checking
enabled, please use the "stty_inpck" and "stty_istrip" functions.

=item databits

An integer from 5 to 8.

=item stopbits

Legal values are 1 and 2.

=item handshake

One of the following: "none", "rts", "xoff".

=back

Some individual parameters (eg. baudrate) can be changed after the
initialization is completed. These will be validated and will
update the I<serial driver> as required. The B<save> method will
write the current parameters to a file that B<start, tie,> and
B<restart> can use to reestablish a functional setup.

  $PortObj = new Win32::SerialPort ($PortName, $quiet)
       || die "Can't open $PortName: $^E\n";    # $quiet is optional

  $PortObj->user_msg(ON);
  $PortObj->databits(8);
  $PortObj->baudrate(9600);
  $PortObj->parity("none");
  $PortObj->stopbits(1);
  $PortObj->handshake("rts");

  $PortObj->write_settings || undef $PortObj;

  $PortObj->save($Configuration_File_Name);
  $PortObj->baudrate(300);
  $PortObj->restart($Configuration_File_Name);	# back to 9600 baud

  $PortObj->close || die "failed to close";
  undef $PortObj;				# frees memory back to perl

=head2 Configuration Utility Methods

Use B<alias> to convert the name used by "built-in" messages.

  $PortObj->alias("MODEM1");

Starting in Version 0.07, a number of I<Application Variables> are saved
in B<$Configuration_File>. These parameters are not used internally. But
methods allow setting and reading them. The intent is to facilitate the
use of separate I<configuration scripts> to create the files. Then an
application can use B<start> as the Constructor and not bother with
command line processing or managing its own small configuration file.
The default values and number of parameters is subject to change.

  $PortObj->devicetype('none'); 
  $PortObj->hostname('localhost');  # for socket-based implementations
  $PortObj->hostaddr(0);            # a "false" value
  $PortObj->datatype('raw');        # 'record' is another possibility
  $PortObj->cfg_param_1('none');
  $PortObj->cfg_param_2('none');    # 3 spares should be enough for now
  $PortObj->cfg_param_3('none');

=head2 Configuration and Capability Methods

The Win32 Serial Comm API provides extensive information concerning
the capabilities and options available for a specific port (and
instance). This module will return suitable responses to facilitate
porting code from that environment.

The B<get_tick_count> method is a clone of the I<Win32::GetTickCount()>
function. It matches a corresponding method in I<Win32::CommPort>.
It returns time in milliseconds - but can be used in cross-platform scripts.

=over 8

Binary selections will accept as I<true> any of the following:
C<("YES", "Y", "ON", "TRUE", "T", "1", 1)> (upper/lower/mixed case)
Anything else is I<false>.

There are a large number of possible configuration and option parameters.
To facilitate checking option validity in scripts, most configuration
methods can be used in two different ways:

=item method called with an argument

The parameter is set to the argument, if valid. An invalid argument
returns I<false> (undef) and the parameter is unchanged. The function
will also I<carp> if B<$user_msg> is I<true>. The port will be updated
immediately if allowed (an automatic B<write_settings> is called).

=item method called with no argument in scalar context

The current value is returned. If the value is not initialized either
directly or by default, return "undef" which will parse to I<false>.
For binary selections (true/false), return the current value. All
current values from "multivalue" selections will parse to I<true>.

=item method called with no argument in list context

Methods which only accept a limited number of specific input values
return a list consisting of all acceptable choices. The null list
C<(undef)> will be returned for failed calls in list context (e.g. for
an invalid or unexpected argument). Only the baudrate, parity, databits,
stopbits, and handshake methods currently support this feature.

=back

=head2 Operating Methods

Version 0.04 adds B<pulse> methods for the I<RTS, BREAK, and DTR> bits. The
B<pulse> methods assume the bit is in the opposite state when the method
is called. They set the requested state, delay the specified number of
milliseconds, set the opposite state, and again delay the specified time.
These methods are designed to support devices, such as the X10 "FireCracker"
control and some modems, which require pulses on these lines to signal
specific events or data. Timing for the I<active> part of B<pulse_break_on>
is handled by I<POSIX::tcsendbreak(0)>, which sends a 250-500 millisecond
BREAK pulse. It is I<NOT> guaranteed to block until done.

  $PortObj->pulse_break_on($milliseconds);
  $PortObj->pulse_rts_on($milliseconds);
  $PortObj->pulse_rts_off($milliseconds);
  $PortObj->pulse_dtr_on($milliseconds);
  $PortObj->pulse_dtr_off($milliseconds);

In Version 0.05, these calls and the B<rts_active> and B<dtr_active> calls
verify the parameters and any required I<ioctl constants>, and return C<undef>
unless the call succeeds. You can use the B<can_ioctl> method to see if
the required constants are available. On Version 0.04, the module would
not load unless I<asm/termios.ph> was found at startup.

=head2 Stty Shortcuts

Version 0.06 adds primitive methods to modify port parameters that would
otherwise require a C<system("stty...");> command. These act much like
the identically-named methods in Win32::SerialPort. However, they are
initialized from "current stty settings" when the port is opened rather
than from defaults. And like I<stty settings>, they are passed to the
serial driver and apply to all operations rather than only to I/O
processed via the B<lookfor> method or the I<tied FileHandle> methods.
Each returns the current setting for the parameter. There are no "global"
or "combination" parameters - you still need C<system("stty...")> for that.

The methods which handle CHAR parameters set and return values as C<ord(CHAR)>.
This corresponds to the settings in the I<POSIX termios cc_field array>. You
are unlikely to actually want to modify most of these. They reflect the
special characters which can be set by I<stty>.

  $PortObj->is_xon_char($num_char);	# VSTART (stty start=.)
  $PortObj->is_xoff_char($num_char);	# VSTOP
  $PortObj->is_stty_intr($num_char);	# VINTR
  $PortObj->is_stty_quit($num_char);	# VQUIT
  $PortObj->is_stty_eof($num_char);	# VEOF
  $PortObj->is_stty_eol($num_char);	# VEOL
  $PortObj->is_stty_erase($num_char);	# VERASE
  $PortObj->is_stty_kill($num_char);	# VKILL
  $PortObj->is_stty_susp($num_char);	# VSUSP

Binary settings supported by POSIX will return 0 or 1. Several parameters
settable by I<stty> do not yet have shortcut methods. Contact me if you
need one that is not supported. These are the common choices. Try C<man stty>
if you are not sure what they do.

  $PortObj->stty_echo;
  $PortObj->stty_echoe;
  $PortObj->stty_echok;
  $PortObj->stty_echonl;
  $PortObj->stty_ignbrk;
  $PortObj->stty_istrip;
  $PortObj->stty_inpck;
  $PortObj->stty_parmrk;
  $PortObj->stty_ignpar;
  $PortObj->stty_icrnl;
  $PortObj->stty_igncr;
  $PortObj->stty_inlcr;
  $PortObj->stty_opost;
  $PortObj->stty_isig;
  $PortObj->stty_icanon;

The following methods require successfully loading I<ioctl constants>.
They will return C<undef> if the needed constants are not found. But
the method calls may still be used without syntax errors or warnings
even in that case.

  $PortObj->stty_ocrlf;
  $PortObj->stty_onlcr;
  $PortObj->stty_echoke;
  $PortObj->stty_echoctl;

=head2 Lookfor and I/O Processing 

Some communications programs have a different need - to collect
(or discard) input until a specific pattern is detected. For lines, the
pattern is a line-termination. But there are also requirements to search
for other strings in the input such as "username:" and "password:". The
B<lookfor> method provides a consistant mechanism for solving this problem.
It searches input character-by-character looking for a match to any of the
elements of an array set using the B<are_match> method. It returns the
entire input up to the match pattern if a match is found. If no match
is found, it returns "" unless an input error or abort is detected (which
returns undef).

Unlike Win32::SerialPort, B<lookfor> does not handle backspace, echo, and
other character processing. It expects the serial driver to handle those
and to be controlled via I<stty>. For interacting with humans, you will
probably want C<stty_icanon(1)> during B<lookfor> to obtain familiar
command-line response. The actual match and the characters after it (if
any) may also be viewed using the B<lastlook> method. It also adopts the
convention from Expect.pm that match strings are literal text (tested using
B<index>) unless preceeded in the B<are_match> list by a B<"-re",> entry.
The default B<are_match> list is C<("\n")>, which matches complete lines.

   my ($match, $after, $pattern, $instead) = $PortObj->lastlook;
     # input that MATCHED, input AFTER the match, PATTERN that matched
     # input received INSTEAD when timeout without match ("" if match)

   $PortObj->are_match("text1", "-re", "pattern", "text2");
     # possible match strings: "pattern" is a regular expression,
     #                         "text1" and "text2" are literal strings

Everything in B<lookfor> is still experimental. Please let me know if you
use it (or can't use it), so I can confirm bug fixes don't break your code.
For literal strings, C<$match> and C<$pattern> should be identical. The
C<$instead> value returns the internal buffer tested by the match logic.
A successful match or a B<lookclear> resets it to "" - so it is only useful
for error handling such as timeout processing or reporting unexpected
responses.

The B<lookfor> method is designed to be sampled periodically (polled). Any
characters after the match pattern are saved for a subsequent B<lookfor>.
Internally, B<lookfor> is implemented using the nonblocking B<input> method
when called with no parameter. If called with a count, B<lookfor> calls
C<$PortObj-E<gt>read(count)> which blocks until the B<read> is I<Complete> or
a I<Timeout> occurs. The blocking alternative should not be used unless a
fault time has been defined using B<read_interval, read_const_time, and
read_char_time>. It exists mostly to support the I<tied FileHandle>
functions B<sysread, getc,> and B<E<lt>FHE<gt>>. When B<stty_icanon> is
active, even the non-blocking calls will not return data until the line
is complete.

The internal buffers used by B<lookfor> may be purged by the B<lookclear>
method (which also clears the last match). For testing, B<lookclear> can
accept a string which is "looped back" to the next B<input>. This feature
is enabled only when C<set_test_mode_active(1)>. Normally, B<lookclear>
will return C<undef> if given parameters. It still purges the buffers and
last_match in that case (but nothing is "looped back"). You will want
B<stty_echo(0)> when exercising loopback.

The B<matchclear> method is designed to handle the
"special case" where the match string is the first character(s) received
by B<lookfor>. In this case, C<$lookfor_return == "">, B<lookfor> does
not provide a clear indication that a match was found. The B<matchclear>
returns the same C<$match> that would be returned by B<lastlook> and
resets it to "" without resetting any of the other buffers. Since the
B<lookfor> already searched I<through> the match, B<matchclear> is used
to both detect and step-over "blank" lines.

The character-by-character processing used by B<lookfor> is fine for
interactive activities and tasks which expect short responses. But it
has too much "overhead" to handle fast data streams.There is also a
B<streamline> method which is a fast, line-oriented alternative with
just pattern searching. Since B<streamline> uses the same internal buffers,
the B<lookclear, lastlook, are_match, and matchclear> methods act the same
in both cases. In fact, calls to B<streamline> and B<lookfor> can be
interleaved if desired (e.g. an interactive task that starts an upload and
returns to interactive activity when it is complete).

There are two additional methods for supporting "list context" input:
B<lastline> sets an "end_of_file" I<Regular Expression>, and B<linesize>
permits changing the "packet size" in the blocking read operation to allow
tuning performance to data characteristics. These two only apply during
B<READLINE>. The default for B<linesize> is 1. There is no default for
the B<lastline> method.

The I<Regular Expressions> set by B<are_match> and B<lastline>
will be pre-compiled using the I<qr//> construct on Perl 5.005 and higher.
This doubled B<lookfor> and B<streamline> speed in my tests with
I<Regular Expressions> - but actual improvements depend on both patterns
and input data.

The functionality of B<lookfor> includes a limited subset of the capabilities
found in Austin Schutz's I<Expect.pm> for Unix (and Tcl's expect which it
resembles). The C<$before, $match, $pattern, and $after> return values are
available if someone needs to create an "expect" subroutine for porting a
script. When using multiple patterns, there is one important functional
difference: I<Expect.pm> looks at each pattern in turn and returns the first
match found; B<lookfor> and B<streamline> test all patterns and return the
one found I<earliest> in the input if more than one matches.

=head2 Exports

Nothing is exported by default. The following tags can be used to have
large sets of symbols exported:

=over 4

=item :PARAM

Utility subroutines and constants for parameter setting and test:

	LONGsize	SHORTsize	nocarp		yes_true
	OS_Error

=item :STAT

The Constants named BM_* and CE_* are omitted. But the modem status (MS_*)
Constants are defined for possible use with B<modemlines> and
B<wait_modemlines>. They are
assigned to corresponding functions, but the bit position will be
different from that on Win32.

Which incoming bits are active:

	MS_CTS_ON    - Clear to send
    MS_DSR_ON    - Data set ready
    MS_RING_ON   - Ring indicator  
    MS_RLSD_ON   - Carrier detected
    MS_RTS_ON    - Request to send (might not exist on Win32)
    MS_DTR_ON    - Data terminal ready (might not exist on Win32)

If you want to write more POSIX-looking code, you can use the constants
seen there, instead of the Win32 versions:

    TIOCM_CTS, TIOCM_DSR, TIOCM_RI, TIOCM_CD, TIOCM_RTS, and TIOCM_DTR

Offsets into the array returned by B<status:>

	ST_BLOCK	ST_INPUT	ST_OUTPUT	ST_ERROR

=item :ALL

All of the above. Except for the I<test suite>, there is not really a good
reason to do this.

=back

=head1 PINOUT

Here is a handy pinout map, showing each line and signal on a standard DB9
connector:

=over 8

=item 1 DCD

Data Carrier Detect

=item 2 RD

Receive Data

=item 3 TD

Transmit Data

=item 4 DTR

Data Terminal Ready

=item 5 SG

Signal Ground

=item 6 DSR

Data Set Ready

=item 7 RTS

Request to Send

=item 8 CTS

Clear to Send

=item 9 RI

Ring Indicator

=back

=head1 NOTES

The object returned by B<new> is NOT a I<Filehandle>. You will be
disappointed if you try to use it as one.

e.g. the following is WRONG!!

 print $PortObj "some text";

This module uses I<POSIX termios> extensively. Raw API calls are B<very>
unforgiving. You will certainly want to start perl with the B<-w> switch.
If you can, B<use strict> as well. Try to ferret out all the syntax and
usage problems BEFORE issuing the API calls (many of which modify tuning
constants in hardware device drivers....not where you want to look for bugs).

With all the options, this module needs a good tutorial. It doesn't
have one yet.

=head1 EXAMPLE

It is recommended to always use "read(255)" due to some unexpected
behavior with the termios under some operating systems (Linux and Solaris
at least).  To deal with this, a routine is usually needed to read from
the serial port until you have what you want.  This is a quick example
of how to do that:

 my $port=Device::SerialPort->new("/dev/ttyS0");

 my $STALL_DEFAULT=10; # how many seconds to wait for new input
 
 my $timeout=$STALL_DEFAULT;
 
 $port->read_char_time(0);     # don't wait for each character
 $port->read_const_time(1000); # 1 second per unfulfilled "read" call
 
 my $chars=0;
 my $buffer="";
 while ($timeout>0) {
        my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars
        if ($count > 0) {
                $chars+=$count;
                $buffer.=$saw;
 
                # Check here to see if what we want is in the $buffer
                # say "last" if we find it
        }
        else {
                $timeout--;
        }
 }

 if ($timeout==0) {
        die "Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
 }


=head1 PORTING

For a serial port to work under Unix, you need the ability to do several
types of operations.  With POSIX, these operations are implemented with
a set of "tc*" functions.  However, not all Unix systems follow this
correctly.  In those cases, the functions change, but the variables used
as parameters generally turn out to be the same.

=over 4

=item Get/Set RTS

This is only available through the bit-set(TIOCMBIS)/bit-clear(TIOCMBIC)
ioctl function using the RTS value(TIOCM_RTS).

 ioctl($handle,$on ? $TIOCMBIS : $TIOCMBIC, $TIOCM_RTS);

=item Get/Set DTR

This is available through the bit-set(TIOCMBIS)/bit-clear(TIOCMBIC)
ioctl function using the DTR value(TIOCM_DTR)

 ioctl($handle,$on ? $TIOCMBIS : $TIOCMBIC, $TIOCM_DTR);

or available through the DTRSET/DTRCLEAR ioctl functions, if they exist.

 ioctl($handle,$on ? $TIOCSDTR : $TIOCCDTR, 0);

=item Get modem lines

To read Clear To Send (CTS), Data Set Ready (DSR), Ring Indicator (RING), and
Carrier Detect (CD/RLSD), the TIOCMGET ioctl function must be used.

 ioctl($handle, $TIOCMGET, $status);

To decode the individual modem lines, some bits have multiple possible
constants:

=over 4

=item Clear To Send (CTS)

TIOCM_CTS

=item Data Set Ready (DSR)

TIOCM_DSR

=item Ring Indicator (RING)

TIOCM_RNG
TIOCM_RI

=item Carrier Detect (CD/RLSD)

TIOCM_CAR
TIOCM_CD

=back

=item Get Buffer Status

To get information about the state of the serial port input and output
buffers, the TIOCINQ and TIOCOUTQ ioctl functions must be used.  I'm not
totally sure what is returned by these functions across all Unix systems.
Under Linux, it is the integer number of characters in the buffer.

 ioctl($handle,$in ? $TIOCINQ : $TIOCOUTQ, $count);
 $count = unpack('i',$count);

=item Get Line Status

To get information about the state of the serial transmission line
(to see if a write has made its way totally out of the serial port
buffer), the TIOCSERGETLSR ioctl function must be used.  Additionally,
the "Get Buffer Status" methods must be functioning, as well as having
the first bit of the result set (Linux is TIOCSER_TEMT, others unknown,
but we've been using TIOCM_LE even though that should be returned from
the TIOCMGET ioctl).

 ioctl($handle,$TIOCSERGETLSR, $status);
 $done = (unpack('i', $status) & $TIOCSER_TEMT);

=item Set Flow Control

Some Unix systems require special TCGETX/TCSETX ioctls functions and the
CTSXON/RTSXOFF constants to turn on and off CTS/RTS "hard" flow control
instead of just using the normal POSIX tcsetattr calls.

 ioctl($handle, $TCGETX, $flags);
 @bytes = unpack('SSSS',$flags);
 $bytes[0] = $on ? ($CTSXON | $RTSXOFF) : 0;
 $flags = pack('SSSS',@bytes);
 ioctl($handle, $TCSETX, $flags);

=back

=head1 KNOWN LIMITATIONS

The current version of the module has been tested with Perl 5.003 and
above. It was initially ported from Win32 and was designed to be used
without requiring a compiler or using XS. Since everything is (sometimes
convoluted but still pure) Perl, you can fix flaws and change limits if
required. But please file a bug report if you do.

The B<read> method, and tied methods which call it, currently can use a
fixed timeout which approximates behavior of the I<Win32::SerialPort>
B<read_const_time> and B<read_char_time> methods. It is used internally
by I<select>. If the timeout is set to zero, the B<read> call will return
immediately. A B<read> larger than 255 bytes will be split internally
into 255-byte POSIX calls due to limitations of I<select> and I<VMIN>.
The timeout is reset for each 255-byte segment. Hence, for large B<reads>,
use a B<read_const_time> suitable for a 255-byte read. All of this is
expeimental in Version 0.055.

  $PortObj->read_const_time(500);	# 500 milliseconds = 0.5 seconds
  $PortObj->read_char_time(5);		# avg time between read char

The timing model defines the total time allowed to complete the operation.
A fixed overhead time is added to the product of bytes and per_byte_time.

Read_Total = B<read_const_time> + (B<read_char_time> * bytes_to_read)

Write timeouts and B<read_interval> timeouts are not currently supported.

On some machines, reads larger than 4,096 bytes may be truncated at 4,096,
regardless of the read size or read timing settings used. In this case,
try turning on or increasing the inter-character delay on your serial
device. Also try setting the read size to

  $PortObj->read(1) or $PortObj->read(255)

and performing multiple reads until the transfer is completed.


=head1 BUGS

See the limitations about lockfiles. Experiment if you like.

With all the I<currently unimplemented features>, we don't need any more.
But there probably are some.

Please send comments and bug reports to kees@outflux.net.

=head1 Win32::SerialPort & Win32API::CommPort

=head2 Win32::SerialPort Functions Not Currently Supported

  $LatchErrorFlags = $PortObj->reset_error;

  $PortObj->read_interval(100);		# max time between read char
  $PortObj->write_char_time(5);
  $PortObj->write_const_time(100);

=head2 Functions Handled in a POSIX system by "stty"

	xon_limit	xoff_limit	xon_char	xoff_char
	eof_char	event_char	error_char	stty_intr
	stty_quit	stty_eof	stty_eol	stty_erase
	stty_kill	stty_clear	is_stty_clear	stty_bsdel	
	stty_echoke	stty_echoctl	stty_ocrnl	stty_onlcr	

=head2 Win32::SerialPort Functions Not Ported to POSIX

	transmit_char

=head2 Win32API::CommPort Functions Not Ported to POSIX

	init_done	fetch_DCB	update_DCB	initialize
	are_buffers	are_baudrate	are_handshake	are_parity
	are_databits	are_stopbits	is_handshake	xmit_imm_char
	is_baudrate	is_parity	is_databits	is_write_char_time
	debug_comm	is_xon_limit	is_xoff_limit	is_read_const_time
	suspend_tx	is_eof_char	is_event_char	is_read_char_time
	is_read_buf	is_write_buf	is_buffers	is_read_interval
	is_error_char	resume_tx	is_stopbits	is_write_const_time
	is_binary	is_status	write_bg	is_parity_enable
	is_modemlines	read_bg		read_done	break_active
	xoff_active	is_read_buf	is_write_buf	xon_active

=head2 "raw" Win32 API Calls and Constants

A large number of Win32-specific elements have been omitted. Most of
these are only available in Win32::SerialPort and Win32API::CommPort
as optional Exports. The list includes the following:

=over 4

=item :RAW

The API Wrapper Methods and Constants used only to support them
including PURGE_*, SET*, CLR*, EV_*, and ERROR_IO*

=item :COMMPROP

The Constants used for Feature and Properties Detection including
BAUD_*, PST_*, PCF_*, SP_*, DATABITS_*, STOPBITS_*, PARITY_*, and 
COMMPROP_INITIALIZED

=item :DCB

The constants for the I<Win32 Device Control Block> including
CBR_*, DTR_*, RTS_*, *PARITY, *STOPBIT*, and FM_*

=back

=head2 Compatibility

This code implements the functions required to support the MisterHouse
Home Automation software by Bruce Winter. It does not attempt to support
functions from Win32::SerialPort such as B<stty_emulation> that already
have POSIX implementations or to replicate I<Win32 idosyncracies>. However,
the supported functions are intended to clone the equivalent functions
in Win32::SerialPort and Win32API::CommPort. Any discrepancies or
omissions should be considered bugs and reported to the maintainer.

=head1 AUTHORS

 Based on Win32::SerialPort.pm, Version 0.8, by Bill Birthisel
 Ported to linux/POSIX by Joe Doss for MisterHouse
 Ported to Solaris/POSIX by Kees Cook for Sendpage
 Ported to BSD/POSIX by Kees Cook
 Ported to Perl XS by Kees Cook

 Currently maintained by:
 Kees Cook, kees@outflux.net, http://outflux.net/

=head1 SEE ALSO

Win32API::CommPort

Win32::SerialPort

perltoot - Tom Christiansen's Object-Oriented Tutorial

=head1 COPYRIGHT

 Copyright (C) 1999, Bill Birthisel. All rights reserved.
 Copyright (C) 2000-2007, Kees Cook.  All rights reserved.

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

# /* vi:set ai ts=4 sw=4 expandtab: */
