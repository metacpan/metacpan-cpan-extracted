package Device::Regulator::Plasmatronic;
use strict;
use IO::File;
use IO::Select;
use Carp;
use vars qw($AUTOLOAD);
use Time::HiRes qw(usleep);
use POSIX;
use Fcntl;

our $VERSION = "0.03";

my $TEMP_DELAY = 100;		# Microsecond (I think...)
my $TEMP_TIMEOUT = 2;		# Max time for an entry (seconds)

=head1 NAME

Plasmatronics - Plasmatronics PL regulator controller

=head1 SYNOPSIS

	use Device::Regulator::Plasmatronic;
	my $r = Device::Regulator::Plasmatronic;
	print "Current state of charge = " . $r->pl_dsoc . "\n";

=head1 DESCRIPTION

This is an interface library via the serial port to a Plasmatronics Regulator.
(http://www.plasmatronics.com.au/)

=head1 MAJOR LIMITATIONS

=head2 Serial Port

I have to replace the serial port driver - currently I use the unix only version,
but I have written 

=head2 Hard Coded Multiplier

The multiplier used for voltages etc is hard coded (currently 4 = 48 Volt system).
This can be read from the system, so I will have to do that as part of the 
initialisation.

=head2 Combined Values

Load and other things combine values from multiple locations to allow for larger 
numbers. I know that I have got this wrong in a number of places. Work to be done
to test these for large numbers (eg: > 25 Amps etc).

=head1 FUTURE

=head2 Fix Limitations

As above, look at each limitation and try and fix it up.

=head2 CGI Scripts

Write a number of example CGI scripts

=head2 Graphing

Include a graph of the history, or even daily history of the system.

=head2 Learning Kit

Put together the whole kit of files above so that it can be used in learning
environments etc to demonstrate logging, power use etc.

=head2 Power Control Link

My house has most lights and equipment controlled by the computer, which means
combined with current load we get a really good idea how much power is used 
when things are switched on. This also means we can work out how much power is
used by which piece of equipment (over time), and monitor the standard load (eg: 
what is on all the time like the Fridge).

=head1 TOOLS

I have documented here the tools that come with this, although they are not part
of this library, it is a convenient place to put them.

=head2 plbackup / plrestore

This allows you to backup all the data currently in the regulator. 
This is very handy if you want to work on the regulator which involves disconnecting
the power. You then loose all the data for the current day. This allows you to 
keep that information, not even loosing any data (except for the period it is off).

=head2 plhistory

Display the history.

=head2 plload

A simple example of some load variables displayed. A good one to look at on how
you would write your own code.

=head2 pllogger

This writes all daily entries to a log file, good for long term logging accross
long periods. You could adapt this to log any data in the system at any interval.

=head2 plloopback

Just test the loopback. You can run this to make sure the unit and code is working.
Handy to put in a test script, you could for example trigger an alarm if the
systems goes down.

=head2 plread / plwrite

Read and write to any variable in the system. Your raw access tool.

=head2 pltest

Another test code - not really necessary but I use it mostly to generally test
my changes.

=head2 pltime

Read and write the time on the system. You can setup a job to set the time 
correctly from your server on regular basis, or call it after a plrestore.

=head1 EXAMPLE CODE

=head2 Initialisation

	my $pl = Plasmatronics->new();
	if ($pl->pl_loopback) {
		print "Cool\n";
	} else {
		print "Not so cool\n";
	}

=head2 Read

	# Init above
	print "Current load = " . $pl->pl_load . "\n";

=head2 Write

	# Change the hour
	print "New hour = " . $pl->pl_hour(15) . "\n";

=head2 Full Example Used for remote display

	# This example could be used for an app, cgi or remote display

	use Plasmatronics;

	my $pl = Plasmatronics->new() || die "Can't connect to PL";

	my $soc = $pl->pl_dsoc;
	print $soc . "%\n";
	my $load = $pl->pl_load;
	my $charge = $pl->pl_charge;
	print "OUT $load, IN $charge\n";

=head1 DATA FILE

The data file (plasmatronics.dat) contains all the clever information.

So why a data file and not hard coded. Well theoretically I want to be able
to write alternate versions of this software in other languages (eg: Java, 
Python, or even a windows DLL/OLE). By keeping any of the non language
specific intelligence in the data file, this can be shared, it is also
a much neater way of doing development.

=head2 Parameters

	- Short Name    
	- Number        
	- Full description      
	- Divide by (number)    
	- Multiply by (number or BM)    
	- Unit  
	- ShiftLeft by (other name or NA)       
	- Write flag    
	- Non NV Backup/Restore (should it be backed up)

The combination of these allows us to do most of the intelligent calculations
in the data file. 

=head2 Mapping to methods

Each of the short names maps to the equivellent method starting with 'pl_'.
The nice part about this is it means you can write code with that name that
is used in place of the generic code. This is kind of useful when you want
to do more complicated calculations which can not be covered in the data file.

=head1 METHODS

Here are the methods...

=cut

# ==============================================================================
# Configuration
# ==============================================================================
# TODO: Check if these change per model.
my $commands = {
	readproc => 20,			# Read from processor location
	readnvram => 72,		# Read from NV Ram
	writeproc => 152,		# Write to processor location
	writenvram => 202,		# Write to NV Ram
	loopback => 187
};

# ==============================================================================
# INITIALISATION
# ==============================================================================
# XXX: How to work out the device?
#	- Arguments
#	- Configuration file
#	- Default
# TODO: Change the default port (via serial port driver) to windows version on
# windows, etc.
sub new {
	my ($class, %args) = @_;
	my $this = bless {}, ref($class) || $class;
	$this->{PORT}{NAME} = $args{port} || "/dev/plasmatronic";
	$this->{PORT}{TYPE} = $args{type} || "FILE";
	$this->_port_init;
	$this->_read_dat;
	return $this;
}

# Read in plasmatronics.dat
sub _read_dat {
	my ($this) = @_;
	my %h = ();
	# XXX: How do you get the location of this file?
	#	(temp symlink from etc !!!)
	close IN;
	foreach my $f ('plasmatronic.dat', '/etc/plasmatronic.dat'){
		next if (! -f $f);
		open (IN, $f) || die "Can't open found file $f";
	}
	# XXX: Check it is open?
	while (<IN>) {
		chomp;
		if (! /^#/) {
			my @arr = split(/ *\t+ */, $_);
			# Convert hex values
			if (substr($arr[1], 0,1) eq "h") {
				$arr[1] = hex(substr($arr[1], 1,2));
			}
			$h{$arr[0]}{number} = $arr[1];
			$h{$arr[0]}{note} = $arr[2];
			$h{$arr[0]}{divider} = $arr[3];
			$h{$arr[0]}{multiplier} = $arr[4];
			$h{$arr[0]}{unit} = $arr[5];
			$h{$arr[0]}{shiftleft} = $arr[6];
			$h{$arr[0]}{write} = $arr[7];
			$h{$arr[0]}{backup} = $arr[8];
		}
	}
	close IN;
	$this->{DAT} = \%h;
}

# Serial port
sub _port_init {
	my ($this) = @_;

	if ($this->{PORT}{TYPE} eq "FILE") {
		# XXX - Errors here ?
		$this->{PORT}{REF} = new IO::File "+< " . $this->{PORT}{NAME};

		my $DisplayFD = fileno ($this->{PORT}{REF}) ;

		my $DisplayTermios = POSIX::Termios->new () ;
		$DisplayTermios->getattr ($DisplayFD) ;

		$DisplayTermios->setispeed (B9600) ; # serial input speed (19200bps)
		$DisplayTermios->setospeed (B9600) ; # serial output speed (19200bps)

		my $CFlag = $DisplayTermios->getcflag () ;
		my $LFlag = $DisplayTermios->getlflag () ;
		my $OFlag = $DisplayTermios->getoflag () ;
		my $IFlag = $DisplayTermios->getiflag () ;

		$IFlag &= ~(IGNBRK|BRKINT|PARMRK|ISTRIP|INLCR|IGNCR|ICRNL|IXON) ; # raw IO
		$OFlag &= ~(OPOST) ;
		$LFlag &= ~(ECHO|ECHONL|ICANON|ISIG) ;
		$CFlag &= ~(CSIZE|PARENB|HUPCL) ;
		$CFlag |= (CREAD|CS8|CLOCAL) ;

		$DisplayTermios->setcflag ($CFlag) ;                               # update serial settings
		$DisplayTermios->setlflag ($LFlag) ;
		$DisplayTermios->setoflag ($OFlag) ;
		$DisplayTermios->setiflag ($IFlag) ;
		$DisplayTermios->setattr ($DisplayFD, TCSANOW) ;                              # update serial device

	} else {
		# Serial device
		# XXX: The device driver should know the lock file, why does it
		# insist on each bit of code calcuating the code !!!
		my $lock = $this->{PORT}{NAME};
		$lock =~ s/\/dev\///;
		$lock = "/var/lock/LCK..$lock";
		# 1 = quiet
		eval q{use Device::SerialPort;};
		die "Failed to load Device::SerialPort - $@" if ($@);
		$this->{PORT}{REF} = new Device::SerialPort ($this->{PORT}{NAME}, 0, $lock)
		      || die "Can't open " . $this->{PORT}{REF} . ": $!\n";
		$this->_port->baudrate(9600);
		$this->_port->parity("none");
		$this->_port->databits(8);
		$this->_port->stopbits(1);
	}
	# XXX Check this works for Device::SerialPort too.
	$this->{SELECT} = new IO::Select;
	$this->_select->add($this->_port());
}

sub _port {
	my ($this) = @_;
	return $this->{PORT}{REF};
}

sub _select {
	my ($this) = @_;
	return $this->{SELECT};
}

# ==============================================================================
# COMMANDS
# ==============================================================================
# Match a list
sub list {
	my ($this, $match) = @_;
	my @ret = ();
	MATCH: foreach my $key (sort {$a cmp $b} keys %{$this->{DAT}}) {
		if (defined($match)) {
			warn "Doing matches";
			foreach my $m (keys %{$match}) {
				warn "\tMatching on $m";
				warn "\t\tDAT = " . $this->{DAT}{$key}{$m};
				warn "\t\tMATCH = " . $match->{$m};
				if ($match->{$m} ne $this->{DAT}{$key}{$m}) {
					warn "\t\tNO MATCH for $m";
					next MATCH;
				}
			}
		}
		warn "ADDING $key";
		push @ret, $key;
	}
	if (wantarray()) {
		return @ret;
	} else {
		return \@ret;
	}
}

sub pl_loopback {
	my ($this) = @_;
	$this->_write(
		$commands->{'loopback'},
		0,
		0,
		255 - $commands->{'loopback'}
	);
	my $buf = $this->_read(1);
	return (ord($buf) == 128);
}

=head2 data

Read or write to a processor or nvram location. 

Returned values are always adjusted to make your life easier, but that is not
so easy for writting, so that has not yet been implemented.

=cut

sub data {
	my ($this, $name, $value) = @_;
	$this->initparams;
	if (!defined($this->{DAT}{$name})) {
		carp "Invalid data requested - " . $name;
	}

	# Write
	if (defined($value)) {
		if (! $this->{DAT}{$name}{write}) {
			croak "Trying to write to a read only value - " . $name;
		}
		my $cmd = $commands->{'writeproc'};
		if ($name =~ /^nv/) {
			$cmd = $commands->{'writenvram'};
		}
		$this->_write(
			$cmd,
			$this->{DAT}{$name}{number},
			$value,
			255 - $cmd
		);
	}

	# Proc or NV read
	my $cmd = $commands->{'readproc'};
	if ($name =~ /^nv/) {
		$cmd = $commands->{'readnvram'};
	}

	# Send command
	$this->_write(
		$cmd,
		$this->{DAT}{$name}{number},
		0,
		255 - $cmd
	);

	# Get results
	my $buf = $this->_read(2)
		or return undef;
	my $out = ord(substr($buf, 1, 1));

	# Check value
	if (defined($value) && ($out != $value)) {
		warn "Received value was not what was written";
	}

	# Shift left by?
	#	Not quite right.
	#	8 bits = * by 10
	#	32 bits = * 
	if ($this->{DAT}{$name}{shiftleft} ne "NA") {
		my $sl = $this->data($this->{DAT}{$name}{shiftleft});
		$out = $out << $sl;
	}

	# Multiplier and Divider
	if ($this->{DAT}{$name}{multiplier} eq "BM") {
		$out = $out * $this->{PARAMS}{MULTIPLIER};
	} else {
		$out = $out * $this->{DAT}{$name}{multiplier};
	}
	$out = $out / $this->{DAT}{$name}{divider};
	return $out;
}

sub exists {
	my ($this, $name) = @_;
	return exists($this->{DAT}{$name});
}

sub unit {
	my ($this, $name) = @_;
	return $this->{DAT}{$name}{unit};
}

sub note {
	my ($this, $name) = @_;
	return $this->{DAT}{$name}{note};
}

# Autoload for all methods (all others)
sub AUTOLOAD {
	my ($this, $val) = @_;
	if ($AUTOLOAD =~ /::pl_(.*)$/ && $this->exists($1)) {
		return $this->data($1, $val);
	} else {
		carp "Invalid method called - $AUTOLOAD";
	}
}

sub DESTROY {
}

# ==============================================================================
# SPECIAL HELPERS (not defined by autoloader, usually because to complicated)
# ==============================================================================
sub pl_out {
	my ($this) = @_;
	# Need high byte too 
	return $this->data('leahl') + $this->data('liahl');
}
sub pl_in {
	my ($this) = @_;
	return $this->data('ciahl') + $this->data('ceahl');
}
sub pl_load {
	my ($this) = @_;
	return $this->data('lint') + $this->data('lext');
}
sub pl_charge {
	my ($this) = @_;
	return $this->data('cint') + $this->data('cext');
}


# ==============================================================================
# INITIALISATION INTERNALLY (batv divider etc.)
# ==============================================================================
sub initparams {
	my ($this) = @_;
	# XXX: Get this somehow, only if we don't already have it
	$this->{PARAMS}{MULTIPLIER} = "4";
}

# ==============================================================================
# READ and WRITE to Serial Port
# ==============================================================================
# XXX: Arbitrary sleeps to cope with no flow control. Parameterise and
# otherwise work out better ways to deal with.
sub _write {
	my ($this, @arr) = @_;
	my $out = "";
	if ($this->{PORT}{TYPE} eq "FILE") {
		foreach my $bit (@arr) {
			usleep $TEMP_DELAY;
			# $out .= chr($bit);
			my @ready = $this->_select->can_write($TEMP_TIMEOUT);
			if (scalar(@ready) < 1) {
				croak "Timeout on write";
			}
			$this->_port->syswrite(chr($bit), 1);
		}
		# return $this->_port->syswrite($out, length($out));
	} else {
		my @ready = $this->_select->can_write($TEMP_TIMEOUT);
		if (scalar(@ready) < 1) {
			croak "Timeout on write";
		}
		return $this->_port->write($out);
	}
}

sub _read {
	my ($this, $len) = @_;
	my $buf = "";
	my $tmp = "";
	eval {
		# local $SIG{__DIE__} = sub {die $_[0];};
		# local $SIG{ALRM} = sub {die "timeout";};
		for (my $i = 0; $i < $len; $i++) {
			usleep $TEMP_DELAY;
			my @ready = $this->_select->can_read($TEMP_TIMEOUT);
			if (scalar(@ready) < 1) {
				croak "Timeout on read";
			}
			if ($this->{PORT}{TYPE} eq "FILE") {
				my $num = $this->_port->sysread($tmp, 1);
				$buf .= $tmp;
			} else {
				my ($num, $tmp) = $this->_port->read(1);
				$buf .= $tmp;
			}
		}
	};
	if ($@) {
		print STDERR "Failed read (request $len)\n";
		return undef;
	}
	return $buf;
}

# ==============================================================================
# END
# ==============================================================================

1;

