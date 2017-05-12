package Ham::Device::FT950;

use 5.008008;
use strict;
use warnings;
require Exporter;
use Device::SerialPort qw(:PARAM :STAT 0.07);
use Carp;
$|=1;

our @ISA = qw();
our @EXPORT = qw();

our @EXPORT_OK = qw();

our $VERSION = '0.29.4 ';
#Version .23 starts OO work.

my ($result, %rig_mode, %inv_rig_mode, %band, %inv_band);
my $port;

# Going to talk to a Yaesu FT-950
# Constructor to start communicating
sub new {
    my $invocant = shift;
    my $class = ref($invocant) || $invocant;
    my $self = {
                portname    => "/dev/ttyS0",  #Defaults, can be overidden
                databits    => 8,             #during construction by user.
                baudrate    => 4800,
                parity      => "none",
                stopbits    => 1,
                handshake   => "rts",
                alias       => "FT-950",
                user_msg    => "OFF",
                lockfile    => 1,
                #configFile  => "FT950.ini",
                read_char_time  => 0,
                read_const_time => 20,
                @_
            };
    bless($self, $class);
    $self->_init;
    $self->_openSerial();
    return $self;
}


#Accessor Methods
sub portname    { $_[0]->{portname  }=$_[1] if defined $_[1]; $_[0]->{portname  } }
sub databits    { $_[0]->{databits  }=$_[1] if defined $_[1]; $_[0]->{databits  } }
sub baudrate    { $_[0]->{baudrate  }=$_[1] if defined $_[1]; $_[0]->{baudrate  } }
sub parity      { $_[0]->{parity    }=$_[1] if defined $_[1]; $_[0]->{parity    } }
sub stopbits    { $_[0]->{stopbits  }=$_[1] if defined $_[1]; $_[0]->{stopbits  } }
sub handshake   { $_[0]->{handshake }=$_[1] if defined $_[1]; $_[0]->{handshake } }
sub read_char_time    { $_[0]->{read_char_time   }=$_[1] if defined $_[1]; $_[0]->{read_char_time   } }
sub read_const_time   { $_[0]->{read_const_time  }=$_[1] if defined $_[1]; $_[0]->{read_const_time  } }
sub alias       { $_[0]->{alias     }=$_[1] if defined $_[1]; $_[0]->{alias  } }
sub user_msg    { $_[0]->{user_msg  }=$_[1] if defined $_[1]; $_[0]->{user_msg  } }
sub configFile  { $_[0]->{configFile }=$_[1] if defined $_[1]; $_[0]->{configFile  } }
sub lockfile    { $_[0]->{lockfile  }=$_[1] if defined $_[1]; $_[0]->{lockfile  } }
#Blank Accessor
#sub     { $_[0]->{  }=$_[1] if defined $_[1]; $_[0]->{  } }
sub _init {
    my $self = shift;
   #So far we don't have anything to do.
}

sub _openSerial {
    
    my $self = shift;
    my $quite = 0;
    my $lockfile = $self->portname;
    if ($self->lockfile) {              #looking for 1 or 0, 1=use lockfile, 0=no lockfile
        chomp($lockfile);
        $lockfile =~ /(tty.+$)/;
        $lockfile = "/var/lock/LCK..".$1;
    } else {
        $lockfile = "";
    }
    #print "Lockfile is $lockfile \n";
    unless ($port = Device::SerialPort -> new($self->portname, $quite, $lockfile)) { croak "Unable to open " . $self->portname . ": $^E\n"; }
        $port->alias($self->alias);
        $port->user_msg($self->user_msg);
        $port->databits($self->databits);
        $port->baudrate($self->baudrate);
        $port->parity($self->parity);
        $port->stopbits($self->stopbits);
        $port->handshake($self->handshake);
        $port->read_char_time($self->read_char_time);
        $port->read_const_time($self->read_const_time);
        #$port->save($self->configFile);
}

sub DESTROY {
    my $self = shift;
    undef $port;   
}

#This is the original way to set serial port.    
#my $portName = "/dev/ttyUSB0";
#my $port = Device::SerialPort -> new($portName) || croak "Unable to open $portName: $^E\n";
#    $port-> alias("FT-950");
#    $port-> user_msg("OFF");
#    $port-> databits(8);
#    $port-> baudrate(9600);
#    $port-> parity("none");
#    $port-> stopbits(1);
#    $port-> handshake("rts");
    
