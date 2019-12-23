#
#  The HyCon-package provides an object oriented interface to the HYCON 
# hybrid controller for the Analogparadigm Model-1 analog computer.
#
# 06-AUG-2016   B. Ulmann   Initial version
# 07-AUG-2016   B. Ulmann   Added extensive error checking, changed 
#                           c-/C-commands for easier interfacing
# 08-AUG-2016   B. Ulmann   Analog calibration capability added
# 31-AUG-2016   B. Ulmann   Support of digital potentiometers
# 01-SEP-2016   B. Ulmann   Initial potentiometer setting based on 
#                           configuration file etc.
# 13-MAY-2017   B. Ulmann   Start adaptation to new, AVR2560-based hybrid 
#                           controller with lots of new features
# 16-MAY-2017   B. Ulmann   single_run_sync() implemented
# 08-FEB-2018   B. Ulmann   Changed read_element to expect the name of a 
#                           computing element instead of its address
# 01-SEP-2018   B. Ulmann   Adapted to the final implementation of the 
#                           hybrid controller (version 0.4)
# 02-SEP-2018   B. Ulmann   Bug fixes, get_response wasn't implemented too 
#                           cleverly, it is now much faster than before :-)
# 13-SEP-2018   B. Ulmann   Fixed a warning problem when used with 
#                           hc_gui.pl
# 20-FEB-2019   B. Ulmann   Changed the reset routine within new since the 
#                           old one sometimes failed
# 31-JUL-2019   B. Ulmann   read_elements() does no longer implicitly halt
#                           the analog computer!
#                           set_pt() now limits values outside of the 
#                           interval [-1, +1] to -1/+1 and croaks.
# 05-SEP-2019   B. Ulmann   Added set_ro_group and read_ro_group functions.
# 11-SEP-2019   B. Ulmann   Made HyCon into a proper Perl module suitable 
#                           for CPAN.
# 12-SEP-2019   B. Ulmann   Added requirements to Makefile.PL which were 
#                           missing.
# 15-SEP-2019   B. Ulmann   Fixed some typos in the POD.
# 21-SEP-2019   B. Ulmann   set_ro_group expected decimal addresses instead
#                           of hexadecimal ones
# 29-SEP-2019   B. Ulmann   new() now takes care of determining the
#                           configuration file name
# 28-OCT-2019   B. Ulmann   Typos in documentation corrected.
# 14-DEC-2019   B. Ulmann   Adapted to new firmware, added XBAR command, added 
#                           DPT-query, set_address entfernt
#

package IO::HyCon;

=pod

=head1 NAME

IO::HyCon - Perl interface to the Analog Paradigm hybrid controller.

=head1 VERSION

This document refers to version 0.1 of HyCon

=head1 SYNOPSIS

    use strict;
    use warnings;

    use File::Basename;
    use HyCon;

    (my $config_filename = basename($0)) =~ s/\.pl$//;
    print "Create object...\n";
    my $ac = HyCon->new("$config_filename.yml");

    $ac->set_ic_time(500);  # Set IC-time to 500 ms
    $ac->set_op_time(1000); # Set OP-Time to 1000 ms
    $ac->single_run();      # Perform a single computation run

    # Read a value from a specific computing element:
    my $element_name = 'SUM8-0';
    my $value = $ac->read_element($element_name);

=head1 DESCRIPTION

This module implements a simple object oriented interface to the Arduino\textregistered~ based 
Analog Paradigm hybrid controller which interfaces an analog computer to a 
digital computer and thus allows true hybrid computation.

=cut

use strict;
use warnings;

use vars qw($VERSION);
our $VERSION = '1.0';

use YAML qw(LoadFile);
use Carp qw(confess cluck carp);
use Device::SerialPort;
use Time::HiRes qw(usleep);
use File::Basename;

use constant {
    DIGITAL_OUTPUT_PORTS   => 8,
    DIGITAL_INPUT_PORTS    => 8,
    DPT_RESOLUTION => 10, 
    XBAR_CONFIG_BYTES => 10,
};

my $instance;

=head1 Functions and methods

=head2 new($filename)

