package Hardware::1Wire::HA7Net;

use Exporter;
use LWP::UserAgent;
use strict;
use vars qw($VERSION @ISA);

$VERSION = '1.01';
@ISA = qw(Exporter);
my ($RCSVERSION) = '$Revision: 1.7 $ ' =~ /\$Revision:\s+([^\s]+)/;

##############################################################################
package Hardware::1Wire::HA7Net::Generic;

use Exporter;
use vars qw($VERSION @ISA);

@ISA = qw(Exporter);
$VERSION = $Hardware::1Wire::HA7Net::VERSION;

sub _new {
    my ($class, $ha7net, $address) = @_;
    my $family = substr($address, -2);

    return bless {
	ha7net	=> $ha7net,
	family	=> $family,
	address	=> $address,
	}, $class;
    }

sub isa {
    my ($self, $type) = @_;

    die "Cannot match empty type"	unless $type;
    for my $match (@{$self->{type}}) {
	return 1	if uc($type) eq $match;
	}
    return 0;
    }

sub ha7net { shift->{ha7net} }

sub family { shift->{family} }

sub address { shift->{address} }

sub units { shift->{units} }

sub type { 
    my $self = shift;
    if (wantarray) {
	return @{ $self->{type} };
	}
    else {
	return $self->{type}[0];
	}
    }

sub part_of { shift->{part_of} }

##############################################################################
package Hardware::1Wire::HA7Net::DS1820;

use Exporter;
use vars qw($VERSION @ISA);

@ISA = qw(Hardware::1Wire::HA7Net::Generic);
$VERSION = $Hardware::1Wire::HA7Net::VERSION;

sub _new {
    my $class = shift;
    my $self = $class->SUPER::_new(@_);

    $self->{type} = [qw(DS1820 DS18S20 DS1920 1820 18S20 1920)];
    $self->{units} = "Degrees C";
    return $self;
    }


sub temperature {
    my $self = shift;
    my $response = $self->{ha7net}->{ua}->get($self->{ha7net}->{baseurl} .
	"1Wire/ReadTemperature.html?Address_Array=$self->{address}");
    return undef	unless $response->is_success;
    $response = $response->content;

    my @response = $response =~
	/ID="Address.*?VALUE="([\dA-F]+)"
		.*?
	 ID="Temperature.*?VALUE="(-?[\d.]+)"/x;

    if (wantarray) {
	return @response;
	}
    else {
	return $response[1];
	}
    }

##############################################################################
package Hardware::1Wire::HA7Net::DS18B20;

use Exporter;
use vars qw($VERSION @ISA);

@ISA = qw(Hardware::1Wire::HA7Net::Generic);
$VERSION = $Hardware::1Wire::HA7Net::VERSION;

sub _new {
    my $class = shift;
    my $self = $class->SUPER::_new(@_);

    $self->{resolution} = 12;
    $self->{type} = [qw(DS18B20 18B20)];
    $self->{units} = "Degrees C";
    return $self;
    }

sub resolution {
    my $self = shift;
    if (@_) {
	my $resolution = shift;
	die "Resolution out of range of 9..12 for DS18B20 $self->{address}"
	    if $resolution < 9 || $ resolution > 12;
	$self->{resolution} = $resolution;
	}
    return $self->{resolution};
    }

sub temperature {
    my $self = shift;
    my $response = $self->{ha7net}->{ua}->get($self->{ha7net}->{baseurl} .
	"1Wire/ReadDS18B20.html?DS18B20Request={$self->{address},$self->{resolution}}");
    return undef	unless $response->is_success;
    $response = $response->content;

    my @response = $response =~
	/ID="Address.*?VALUE="([\dA-F]+)"
		 .*?
	 ID="Temperature.*?VALUE="(-?[\d.]+)
		 .*?
	 ID="Resolution.*?VALUE="([\d]+\+?)"/x;

    if (wantarray) {
	return @response;
	}
    else {
	return $response[1];
	}
    }