#    $port-> write_settings;
#    $port-> save($configFile) || warn "Unable to write config file\n";

#$port->read_char_time(0);     # don't wait for each character
#$port->read_const_time(20); # 1 second per unfulfilled "read" call


###############################
# Set up a hash with rig modes
%rig_mode = qw( 1 LSB 2 USB 3 CW 4 FM 5 AM 6 FSK 7 CW-R 8 PKT-L 9 FSK-R A PKT-FM B FM-N C PKT-U D AM-N);
%inv_rig_mode = reverse %rig_mode;
############################
##############################
# Set up a band hash
%band = qw(00 1.8 01 3.5 03 7 04 10 05 14 06 18 07 21 08 24.5 09 28 10 50 11 GEN);
%inv_band = reverse %band;
##############################



#####################################
#
# sub closePort
# clean up serial connection
#
#sub closePort {
#    
#    $port->close || warn "Serial port did not close proper!\n";
#    undef $port;
#}

 # print "All Closed up\n";
#####################################
#
# sub writeOpt
# Write FT-950 Options to file
# Writes options to "FT950-options" to
# current directory.
# return  undef on fail, 1 on success
#
sub writeOpt {
    my $self = shift;
    my $filename = shift;
    unless ($filename) { $filename = "FT950-options" }
    my ($option,$p);
    if (!open OUTFILE, ">$filename") {
         warn "Unable to open file to write options!\n";
         return undef;
    }     
for ($option = 1; $option <= 118; $option++) {
    $p = sprintf "%03d", "$option";
    print OUTFILE "$option ".$self->readOpt($p)."\n";
    }
    close OUTFILE;
    return 1;
}
#####################################
#
# readOpt()
# Sent the option number 001-118
# and return the result
#
sub readOpt {
    my $self = shift;
    my $opt = shift;
    my $count;
    if ($opt lt "001" || $opt gt "118") {
        print "Option must be 001-118\n";
        return undef;
    }
    unless ($count = $self->writeCmd('EX'.$opt.';')) { return undef; }
    my $result = $self->readResult();
    $result =~ /EX\d{3}([+-]?\d+)\;/;
    my $r = $1;
    #print "Result from readReslt = $result, from \$r = $r\n";
    return $r;
    
}
#####################################
#
# sub playBack
# Plays back the Digital Voice Keyer
# send it string 01-05 for channels 1-5
#
sub playBack {
    my $self = shift;
    my $channel = shift;
    my $count;
    if ($channel lt "01" || $channel gt "05") {
        print "Channel must be 01-05\n";
        return undef;
    }
    unless ($count = $self->writeCmd('pb'.$channel.';')) { return undef; }
    return $count;
}
    
#####################################
#
# sub setPower
# set the rig power output
# sent it 005-100
#
sub setPower {
    my $self = shift;
    my $power = shift;
    my $count;
    if (!($power ge "005" && $power le "100")) {
        print "Power must be 005 to 100\n";
        return undef
    }
    unless ($count = $self->writeCmd('pc'.$power.';')) { return undef; }
    return $count;
}
####################################
#
# sub getPower
# returns power in watts
# value between 5-100
#
sub getPower {
    my $self = shift;
    my $power;
    unless ($power = $self->writeCmd('pc;')) { return undef; }
    my $result = $self->readResult();
    $result =~ /PC(\d+)\;/;
    my $p = $1;
    $p = sprintf "%d", "$p";
    return $p;
}

#####################################
#
# sub swapVfo
# exchanges vfo freqs, B into A, A into B
# Return num of chars sent or undef
#
sub swapVfo {
    my $self = shift;
    my $swap;
    unless ($swap = $self->writeCmd('SV;')) { return undef; }
    return $swap;
}

#####################################
#
# sub vfoSelect
# select VFO A or B
# 0=A, 1=B
# return num chars sent or undef
# if you select the same vfo twice it will mute
#
sub vfoSelect {
    my $self = shift;
    my $vfo = shift;
    my $result;
    $vfo = uc($vfo);
    if ($vfo eq 'A') {
        unless ($result = $self->writeCmd('VS'."0".';')) { return undef; }
        return $result;
    } elsif ($vfo eq 'B') {
        unless ($result = $self->writeCmd('VS'."1".';')) { return undef; }
        return $result;
    } else {
        print "vfo must be A or B\n";
        return undef;
    }
}
#####################################
#
# sub getActVfo
# Returns active vfo (receiving) A or B
# return undef on error
#
sub getActVfo {
    my $self = shift;
    my $vfo;
    my $result;
    unless ($result = $self->writeCmd('VS;')) { return undef; }
    $vfo = $self->readResult();
    $vfo =~ /VS(\d)\;/;
    my $v = $1;
    if ($v == 0) {
        return "A";
    } elsif ($v == 1) {
        return "B";
    }
    return undef;
}