This function generates a HyCon-object. Currently there is only one hybrid 
controller supported, so this is, in fact, a singleton and every subsequent 
invocation will cause a fatal error. If no configuration file path is supplied
as parameter, new() tries to open a YAML-file with the name of the currently
running program but with the extension '.yml' instead of '.pl'. This file is
assumed to have the following structure:

    config.yml:
        serial:
            port: /dev/tty.usbmodem621
            bits: 8
            baud: 250000
            parity: none
            stopbits: 1
            poll_interval: 1000
            poll_attempts: 200
    types:
        0: PS
        1: SUM8
        2: INT4
        3: PT8
        4: CU
        5: MLT8
        6: MDS2
        7: CMP4
        8: HC
    elements: 
        Y_DDOT: 0x0100
        Y_DOT:  0x0101
        PT_8-0: 0x0220
        PT_8-1: 0x0221
        PT_8-2: 0x0222
        PT_8-3: 0x0223
        PT_8-4: 0x0224
        PT_8-5: 0x0225
        PT_8-6: 0x0226
        PT_8-7: 0x0227
    manual_potentiometers:
        PT_8-0,rT_8-1,PT_8-2,PT_8-3,PT_8-4,PT_8-5,PT_8-6,PT_8-7

The setup shown above will not fit your particular analog computer 
configuration; it just serves as an example. The remaining parameters 
nevertheless apply in general and are mostly self-explanatory. 'poll_interval'
and 'poll_attempts' control how often this interface will poll the hybrid 
controller to get a response to a command issued before. The values shown above 
are overly pessimistic but this won't matter during normal operation.

If the number of values specified in the array 'values' does not match the 
number of configured potentiometers, the function will abort.

The 'types' section contains the mapping of the devices types as returned by 
the analog computer's readout system to their module names. This should not 
be changed but will be expanded when new analog computer modules will be 
developed.

The 'elements' section contains a list of computing elements defined by an 
arbitrary name and their respective address in the computer system. Calling 
read_all_elements() will switch the computer into HALT-mode, read the 
values of all elements in this list and return a reference to a hash 
containing all values and IDs of the elements read. (If jitter during readout 
is to be minimized, a readout-group should be defined instead, see below.)

Ideally, all manual potentiometers are listed under
'manual_potentiometers' which is used for automatic readout of the settings 
of these potentiometers by calling read_mpts(). This is useful, if a 
simulation has been parameterized manually and these parameters are required 
for documentation purposes or the like. Caution: All potentiometers to be read 
out by read_mpts() must be defined in the elements-section.

The new() function will clear the communication buffer of the hybrid 
controller by reading and discarding and data until a timeout will be 
reached. This currently equals the product of 'poll_interval' and 
'poll_attempts' and may take a few seconds during startup.

=cut

sub new {
    my ($class, $config_filename) = @_;

    confess "Only one instance of a HyCon-object at a time is supported!" 
        if $instance++;

    ($config_filename = basename($0)) =~ s/\.pl$/\.yml/
        unless defined($config_filename);

    my $config = LoadFile($config_filename) or 
        confess "Could not read configuration YAML-file: $!";

    my $port = Device::SerialPort->new($config->{serial}{port}) or 
        confess "Unable to open USB-port: $!\n";
    $port->databits($config->{serial}{bits});
    $port->baudrate($config->{serial}{baud});
    $port->parity($config->{serial}{parity});
    $port->stopbits($config->{serial}{stopbits});

    # If no poll-interval is specified, use 1000 microseconds
    $config->{serial}{poll_interval} //= 1000;  
    $config->{serial}{poll_attempts} //= 200;   # and 200 such intervals.

    # Get rid of any data which might still be in the serial line buffer
    for my $i (1 .. 10) {
        last if $port->lookfor();
    }

    # Now reset the controller
    print "Resetting the hybrid controller...\n";

    my ($attempt, $data);
    for my $i (1 .. 10) {
        print "Reset attempt $i\n";
        $port->write('x'); # Reset the hybrid controller
        sleep(1);
        last if ($data = $port->lookfor()) eq 'RESET';
    }
    confess "Unexpected response from controller: >>$data<<\n" unless $data eq 'RESET';
#        print "Lookfor: ", $port->lookfor(), "\n";
#        while (++$attempt < $config->{serial}{poll_attempts}) {
#            $data = $port->lookfor();
#            last OUTER if $data eq 'RESET';
#            usleep($config->{serial}{poll_interval});
#        }
#    }

    # Create the actual object
    my $object;
    {
        no warnings 'uninitialized';
        $object = bless(my $self = { 
            port => $port, 
            poll_interval => $config->{serial}{poll_interval},
            poll_attempts => $config->{serial}{poll_attempts},
            elements => $config->{elements},
            types    => $config->{types},
            times    => {
                ic_time => -1,
                op_time => -1,
            },
            manual_potentiometers => 
                [ split(/\s*,\s*/, $config->{manual_potentiometers}) ],
        }, $class);
    }

    return $object;
}