##############################################################################
package Hardware::1Wire::HA7Net::Analog;

use Exporter;
use vars qw($VERSION @ISA);

@ISA = qw(Hardware::1Wire::HA7Net::Generic);
$VERSION = $Hardware::1Wire::HA7Net::VERSION;

sub _new {
    my $class = shift;
    my $self = $class->SUPER::_new(@_);

    my $response = $self->{ha7net}->{ua}->get($self->{ha7net}->{baseurl} .
	"1Wire/ReadAnalogProbe.html?Address_Array=$self->{address}")->content;

    my ($type, $units) = $response =~
	/ID="Probe_Type.*?VALUE="(\w+)"
		.*?
	 ID="Probe_Units.*?VALUE="(.*?)"/x;

    $self->{type} = [ $type ];
    $self->{units} = $units;
    return $self;
    }

sub value {
    my $self = shift;
    my $response = $self->{ha7net}->{ua}->get($self->{ha7net}->{baseurl} .
	"1Wire/ReadAnalogProbe.html?Address_Array=$self->{address}");
    return undef	unless $response->is_success;
    $response = $response->content;

    my @response = $response =~
	/ID="Probe_Address.*?VALUE="([\dA-F]+)"
		.*?
	 ID="Probe_Value.*?VALUE="(-?[\d.]+)"
		.*?
	 ID="Temperature_Address.*?VALUE="([\dA-F]+)"
		.*?
	 ID="Temperature.*?VALUE="(-?[\d.]+?)"/x;

    if (wantarray) {
	return @response;
	}
    else {
	return $response[1];
	}
    }

##############################################################################
package Hardware::1Wire::HA7Net;

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    my ($scan, $response, $sensor);
    if (@_) {
	($self->{baseurl}, $scan) = @_;
	$self->{baseurl} =~ s#/*$#/#;
	}
    else {
	die "Cannot yet probe for HA7Net's";
	}

    $self->{ua} = new LWP::UserAgent;
    $self->{ua}->agent("$class/$VERSION");

    #
    # If we do not want to scan the device now, just fill in empty arrays and
    # return.  Otherwise, continue with scanning the devices.
    #.
    if (defined $scan && $scan == 0) {
	@{ $self->{sensors} } = ();
	%{ $self->{by_addr} } = ();
	return $self;
	}

    $response = $self->{ua}->get($self->{baseurl} .
	"1Wire/Search.html?ConditionalSearch=on");
    die "Cannot access $self->{baseurl}"	unless $response->is_success;

    ($self->{version}) = $response->content =~ /HA7Net: (\d+(\.\d+)+)/;

    for my $addr ($response->content =~ /ID="ADDRESS.*?VALUE="([\dA-F]+)"/g) {
	if ($addr =~ /10$/) {
	    $sensor = _new Hardware::1Wire::HA7Net::DS1820 ($self, $addr);
	    }
	elsif ($addr =~ /28$/) {
	    $sensor = _new Hardware::1Wire::HA7Net::DS18B20 ($self, $addr);
	    }
	elsif ($addr =~ /12$/) {
	    $sensor = _new Hardware::1Wire::HA7Net::Analog ($self, $addr);
	    }
	push @{ $self->{sensors} }, $sensor;
	$self->{by_addr}->{$sensor->{address}} = $sensor;
	}

    _generate_associated_addresses($self);
    return $self;
    }