#####################################
#
# sub bandSelect
# Sets the band
# Expects to receive the band in Mhz. It converts
# to the special numbers that the 950 needs:
# 00=1.8 01=3.5 02=? 03=7 04=10 05=14
# 06=18 07=21 08=28.5 09=28 10=50 11=GEN
#
# No way to query the band so guess we just
# trust it happens!
# Return undef if no bytes transmitted else
# return number of bytes sent.
#

sub bandSelect {
    my $self = shift;
    my $band = shift;
    my $numchars;
    if (!$inv_band{$band}) {
        carp "Invalid band!\n";
        return undef;
    }
    my $b = $inv_band{$band};
    unless ($numchars = $self->writeCmd('BS'.$b.';')) { return undef; }
    return $numchars;     
}

#####################################
#
# sub getFreq
#
# Send getFreq VFO "A" or "B"
# Return the 950 frequency in Mhz
# Return undef on failure.

sub getFreq {
    my $self = shift;  #if called $obj->getFreq("a"), this is obj reference
    my $vfo  = shift;   #this is the argument we want.
    my $result;
    $vfo = uc($vfo);
    if ($vfo ne "A" && $vfo ne "B") {
        carp "VFO must be A or B!\n";
        return undef;
    }
    $self->writeCmd('f'.$vfo.';');
    unless ($result = $self->readResult()) { return undef }
    $result =~ /(F[A-B])(\d+)\;/;    # So if we receive fa14000000;
    my $f = $2;                      # $2 has the numeric portion of the string
    $f = $f / 1000000;
    $f = sprintf "%2.6f", "$f";
    return $f;
}

###########################################
#
# setFreq
# Send the FT-950 VFO and Freq and it will
# Set.  Freq is verified.
# Freq must be sent in Mhz
#
sub setFreq {
    my $self = shift;
    my ($vfo, $freq) = @_;                   # Pass VFO and Freq
    #print "We got VFO:$vfo and Freq:$freq .\n";
    my $result = '';
    $vfo = uc($vfo);                         # Make VFO upper case
    $freq = $freq * 1000000;                 # Change freq to hertz
    #print "The freq after math: $freq\n";
    if ($freq < 30000 || $freq > 56000000) {
        carp "Frequency out of range!\n";
        return undef;
    }
    $freq = sprintf("%08d", $freq);         #make sure the freq is padded
                                            #7200000 needs to be 07200000
    #print "The Freq after sprintf: $freq\n";
    if ($vfo ne "A" && $vfo ne "B") {
        carp "VFO must be A or B!\n";
        return undef;
    }
    if ($vfo eq "A") {
        $self->writeCmd('fa'.$freq.';');
        $result = $self->getFreq('A');
    } elsif 
    ($vfo eq "B") {
        $self->writeCmd('fb'.$freq.';');
        $result = $self->getFreq('B');
    }
    return $result;
}
        

############################
#
# Sub writeCmd
# Send a scaler command (ie, "FA;")
# to FT-950.  Must be correctly formatted.
# Returns number of chars successfully sent to rig
# or undef on failure.
#
eval {
sub writeCmd {
    my $self = shift;
    my $cmd = shift;
    my $count;
    unless ($count = $port->write($cmd)) { return undef; }
    return $count;
}
};
###############################
#
# Sub setMode
# Sets the rig mode, must sent the actual mode
# We take care of the numbers.
# Options are 1=LSB, 2=USB, 3=CW, 4=FM, 5=AM, 6=FSK-L
# 7=CW-R, 8=PKT-L, 9=FSK-R, A=PKT-FM, B=FM-N, C=PKT-U
# D=AM-N
# uses has $inv_rig_mode
sub setMode {
    my $self = shift;
    my $mode = shift;
    $mode = uc($mode);
    if ((!$inv_rig_mode{$mode})) {
        print "Mode $mode is invalid\n";
        return undef;
    }
    my $m = $inv_rig_mode{$mode};
    $self->writeCmd('md0'.$m.';');
    my $result = $self->getMode();
    return $result;
    
}
##############################
#
# Sub getMode
# Returns the mode of the rig
# uses hash $rig_mode
#
eval {
sub getMode {
    my $self = shift;
    $self->writeCmd('md0;');
    my $mode = $self->readResult() || croak "Unable to read Rig Mode!\n";
    #print "getMode:result of command: $mode\n";
    $mode =~ /MD0([0-9A-D])\;/;
    my $m = $rig_mode{$1};
    #print "getMode:Value returned: $m\n";
    return $m;
    
}
};