=head2 get_response()

In some cases, e.g. external HALT conditions, it is necessary to query the 
hybrid controller for any messages which may have occured since the last 
command. This can be done with this method - it will poll the controller 
for a period of 'poll_interval' times 'poll_attemps' microseconds. If this
timeout value is not suitable, a different value (in milliseconds) can be 
supplied as first argument of this method. If this argument is zero or negative,
get_response will wait indefinitely for a response from the hybrid controller.

=cut

sub get_response {
    my ($self, $timeout) = @_;
    $timeout = $self->{poll_interval} unless defined($timeout);

    my $attempt;
    do {
        my $response = $self->{port}->lookfor();
        return $response if $response;
        # If we poll indefinitely, there is no need to wait at all
        usleep($timeout) if $timeout > 0; 
    } while ($timeout < 1 or ++$attempt < $self->{poll_attempts});
}

=head2 ic()

This method switches the analog computer to IC (initial condition) mode 
during which the integrators are (re)set to their respective initial value. 
Since this involves charging a capacitor to a given value, this mode should 
be activated for the a minimum duration as required by the time scale factors
involved. 

ic() and the two following methods should not be used when timing is critical. 
Instead, IC- and OP-times should be setup explicitly (see below) and then a 
single-run should be initiated which will be under control of the hybrid 
controller. This avoids latencies involved with the communication to and from
the hybrid controller and allows sub-millisecond resolution.

=head2 op()

This method switches the analog computer to operating-mode. 

=head2 halt()

Calling this method causes the analog computer to switch to HALT-mode. In 
this mode the integrators are halted and store their last value. After 
calling halt() it is possible to return to OP-mode by calling op() again. 
Depending on the analog computer being controlled, there will be a more or
less substantial drift of the integrators in HALT-mode, so it is advisable 
to keep the HALT-periods as short as possible to minimize errors. 

A typical operation cycle may look like this: IC-OP-HALT-OP-HALT-OP-HALT. 
This would start a single computation with the possibility of reading 
values from the analog computer during the HALT-intervals.

Another typical cycle is called 'repetitive operation' and looks like this: 
IC-OP-IC-OP-IC-OP... This is normally used with the integrators set to 
time-constants of 100 or 1000 and allows to display a solution as a more or 
less flicker free curve on an oscilloscope for example.

=head2 enable_ovl_halt()

During a normal computation on an analog computation there should be no 
overloads of summers or integrators. Such overload conditions are typically
the result of an erroneous computer setup (normally caused by wrong scaling of 
the underlying equations). To catch such problems it is usually a good idea to 
switch the analog computer automatically to HALT-mode when an overload occurs. 
The computing element(s) causing the overload condition can the easily 
identified on the analog computer's console and the variables of the computation
run can be read out to identify the cause of the problem.

=head2 disable_ovl_halt()

Calling this method will disable the automatic halt-on-overload 
functionality of the hybrid controller. 

=head2 enable_ext_halt()

Sometimes it is necessary to halt a computation when some condition is 
satisfied (some value reached etc.). This is normally detected by a 
comparator used in the analog computer setup. The hybrid controller 
features an EXT-HALT input jack that can be connected to such a comparator.
After calling this method, the hybrid controller will switch the analog 
computer from OP-mode to HALT as soon as the input signal patched to this 
input jack goes high.

=head2 disable_ext_halt()

This method disables the HALT-on-overflow feature of the hybrid controller.

=head2 single_run()

Calling this method will initiate a so-called 'single-run' on the analog 
computer which automatically performs the sequence IC-OP-HALT. The times 
spent in IC- and OP-mode are specified with the methods set_ic_time() and 
set_op_time() (see below).

It should be noted that the hybrid controller will not be blocked during 
such a single-run - it is still possible to issue other commands to read or 
set ports etc.

=head2 single_run_sync()