sub scan {
    my $self = shift;
    my ($response, $sensor, %by_addr, @new);

    @{ $self->{sensors} } = ();
    %by_addr = %{ $self->{by_addr} };
    %{ $self->{by_addr} } = ();

    $response = $self->{ua}->get($self->{baseurl} .
	"1Wire/Search.html?ConditionalSearch=on");

    for my $addr ($response->content =~ /ID="ADDRESS.*?VALUE="([\dA-F]+)"/g) {
	unless ($sensor = delete $by_addr{$addr}) {
	    if ($addr =~ /10$/) {
		$sensor = _new Hardware::1Wire::HA7Net::DS1820 ($self, $addr);
		}
	    elsif ($addr =~ /28$/) {
		$sensor = _new Hardware::1Wire::HA7Net::DS18B20 ($self, $addr);
		}
	    elsif ($addr =~ /12$/) {
		$sensor = _new Hardware::1Wire::HA7Net::Analog ($self, $addr);
		}
	    push @new, $sensor;
	    }
	push @{ $self->{sensors} }, $sensor;
	$self->{by_addr}->{$sensor->{address}} = $sensor;
	}

    _generate_associated_addresses($self);

    if (defined $_[0]) {
	if (ref $_[0] eq "ARRAY") {
	    @{ $_[0] } = @new;
	    }
	else {
	    $_[0] = \@new;
	    }
	}
    if (defined $_[1]) {
	if (ref $_[1] eq "ARRAY") {
	    @{ $_[1] } = values %by_addr;
	    }
	else {
	    $_[1] = [ values %by_addr ];
	    }
	}
    return (@new + values %by_addr);	# Number of (existence of) changes
    }

#
# Find the addresses of the Temperature sensor in the analog sensors.  Not
# to be called externally.
#
sub _generate_associated_addresses {
    my $self = shift;
    my $response;

    ANALOG: for my $addr (keys %{ $self->{by_addr} }) {
	my $assoc_addr;
	next unless $addr =~ /12$/;
	for my $chk (values %{ $self->{by_addr} }) {
	    no warnings;
	    next ANALOG if $chk->{part_of} == $self->{by_addr}->{$addr};
	    }
	$response = $self->{ua}->get($self->{baseurl} .
	    "1Wire/ReadAnalogProbe.html?Address_Array=$addr")->content;
	($assoc_addr) =
	    $response =~ /ID="Temperature_Address.*?VALUE="([\dA-F]+)"/;
	$self->{by_addr}->{$assoc_addr}->{part_of} = $self->{by_addr}->{$addr};
	}
    }

sub sensors {
    @{ shift->{sensors} }
    }