###########################################
#
# Sub readSMeter
#
# Reads the S-Meter
# Send a "RM1;
# receive a string back RM1XXX; where
# XXX = 000-255
# Sub return a value 000-255 or undef
#
sub readSMeter {
    my $self = shift;
    my $meter;
    $self->writeCmd('RM1;');
    unless ($meter = $self->readResult()) {return undef }
    $meter =~ /RM1(\d+)\;/;
    my $r = $1;
    return $r
}

###########################################
#
# Sub statBSY
#
# Retrieves status of BUSY light on
# front of Rig.
# Returns 1 if ON
# Returns 0 if OFF
# Return undef is error or don't know
eval {
sub statBSY {
    my $self = shift;
    my ($busy, $result);
    unless ($result = $self->writeCmd('BY;')) { return undef; }
    $busy = $self->readResult();
    $busy =~ /BY(\d+)\;/;
    my $b = $1;
        if ($b == 10) { return 1;
        } else { return 0; }
}
};

###########################################
#
# Sub setMOX
#
# Sets and unsets the MOX (Manual Operated Xmit)
# Send a 1 to set, 0 to unset and 2 to status
# Status result:
# Returns 1 if ON
# Returns 0 if OFF
# Return undef is error or don't know
#
eval {
sub setMOX {
    my $self = shift;
    my $mox = shift;
    my ($m, $result, $r);
    if ($mox == 1) {
        unless ($result = $self->writeCmd('MX1;')) { return undef; }               
    } elsif ($mox == 0) {
          unless ($result = $self->writeCmd('MX0;')) { return undef; }
    } elsif ($mox == 2) {
        unless ($result = $self->writeCmd('MX;')) { return undef; }
        $r = $self->readResult();
        $r =~ /MX(\d)\;/;
        return $1;
    }
  }  #end sub
};  #end eval

###########################################
#
# Sub setVOX
#
# Sets and unsets the MOX (Voice Operated Xmit)
# Send a 1 to set, 0 to unset and 2 to status
# Status result:
# Returns 1 if ON
# Returns 0 if OFF
# Return undef is error or don't know
#
eval {
sub setVOX {
    my $self = shift;
    my ($vox, $m, $result, $r);
    $vox = shift;
    if ($vox == 1) {
        unless ($result = $self->writeCmd('VX1;')) { return undef; }               
    } elsif ($vox == 0) {
          unless ($result = $self->writeCmd('VX0;')) { return undef; }
    } elsif ($vox == 2) {
        unless ($result = $self->writeCmd('VX;')) { return undef; }
        $r = $self->readResult();
        $r =~ /VX(\d)\;/;
        return $1;
    }
  }  #end sub
};  #end eval

###########################################
#
# Sub statTX
#
# Retrieves TX status of Rig
# Returns 0 if Radio TX Off CAT TX OFF
# Returns 1 if Radio TX Off CAT TX ON
# Returns 2 if Radio TX ON  CAT TX OFF
# Return undef is error or don't know
eval {
sub statTX {
    my $self = shift;
    my ($busy, $result);
    unless ($result = $self->writeCmd('TX;')) { return undef; }
    $busy = $self->readResult();
    $busy =~ /TX(\d)\;/;
    my $b = $1;
        if ($b == 0)      {
            return 1;
        } elsif ($b == 1) {
            return 1;
        } elsif ($b == 2) {
            return 2;
        } else { return undef; }
}
};

###########################################
#
# Sub statFastStep
#
# Retrieves status of "Fast Step" Button
# Returns 0 for Off
# Returns 1 for ON
# Return undef is error or don't know
eval {
sub statFastStep {
    my $self = shift;
    my ($busy, $result);
    unless ($result = $self->writeCmd('FS;')) { return undef; }
    $busy = $self->readResult();
    $busy =~ /FS(\d)\;/;
    my $b = $1;
        if ($b == 0)      {
            return 0;
        } elsif ($b == 1) {
            return 1;
        } else {
            return undef;
        }
}
};