This function behaves quite like single_run() but waits for the termination 
of the single run, thus blocking any further program execution. This method 
returns true, if the single-run mode was terminated by an external halt 
condition. undef is returned otherwise.

=head2 repetitive_run()

This initiates repetitive operation, i.e. the analog computer is commanded 
to perform an IC-OP-IC-OP-... sequence. The hybrid controller will not block 
during this sequence. To terminate a repetitive run either ic() or halt() 
may be called. Note that these methods act immediately and will interrupt any 
ongoing IC- or OP-period of the analog computer.

=head2 pot_set()

This function switches the analog computer to POTSET-mode, i.e. the 
integrators are set implicitly to HALT while all (manual) potentiometers 
are connected to +1 on their respective input side. This mode can be used 
to read the current settings of the potentiometers.

=cut

# Create basic methods
my %methods = (
    ic               => ['i', '^IC'],            # Switch AC to IC-mode
    op               => ['o', '^OP'],            # Switch AC to OP-mode
    halt             => ['h', '^HALT'],          # Switch AC to HALT-mode
    disable_ovl_halt => ['a', '^OVLH=DISABLED'], # Disable HALT-on-overflow
    enable_ovl_halt  => ['A', '^OVLH=ENABLED'],  # Enable HALT-on-overflow
    disable_ext_halt => ['b', '^EXTH=DISABLED'], # Disable external HALT
    enable_ext_halt  => ['B', '^EXTH=ENABLED'],  # Enable external HALT
    repetitive_run   => ['e', '^REP-MODE'],      # Switch to RepOp
    single_run       => ['E', '^SINGLE-RUN'],    # One IC-OP-HALT-cycle
    pot_set          => ['S', '^PS'],            # Activate POTSET-mode
);