sub read {
    my $self = shift;
    my (@objs, @ds1820, @ds18b20, @analog, %analog_objs, $response,
	$sensor, $sub, @answer, @results);

    #
    # Read everything by default, else read the set specified by the caller
    #
    @_ = @{$self->{sensors}} unless @_;
    #
    # First, convert all request entities to objects, preparing for batched
    # reads.  If there is no object associated with a particular address,
    # create the object (which means reading it).  We exclude those from a
    # second scan, of course.  If there are any previously unknown sensors,
    # there will be @results, so we'll have to _generate_associated_addresses
    #
    for my $addr (@_) {
	if (ref($addr) =~ /^Hardware::1Wire::HA7Net::/) {
	    push @objs, $addr;
	    }
	elsif (ref($addr)) {
	    die "Cannot use read on a non Hardware::1Wire::HA7Net:: object";
	    }
	elsif ($addr !~ /^[\dA-Fa-f]{16}/) {
	    die "Illegal Dalls Semiconductor device address";
	    }
	elsif (exists $self->{by_addr}->{$addr}) {
	    push @objs, $self->{by_addr}->{$addr};
	    }
	else {
	    #
	    # Add a new device!
	    #
	    if ($addr =~ /10$/) {
		$response = $self->{ua}->get($self->{baseurl} .
		    "1Wire/ReadTemperature.html?Address_Array=$addr")->content;
		if (@answer = $response =~
		    /ID="Address.*?VALUE="([\dA-F]+)"
			    .*?
		     ID="Temperature.*?VALUE="(-?[\d.]+)"/gx) {
		    $sensor = _new Hardware::1Wire::HA7Net::DS1820 ($self, $addr);
		    }
		else {
		    warn "Cannot read device at address $addr";
		    }
		}
	    elsif ($addr =~ /28$/) {
		$response = $self->{ua}->get($self->{baseurl} .
		    "1Wire/ReadDS18B20.html?DS18B20Request={$addr,12}")->content;

		if (@answer = $response =~
		    /ID="Address.*?VALUE="([\dA-F]+)"
			     .*?
		     ID="Temperature.*?VALUE="(-?[\d.]+)/gx) {
		    $sensor = _new Hardware::1Wire::HA7Net::DS18B20 ($self, $addr);
		    }
		else {
		    warn "Cannot read device at address $addr";
		    }
		}
	    elsif ($addr =~ /12$/) {
		$response = $self->{ua}->get($self->{baseurl} .
		    "1Wire/ReadAnalogProbe.html?Address_Array=$addr")->content;

		if (@answer = $response =~
		    /ID="Probe_Address.*?VALUE="([\dA-F]+)"
			    .*?
		     ID="Probe_Value.*?VALUE="(-?[\d.]+)"
			    .*?
		     ID="Temperature_Address.*?VALUE="([\dA-F]+)"
			    .*?
		     ID="Temperature.*?VALUE="(-?[\d.]+?)"/gx) {
		    $sensor = _new Hardware::1Wire::HA7Net::Analog ($self, $addr);
		    #
		    # Analog devices have a temperature sensor associated
		    # with them - create that device, too (and enter it here)
		    #
		    if ($answer[2] =~ /10$/) {
			$sub = _new Hardware::1Wire::HA7Net::DS1820 ($self, $answer[2]);
			}
		    elsif ($answer[2] =~ /28$/) {
			$sub = _new Hardware::1Wire::HA7Net::DS18B20 ($self, $answer[2]);
			}
		    else {
			die "Unknown co-sensor associated with $addr";
			}
		    push @{ $self->{sensors} }, $sub;
		    $self->{by_addr}->{$sub->{address}} = $sub;
		    }
		else {
		    warn "Cannot read device at address $addr";
		    }
		}
	    else {
		die "Unknown sensor type $addr";
		}
	    if (@answer) {
		push @{ $self->{sensors} }, $sensor;
		$self->{by_addr}->{$sensor->{address}} = $sensor;
		push @results, @answer;
		}
	    }
	}
    _generate_associated_addresses($self)	if @results;
    #
    #
    # Next find all the analog sensors in the set of addresses given
    #
    for my $sensor (@objs) {
	if ($sensor->{ha7net} != $self) {
	    warn "Cannot read sensor from a different HA7Net";
	    next;
	    }
	if ($sensor->isa("hmp2001s")) {
	    push @analog, $sensor->{address};
	    $analog_objs{$sensor}++;
	    }
	}
    #
    # Then find all the  temperature sensors, eliminating those that would
    # be read by the analog read routine (so we don't read them twice)
    #
    for my $sensor (@objs) {
	if ($sensor->{ha7net} != $self) {
	    warn "Cannot read sensor from a different HA7Net";
	    next;
	    }
	if ($sensor->isa("ds1820")) {
	    no warnings;	# Otherwise the "unless" will elicit them
	    push @ds1820, $sensor->{address}
		unless $analog_objs{$sensor->part_of};
	    }
	elsif ($sensor->isa("ds18b20")) {
	    no warnings;	# Otherwise the "unless" will elicit them
	    push @ds18b20, "{$sensor->{address},$sensor->{resolution}}"
		unless $analog_objs{$sensor->part_of};
	    }
	}
    #
    # Now actually read the devices
    #
    if (@ds1820) {
	$response = $self->{ua}->get($self->{baseurl} .
	    "1Wire/ReadTemperature.html?Address_Array=" .
	    join ",", @ds1820)->content;
	push @results, $response =~
	    /ID="Address.*?VALUE="([\dA-F]+)"
		    .*?
	     ID="Temperature.*?VALUE="(-?[\d.]+)"/gx;
	}
    if (@ds18b20) {
	$response = $self->{ua}->get($self->{baseurl} .
	    "1Wire/ReadDS18B20.html?DS18B20Request=" .
	    join ",", @ds18b20)->content;

	push @results, $response =~
	    /ID="Address.*?VALUE="([\dA-F]+)"
		     .*?
	     ID="Temperature.*?VALUE="(-?[\d.]+)/gx;
	}
    if (@analog) {
	$response = $self->{ua}->get($self->{baseurl} .
	    "1Wire/ReadAnalogProbe.html?Address_Array=" .
	    join ",", @analog)->content;

	push @results, $response =~
	    /ID="Probe_Address.*?VALUE="([\dA-F]+)"
		    .*?
	     ID="Probe_Value.*?VALUE="(-?[\d.]+)"
		    .*?
	     ID="Temperature_Address.*?VALUE="([\dA-F]+)"
		    .*?
	     ID="Temperature.*?VALUE="(-?[\d.]+?)"/gx;
	}

    return @results;
    }