###########################################
#
# Sub setFastStep
#
# Sets the fast step mode
# Send 0 for Off
# Send 1 for ON
# Returns number of chars transmitted or
# undef on error
eval {
sub setFastStep {
    my $self = shift;
    my ($cmd, $result);
    $cmd = shift;
    if ($cmd == 0) {
        unless ($result = $self->writeCmd('FS0;')) { return undef; }
        return $result;
    } elsif ($cmd == 1) {
        unless ($result = $self->writeCmd('FS1;')) { return undef; }
        return $result;
    } else { return undef;}
    
}
};
###########################################
#
# Sub readResult
#
# Returns the result from a command to FT-950
# Remember this only works right after a
# read command.
#

sub readResult {
my $self = shift;
my $STALL_DEFAULT = 10; # how many seconds to wait for new input
my $timeout = $STALL_DEFAULT;
my $timeout_msg = "FT-950 timeout\n";
my $chars=0;
my $buffer="";

 while ($timeout>0) {
        my ($count,$saw)=$port->read(255); # will read _up to_ 255 chars
        if ($count > 0) {
                $chars+=$count;
                $buffer.=$saw;
                if ($saw =~ /;/) {
                    return $buffer;  # ; is end of data for FT-950
                    last;
                }
                # Check here to see if what we want is in the $buffer
                # say "last" if we find it
                
        }
        else {
                $timeout--;
        }
 }
 return $timeout_msg; 
 #if ($timeout==0) {
 #       die "Waited $STALL_DEFAULT seconds and never saw what I wanted\n";
 #}
}
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Ham::Device::FT950 - Functions to Communicate with Yaesu FT-950

=head1 SYNOPSIS

  use Ham::Device::FT950;
  
=head2  Constructors

  my $ft950 = new Ham::Device::FT950(
             portname    => "/dev/ttyS0",
             baudrate    => 4800,
             databits    => 8,
             parity      => "none",            
             handshake   => "rts",
             lockfile    => 1,
             read_char_time  => 0,
             read_const_time => 20           
  );

=head1 DESCRIPTION

Set of functions used to talk to a Yaesu FT-950 HF Radio.  Not all functions
of the radio are implimented.  The communications is based on Device::SerialPort
as the underlying process to communicate with the radio.  View "perldoc Device::SerialPort"
for more infomation on serial port operation and options.

Included is a demonstration program pRigctl.plx that can be used to test most of the
functionality of Ham::Device::FT950.

=head2 Configuration Parameter Methods

Below is a list of supported option that can be passed to set up serial port:

=over 5

=item $ft950-E<gt>portname($portname)

Usually a name like /dev/ttyS0 or /dev/ttyUSB0, default is /dev/ttyS0.

=item $ft950-E<gt>databits($databits)

Number of bits in the serial steam excluding start, stop and parity. Legal values integer 5 to 8, default is 8.
    
=item $ft950-E<gt>parity($parity)

One of the following: "none", "odd", "even".  If you select anything except
"none", you will need to set B<parity_enable> (not implmented yet).
Default is "none".
    
=item $ft950-E<gt>stopbits($stopbits)

Number of stopbits.  Legal valus are 1 and 2, default is 1.
    
=item $ft950-E<gt>handshake($handshake)

One of the following: "none", "rts", and "xoff".  Default is "rts".  Note the
FT-950 needs to be set "rts"; make sure all serial lines are connected.
    
=item $ft950-E<gt>alias($alias)

Use alias to convert the name used by "built-in" messages.  Default is "FT-950".

=item $ft950-E<gt>user_msg($bool)

Use Device::SerialPort's built-in messages, "ON" or "OFF".  Default is "OFF".

=item $ft950-E<gt>lockfile($lock)

Flag to use or not use a lockfile.  The Device::SerialPort package has support
for lockfiles but support is experimental.  So by setting this attribute to "0"
turns off the usage of lockfiles.
Options are "0" for no lockfile and "1" to enable lockfile, default is "1".
Note lockfile location is hard coded to /var/lock/.  If you see a messages like:

B<Unable to open /dev/ttyUSB0: File exists>
 
Then delete the file "/var/lock/LCK..USB0" and try again.  If still no sucess
try setting lockfile equal to "0".

=item $ft950-E<gt>read_char_time($time)

Average time between read characters.  Default is 0.

=item $ft950-E<gt>read_const_time($time)

Read time for serial port.  See "perldoc Device::Serial".  Default is 20ms.

=back