eval ('
    sub ' . $_ . ' {
        my ($self) = @_;
        $self->{port}->write("' . $methods{$_}[0] . '");
        my $response = get_response($self);
        confess "No response from hybrid controller! Command was \'' . 
                $methods{$_}[0] . '\'." unless $response;
        confess "Unexpected response from hybrid controller:\\n\\tCOMMAND=\'' . 
                $methods{$_}[0] . '\', RESPONSE=\'$response\', PATTERN=\'' . 
                $methods{$_}[1] . '\'\\n"
            if $response !~ /' . $methods{$_}[1] . '/;
    }
') for keys(%methods);

sub single_run_sync() {
    my ($self) = @_;
    $self->{port}->write('F');
    my $response = get_response($self);
    confess "No Response from hybrid controller! Command was 'F'" 
        unless $response;
    confess "Unexpected response:\n\tCOMMAND='F', RESPONSE='$response'\n"
        if $response !~ /^SINGLE-RUN/;
    my $timeout = 1.1 * ($self->{times}{ic_time} + $self->{times}{op_time});
    $response = get_response($self, $timeout);
    confess "No Response during single_run_sync within $timeout ms" 
        unless $response;
    confess "Unexpected response after single_run_sync: '$response'\n"
        if $response !~ /^EOSR/ and $response !~ /^EOSRHLT/;
    # Return true if the run was terminated by an external halt condition
    return $response =~ /^EOSRHLT/; 
}

=head2 set_ic_time($milliseconds)

It is normally advisable to let the hybrid controller take care of the overall
timing of OP and IC operations since the communication with the digital host 
introduces quite some jitter. This method sets the time the analog computer 
will spend in IC-mode during a single- or repetitive run. The time is 
specified in milliseconds and must be positive and can not exceed 999999 
milliseconds due to limitations of the hybrid controller firmware.

=cut

# Set IC-time
sub set_ic_time {
    my ($self, $ic_time) = @_;
    confess 'IC-time out of range - must be >= 0 and <= 999999!' 
        if $ic_time < 0 or $ic_time > 999999;
    my $pattern = "^T_IC=$ic_time\$";
    my $command = sprintf("C%06d", $ic_time);
    $self->{port}->write($command);
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: '$pattern'"
        if $response !~ /$pattern/;
    $self->{times}{ic_time} = $ic_time;
}

=head2 set_op_time($milliseconds)

This method specifies the duration of the OP-cycle(s) during a single- or 
repetitive analog computer run. The same limitations hold with respect to the 
value specified as for the set_ic_time() method.

=cut

# Set OP-time
sub set_op_time {
    my ($self, $op_time) = @_;
    confess 'OP-time out of range - must be >= 0 and <= 999999!' 
        if $op_time < 0 or $op_time > 999999;
    my $pattern = "^T_OP=$op_time\$";
    my $command = sprintf("c%06d", $op_time);
    $self->{port}->write($command);
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: '$pattern'"
        if $response !~ /$pattern/;
    $self->{times}{op_time} = $op_time;
}

=head2 read_element($name)

This function expects the name of a computing element specified in the 
configuation YML-file and applies the corresponding 16 bit value $address to 
the address lines of the analog computer's bus system, asserts the active-low 
/READ-line, reads one value from the READOUT-line, and de-asserts /READ again. 
read_element(...) returns a reference to a hash containing the keys 'value' and 
'id'.

=cut

sub read_element {
    my ($self, $name) = @_;
    my $address = hex($self->{elements}{$name});
    confess "Computing element $name not configured!\n" 
        unless defined($address);
    $self->{port}->write('g' . sprintf("%04X", $address & 0xffff));
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my ($value, $id) = split(/\s+/, $response);
    $id = $self->{types}{$id & 0xf} || 'UNKNOWN';
    return { value => $value, id => $id};
}

=head2 read_element_by_address($address)

This function expects the 16 bit address of a computing element as
parameter and returns a data structure identically to that returned by 
read_element. This routine should not be used in general as computing elements
are better addressed by their name. It is mainly provided for completeness.

=cut

sub read_element_by_address {
    my ($self, $address) = @_;
    $self->{port}->write('g' . sprintf("%04X", $address & 0xffff));
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my ($value, $id) = split(/\s+/, $response);
    $id = $self->{types}{$id & 0xf} || 'UNKNOWN';
    return { value => $value, id => $id};
}

=head2 read_all_elements()

The routine read_all_elements() reads the current values from all elements 
listed in the 'elements' section of the configuration file. It returns a 
reference to a hash containing all elements read with their associated values 
and IDs. It may be advisable to switch the analog computer to HALT mode before
calling read_all_elements() to minimize the effect of jitter. After calling
this routine the computer has to be switched back to OP mode again. A better
way to readout groups of elements is by means of a readout-group (see below).

=cut

sub read_all_elements {
    my ($self) = @_;
    my %result;
    for my $key (sort(keys(%{$self->{elements}}))) {
        my $result = $self->read_element($key);
        $result{$key} = { value => $result->{value}, id => $result->{id} };
    }
    return \%result;
}

=head2 set_ro_group()

This function defines a readout group, i.e. a group of computing elements 
specified by their respective names as defined in the configuration file. All
elements of such a readout group can be read by issuing a single call to 
read_ro_group(), thus reducing the communications overhead between the HC and
digital computer substantially. A typical call would look like this (provided
the names are defined in the configuration file):

    $ac->set_ro_group('INT0_1', 'SUM2_3');

=cut

sub set_ro_group {
    my ($self, @names) = @_;

    my @addresses;
    for my $name (@names) {
        confess "Computing element $name not configured!\n" 
            unless defined($self->{elements}{$name});
        push(@addresses, $self->{elements}{$name});
    }
    $self->{'RO-GROUP'} = \@names;
    my $command = 'G' . join(';', @addresses) . '.';
    $self->{port}->write($command);
}

=head2 read_ro_group()

read_ro_group() reads all elements defined in a readout group. This minimizes
the communications overhead between digital and analog computer and reduces
the effect of jitter during readout as well as the risk of a serial line buffer
overflow on the side of the hybrid controller. The function returns a reference
to a hash containing the names of the elements forming the readout group with
their associated values.

=cut

sub read_ro_group {
    my ($self) = @_;
    $self->{port}->write('f'); # Issue read-ro-group command
    my @values = split(/\s*;\s*/, get_response($self));
    my %result;
    $result{$_} = shift(@values) for @{$self->{'RO-GROUP'}};
    return \%result;
}

=head2 read_digital()

In addition to these analog readout capabilities, the hybrid controller also 
features eight digital inputs which can be used to read the state of 
comparators or other logic elements of the analog computer being controlled. 
This method returns an array-reference containing values of 0 or 1 for each of
the digital input ports.

=cut

# Read digital inputs
sub read_digital {
    my ($self) = @_;
    $self->{port}->write('R');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my $pattern = '^' . '\d+\s+' x (DIGITAL_INPUT_PORTS - 1) . '\d+';
    confess "Unexpected response: '$response', expected: '$pattern'"
        if $response !~ /$pattern/;
    return [ split(/\s+/, $response) ];
}

=head2 digital_output($port, $value)

The hybrid controller also features eight digital outputs which can be used to 
control the electronic switches which are part of the comparator unit. Calling 
digital_output(0, 1) will set the first (0) digital output to 1 etc.

=cut

# Set/reset digital outputs
sub digital_output {
    my ($self, $port, $state) = @_;
    confess '$port must be >= 0 and < ' . DIGITAL_OUTPUT_PORTS
        if $port < 0 or $port > DIGITAL_OUTPUT_PORTS;
    $self->{port}->write(($state ? 'D' : 'd') . $port);
    $self->{'RO-GROUP'} = [];
}

=head2 set_xbar()

set_xbar sends a configuration bitstream to an XBAR-module specified by its 
name in the elements section of the configuration file. The routine expects
two parameters: The name of the XBAR-module and a HEX-number, 
XBAR_CONFIG_BYTES * 2  nibbles in length.

=cut

sub set_xbar {
    my ($self, $name, $config) = @_;
    confess "XBAR-module >>$name<< not defined!" unless defined($self->{elements}{$name});
    confess 'Exactly ', XBAR_CONFIG_BYTES * 2, ' HEX-nibbles are required as config data! Only ',
        length($config), ' were found!' if length($config) != XBAR_CONFIG_BYTES * 2;
    my $address = sprintf('%04X', hex($self->{elements}{$name}));
    my $command = "X$address$config";
    $self->{port}->write($command);
    my $response = get_response($self); # Get response
    confess 'No response from hybrid controller!' unless $response;
    confess "Configuring XBAR failed: >>$response<<." unless $response eq 'XBAR READY';
}

=head2 read_mpts()

Calling read_mpts() returns a reference to a hash containing the current 
settings of all manual potentiometers listed in the 
'manual_potentiometers' section in the configuration file. To accomplish this, 
the analog computer is switched to POTSET-mode (implying HALT for the 
integrators). In this mode, all inputs of potentiometers are connected to 
the positive machine unit +1, so that their current setting can be read out.
("Free" potentiometers will behave erroneously unless their second input is
connected to ground, refer to the analog computer manual for more information
on that topic.)

=cut

sub read_mpts {
    my ($self) = @_;
    $self->pot_set();
    my %result;
    for my $key (@{$self->{manual_potentiometers}}) {
        my $result = $self->read_element($key);
        $result{$key} = { value => $result->{value}, id => $result->{id} };
    }
    return \%result;
}

=head2 set_pt($name, $value)

To set a digital potentiometer, set_pt() is called. The first argument is the 
name of the the digital potentiometer to be set as specified in the elements 
section in the configuration YML-file (an entry like 'DPT24-2: 0060/2'). The 
second argument is a floating point value 0 <= v <= 1. If the potentiometer to
be set can not be found in the configuration data or if the value is out of 
bounds, the function will die.

=cut

sub set_pt {
    my ($self, $pot, $value) = @_;
    confess "Potentiometer >>$pot<< not defined!" unless defined($self->{elements}{$pot});
    my ($address, $number) = split('/', $self->{elements}{$pot});

    if ($value < 0 or $value > 1) {
        carp "$value must be >= 0 and <= 1, has been limited\n";
        $value = 1  if $value > 1;
        $value = 0 if $value < 0;
    }

    #  Convert value to an integer suitable to setting the potentiometer and 
    # generate fixed length strings for the parameters address (single digit)
    # and value (three digits, 0000 <= value <= 1023):
    $value = sprintf('%04d', int($value * (2 ** DPT_RESOLUTION - 1)));

    $address = sprintf('%04X', hex($address)); # Make sure we have a four digit hex value
    $number  = sprintf('%02d', $number);       # Make sure we have a two digital pot number

    $self->{port}->write("P$address$number$value");

    my $response = get_response($self);      # Get response
    confess 'No response from hybrid controller!' unless $response;
    my ($raddress, $rnumber, $rvalue) = $response =~ /^P(\d+)\.(\d+)=(\d+)$/;
    confess "set_pt failed! $address vs. $raddress, $rnumber vs. $number, $value vs. $rvalue" 
        if ($address != $raddress) or ($number != $rnumber) or ($value != $rvalue);
}

=head2 read_dpts()

Read the current setting of all digital potentiometers. Caution: This does
not query the actual potentiometers as there is not readout capability 
on the modules containing DPTs, instead this function will query the hybrid
controller to return the values it has stored when DPTs were set.

=cut

sub read_dpts {
    my ($self) = @_;
    $self->{port}->write('q');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my %result;
    for my $entry (split(';', $response)) {
        my ($address, $data) = split(':', $entry);
        my @values;
        push(@values, $_) for split(',', $data);
        $result{$address} = \@values;
    }
    return \%result;
}

=head2 get_status()

Calling get_status() yields a reference to a hash containing all current 
status information of the hybrid controller. A typical hash structure 
returned may look like this:

    $VAR1 = {
          'IC-time' => '500',
          'MODE' => 'HALT',
          'OP-time' => '1000',
          'STATE' => 'NORM',
          'OVLH' => 'DIS',
          'EXTH' => 'DIS',
          'RO_GROUP' => [..., ..., ...],
          'DPTADDR' => [60 => 9, 80 => 8, ], # hex address and module id
        };

In this case the IC-time has been set to 500 ms while the OP-time is set to 
one second. The analog computer is currently in HALT-mode and the hybrid 
controller is in its normal state, i.e. it is not currently performing a 
single- or repetitive-run. HALT on overload and external HALT are both 
disabled. A readout-group has been defined, too.

=cut

sub get_status {
    my ($self) = @_;
    $self->{port}->write('s');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my %state;
    for my $entry (split(/\s*,\s*/, $response)) {
        my ($parameter, $value) = split(/\s*=\s*/, $entry);
        $state{$parameter} = $value;
    }

    my @addresses = split(/\s*;\s*/, $state{'RO-GROUP'});
    $state{'RO-GROUP'} = \@addresses;

    my %mapping;
    for my $entry (split(';', $state{DPTADDR})) {
        my ($address, $module_id) = split('/', $entry);
        $mapping{$address} = $module_id;
    }
    $state{DPTADDR} = \%mapping;

    return \%state;
}

=head2 get_op_time()

In some applications it is useful to be able to determine how long the analog 
computer has been in OP-mode. As time as such is the only free variable of 
integration in an analog-electronic analog computer, it is a central parameter 
to know. Imagine that some integration is being performed by the analog 
computer and the time which it took to reach some threshold value is of 
interest. In this case, the hybrid controller would be configured 
so that external-HALT is enabled. Then the analog computer would be placed to
IC-mode and then to OP-mode. After an external HALT has been triggered by some 
comparator of the analog commputer, the hybrid controller will switch the 
analog computer to HALT-mode immediately. Afterwards, the time the analog 
computer spent in OP-mode can be determined by calling this method. The time 
will be returned in microseconds (the resolution is about +/- 3 to 4 
microseconds).

=cut

# Get current time the AC spent in OP-mode
sub get_op_time {
    my ($self) = @_;
    $self->{port}->write('t');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my $pattern = 't_OP=\-?\d*';
    confess "Unexpected response: '$response', expected: '$pattern'"
        if $response !~ /$pattern/;
    my ($time) = $response =~ /=\s*(\-?\d+)$/;
    return $time ? $time : -1;
}

=head2 reset()

The reset() method resets the hybrid controller to its initial setup. This 
will also reset all digital potentiometer settings including their number! 
During normal operations it should not be necessary to call this method which 
was included primarily to aid debugging.

=cut

sub reset {
    my ($self) = @_;
    $self->{port}->write('x');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: 'RESET'"
        if $response ne 'RESET';
}

=head1 Examples

The following example initates a repetitive run of the analog computer with 20 
ms of operating time and 10 ms IC time:

    use strict;
    use warnings;

    use File::Basename;
    use HyCon;

    my $ac = HyCon->new();

    $ac->set_op_time(20);
    $ac->set_ic_time(10);

    $ac->repetitive_run();

=cut

=head1 AUTHOR

Dr. Bernd Ulmann, ulmann@analogparadigm.com

=cut

return 1;