sub version { shift->{version} }

1;

__END__

=pod

=head1 NAME

Hardware::1Wire::HA7Net, Hardware::1Wire::HA7Net::DS1820,
Hardware::1Wire::HA7Net::DS18B20, Hardware::1Wire::HA7Net::HMP2001S

=head1 SYNOPSIS

    use Hardware::1Wire::HA7Net;
    $unit = new Hardware::1Wire::HA7Net "http://ha7net.local.net";

    for $s ($unit->sensors) {
	if ($s->isa("ds1820")) {
	    print scalar $s->temperature, "\n";
	    push @addrs, $s->address;
	    }
	if ($s->isa("ds18b20")) {
	    $s->resolution(10);
	    printf "Addr: %s, Temp: %s, Resolution: %s\n", $s->temperature;
	    push @addrs, $s->address;
	    }
	if ($s->isa("hmp2001s")) {
	    print scalar $s->value, "\n";
	    push @addrs, $s->address;
	    }
	}

    %sensors = $unit->read(@addrs);
    %sensors = $unit->read($unit->sensors);
    %sensors = $unit->read();

    if ($unit->scan(\@added, \@deleted)) {
	for $s (@added) {
	    print "Added sensor: ", $s->type, $s->address;
	    }
	}



=head1 DESCRIPTION

This module provides an interface to the Embedded Data Systems HA7Net 1-Wire
bus master. 

=head2 Methods

The Hardware::1Wire::HA7Net exports the following methods:

=over 4

=item new ( URL, [ scan ] )

This method creates a new Hardware::1Wire::HA7Net object.  The first (required)
parameter to this method is the URL of the sensor (which may be either
C<http> or C<https> - if C<https>, the C<Crytpo::SSLeay> module must also be
installed).

The second (optional) parameter determines whether the C<new> method scans the
HA7Net device at the specified URL to determine the current set of attached
devices.  Note that the default behavior is to scan the device!  If the
second parameter is present, a true value indicates to scan the device, while
a false value does not scan.  Scanning the device will cause the method to
take a few seconds to complete.

Note that if you know I<a priori> the addresses of the devices connected to
the HA7Net, you do not need to scan it when calling the C<new> method.  Simply
reading the device (with the C<read> method) using a device address will cause
it to be added to the list of known devices.

=item version

This method returns the version number of the HA7Net firmware.  B<I<This
software expects the firmware to be at least version 1.0.0.9.>>  The package
will not abort if this is not the case, but erroneous behavior may result.
We strongly recommend that you upgrade your HA7Net to use version 1.0.0.13
(or later).

=item sensors

This method returns a list of known devices attached to the HA7Net.  Note
that devices become "known" when the HA7Net is scanned (by either the C<new>
or C<scan> methods) or by C<read>ing a previously unknown device.  Each
device returned will be one of the subclassed devices as described below.

=item read ( [ device-address | device-object | ... ] )