=head2 Instance Methods

=over 5

=item $ft950-E<gt>playBack($mem)

This method plays back one of the 5 voice memories.  $mem is required to be a
string "01" to "05".  Returns number of characters sent or undef on failure.

=item $ft950-E<gt>getPower()

Gets the current output power setting of radio.  Returns power between 5-100 or undef on failure.

=item $ft950-E<gt>swapVfo()

Swaps the frequency of VFO A and VFO B.  Returns the number of characters sent or undef on failure.

=item $ft950-E<gt>vfoSelect($vfo)

Selects VFO A or B.  $vfo = "A" or "B".  If you send the same VFO twice the rig
will mute.  Returns the number of characters sent or undef on failure.

=item $ft950-E<gt>getActVfo()

Returns which VFO is currently active.  Returns "A" or "B" or undef on failure.

=item $ft950-E<gt>bandSelect($band)

Selects active band, $band equal to one of the following: 1.8, 3.5, 7, 10, 14,
18, 21, 28.5, 29, 50.  Returns number of characters sent on undef on failure.

=item $ft950-E<gt>getFreq($vfo)

Gets the current frequency and returns the value in Mhz.  Set $vfo to "a" or
"b".  Returns undef on failure.

=item $ft950-E<gt>setFreq($vfo, $freq)

Sets frequency in the requested VFO.  $vfo must be "a" or "b" and frequency must
be in Mhz.  Returns undef on failure.

=item $ft950-E<gt>setMode($mode)

Sets the operating mode, valid modes are: LSB, USB, CW, FM, AM, FSK-L, CW-R,
PKT-L, FSK-R, PKT-FM, FM-N, PKT-U and AM-N.  Returns undef on failure.

=item $ft950-E<gt>getMode()

Gets the current operating mode or undef on failure.  Modes are LSB, USB, CW,
FM, AM, FSK-L, CW-R, PKT-L, FSK-R, PKT-FM, FM-N, PKT-U and AM-N.

=item $ft950-E<gt>setPower($power)

Sets the rigs output power.  $power must be "005" to "100".  Returns number of
characters sent or undef on failure.

=item $ft950-E<gt>readOpt($option)

Reads an option from the radio.  $option neets to be a string between "001" and
"118".  Returns the value of the option or undef on failure.

=item $ft950-E<gt>readSMeter()

Reads the current value of the S meter.  Returns a result between "000" and
"255" or undef on failure.

=item $ft950-E<gt>statBSY()

Status the "BUSY" indicator of the radio.  Returns 1 if ON or 0 if OFF.  Returns
undef on failure.

=item $ft950-E<gt>setMOX($mox)

Sets the MOX (Manual Operated Transmit) on or off, or gets the status of the MOX
.  $mox equal 1 to set, 0 unsets and 2 returns status: 1 = ON, 0 = OFF.  Returns
undef on failure.

=item $ft950-E<gt>setVOX($vox)

Sets the VOX (Voice Operated Transmit) on or off, or get the status of the VOX.
$vox equal 1 to set, 0 to unset, and 2 returns status: 1 = ON, 0 = OFF.  Returns
undef on failure.

=item $ft950-E<gt>statTX()

Returns the transmit status of the rig:

 Returns 0 if Radio TX OFF CAT TX OFF
 Returns 1 if Radio TX OFF CAT TX ON
 Returns 2 if Radio TX ON  CAT TX OFF
 Returns undef on failure.

=item $ft950-E<gt>statFastStep()

Get the status of the Fast Step mode.  Returns 0 for OFF, 1 for ON and undef for failure.

=item $ft950-E<gt>setFastStep($fsmode)

Set Fast step mode on or off. $fsmode = 0 for OFF and 1 for ON.  Returns number
of characters sent or undef on failure.

=item $ft950-E<gt>writeOpt($filename)

Writes all of the rigs options to a file.  $filename contains the filename to
write out the options.  Default filename is FT950-options, returns 1 on success and undef on failure.

=back

=head1 BUGS

This is a very ealy version using object oriented Perl, so expect a few.  Hope to complete
full implemtation in the next year or so.

=head1 SEE ALSO

FT-950 CAT Operation Reference book, Vertex Standard Co., Ltd.  Avaiable at www.yaesu.com, Device::Serial

Updates will be posted to http://www.cpan.org as they become avaiable.


=head1 AUTHOR

Tim Gimmel, E<lt>ky4j@arrl.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008-2010 by Tim Gimmel

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