This method accepts a list of devices and reads the sensors in as
few chunked reads as possible (that is, it attempts to I<not> call the
individual C<temperature> or C<value> methods, if possible).  The device
may be a device object (of type C<Hardware::1Wire::HA7Net::I<some_type>>),
or it may be the 1-Wire address of a device.  If no parameters are specified,
then all known devices on the HA7Net are read (a device is made to be known
by scanning the HA7Net with the C<new> or <scan> methods, or by reading the
device value with the C<read> method with a specific device address).

The value returned is a hash table, where the key(s) are the 1-Wire addresses
and the values are the values read.

=item scan ( [ new [ , gone ] ] )

The method (re)scans the HA7Net device to determine the current set of
attached devices (this the method may take a few seconds to complete).  The
method returns true if there have been any changes to the set of attached
devices.

You may pass in up to two optional parameters to this method.  Each is a
reference to an array - the first will be filled with the set of devices that
have been added, and the second will be filled wih the set of devices that
have been removed.

=head1 SUBCLASSES

The Hardware::1Wire::HA7Net object also defines three subclassed objects:
Hardware::1Wire::HA7Net::DS1820, Hardware::1Wire::HA7Net::DS18B20, and
Hardware::1Wire::HA7Net::HMP2001S.

=head2 Common Methods

Each of these object types exports the following methods (there is no C<new>
method - the only way to create the subclassed devices is to have the
connected to the HA7Net at the time the C<Hardware::1Wire::HA7Net> object is
created).:

=over 4

=item isa ( type )

This method takes a single string parameter, and returns true if the object
is of that type.

=item ha7net

This method returns the Hardware::1Wire::HA7Net object that this device is
associated with.  This method is the complement to the C<sensors> method,
which lists all devices associated with an HA7Net.

=item family

This method returns a two-digit Dallas Semiconductor family number associated
with a device.

=item address

This method returns the unique 16-digit hexadecimal address of a device.

=item units

This method returns the units that the device reads (for example, "Degrees C"
or "% Relative Humidity").

=item type

This method returns an array containing the sensor type.  There may be more
than one possible type listed - for example, "DS1820" and "DS18S20".  This
list may be easily searched using the C<isa> method.  If called in a scalar
context, the method will return the first element of the array (which is the
Dallas Semiconductor sensor type).

=item part_of

If the sensor is a temperature sensor that is part of a larger sensor (for
example, the DS1820 temperature sensor in the HMP2001S Humidity/Temperature
sensor), this method returns the analog sensor object.

=back

Additionally, the sub-classed objects have methods that are specific to the
type of sensor:

=head2 Hardware::1Wire::HA7Net::DS1820

=over 4

=item temperature

This method returns the current temperature value seen by the sensor.  When
called in an arrray context, the method returns the device address and the
temperature.  When called in a scalar context, the method returns only the
temperature.

=back

=head2 Hardware::1Wire::HA7Net::DS18B20

=over 4

=item resolution

If the method is passed a parameter, the number of bits of resolution measured
by the sensor will be set to that value (the value may range from 9..12 bits
of resolution).  This method always returns the number of bits of resolution
currently measured by the sensor.

=item temperature

This method returns the current temperature value seen by the sensor.  When
called in an arrray context, the method returns the device address, the
temperature, and the number of bits of resolution.  When called in a scalar
context, the method returns only the temperature.

=back

=head2 Hardware::1Wire::HA7Net::Analog

=over 4

=item value

This method returns the current value seen by the sensor.  When called in an
array context, this method returns the analog sensor address, the analog
value, the temperature sensor address, and the temperature value.  When
called in a scalar context, this method returns only the analog sensor value.

=back

=head1 AUTHOR

Daniel V. Klein E<lt>L<dan@klein.com>E<gt>

=head1 SEE ALSO

L<http://www.embeddeddatasystems.com/> for full product and sensor details.

=cut
