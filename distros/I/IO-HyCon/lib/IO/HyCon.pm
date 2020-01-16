#
#  The HyCon-package provides an object oriented interface to the HYCON 
# hybrid controller for the Analogparadigm Model-1 analog computer.
#
# 06-AUG-2016   B. Ulmann   Initial version
# 07-AUG-2016   B. Ulmann   Added extensive error checking, changed c-/C-commands for easier interfacing
# 08-AUG-2016   B. Ulmann   Analog calibration capability added
# 31-AUG-2016   B. Ulmann   Support of digital potentiometers
# 01-SEP-2016   B. Ulmann   Initial potentiometer setting based on configuration file etc.
# 13-MAY-2017   B. Ulmann   Start adaptation to new, AVR2560-based hybrid controller with lots of new features
# 16-MAY-2017   B. Ulmann   single_run_sync() implemented
# 08-FEB-2018   B. Ulmann   Changed read_element to expect the name of a computing element instead of its address
# 01-SEP-2018   B. Ulmann   Adapted to the final implementation of the hybrid controller (version 0.4)
# 02-SEP-2018   B. Ulmann   Bug fixes, get_response wasn't implemented too cleverly, it is now much faster than before :-)
# 13-SEP-2018   B. Ulmann   Fixed a warning problem when used with hc_gui.pl
# 20-FEB-2019   B. Ulmann   Changed the reset routine within new since the old one sometimes failed
# 31-JUL-2019   B. Ulmann   read_elements() does no longer implicitly halt the analog computer!
#                           set_pt() now limits values outside of the interval [-1, +1] to -1/+1 and croaks.
# 05-SEP-2019   B. Ulmann   Added set_ro_group and read_ro_group functions.
# 11-SEP-2019   B. Ulmann   Made HyCon into a proper Perl module suitable for CPAN.
# 12-SEP-2019   B. Ulmann   Added requirements to Makefile.PL which were missing.
# 15-SEP-2019   B. Ulmann   Fixed some typos in the POD.
# 21-SEP-2019   B. Ulmann   set_ro_group expected decimal addresses instead of hexadecimal ones
# 29-SEP-2019   B. Ulmann   new() now takes care of determining the configuration file name
# 28-OCT-2019   B. Ulmann   Typos in documentation corrected.
# 14-DEC-2019   B. Ulmann   Adapted to new firmware, added XBAR command, added DPT-query, set_address entfernt
# 16-DEC-2019   B. Ulmann   set_pt expected a decimal potentiometer value while the P command of the HC expects it as hex...
# 17-DEC-2019   B. Ulmann   Added support for data logging
# 18-DEC-2019   B. Ulmann   Fixed bug in RO-group handling. The group was reset whenever a digital output was changed...
# 19-DEC-2019   B. Ulmann   Enhanced set_xbar so that it does not only accept hex encoded bit strings but also a list of connections
# 21-DEC-2019   B. Ulmann   Added gnuplot support, changed get_data behaviour, added store_data()
# 23-DEC-2019   B. Ulmann   Corrected a bug in plot which caused one data column to be skipped.
# 25-DEC-2019   B. Ulmann   Added auto-setup functionality
# 15-JAN-2020   B. Ulmann   Fixed a bug in setup which caused source and destination to be swapped in an error message
# 16-JAN-2020   B. Ulmann   The first call to set_pt after setup() had no effect althought the correct response was received...

package IO::HyCon;

=pod

=head1 NAME

IO::HyCon - Perl interface to the Analog Paradigm hybrid controller.

=head1 VERSION

This document refers to version 1.0 of HyCon

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
our $VERSION = '1.2';

use YAML qw(LoadFile);
use Carp qw(confess cluck carp);
use Device::SerialPort;
use Time::HiRes qw(usleep);
use File::Basename;
use File::Temp;

use constant {
    DIGITAL_OUTPUT_PORTS   => 8,
    DIGITAL_INPUT_PORTS    => 8,
    DPT_RESOLUTION => 10, 
    XBAR_CONFIG_BYTES => 10,
};

my $instance;

=head1 Functions and methods

=head2 new($filename)

This function generates a HyCon-object. Currently there is only one hybrid controller supported, so this is, in fact, a singleton 
and every subsequent invocation will cause a fatal error. If no configuration file path is supplied as parameter, new() tries to 
open a YAML-file with the name of the currently running program but with the extension '.yml' instead of '.pl'. This file is
assumed to have the following structure (this example configures a van der Pol oscillator):

serial:
    port: /dev/cu.usbserial-DN050L1O
    bits: 8
    baud: 115200
    parity: none
    stopbits: 1
    poll_interval: 10
    poll_attempts: 20000
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
    INT0-: 0160
    INT0+: 0123
    INT0a: 0060/0
    INT0b: 0060/1
    INT0ic: 0080/0

    INT1-: 0161
    INT1+: 0126
    INT1a: 0060/2
    INT1b: 0060/3
    INT1ic: 0080/1

    INT2-: 0162
    INT2a: 0060/4
    INT2b: 0060/5
    INT2ic: 0080/2

    MLT0+: 0100
    MLT0-: 0127
    MLT0a: 0060/6
    MLT0b: 0060/7

    MLT1+: 0101
    MLT1a: 0060/8
    MLT1b: 0060/9

    SUM0-: 0120
    SUM0+: 0124
    SUM0a: 0060/a
    SUM0b: 0060/b

    SUM1-: 0121
    SUM1+: 0125
    SUM1a: 0060/c
    SUM1b: 0060/d

    SUM2-: 0122
    SUM2a: 0060/e
    SUM2b: 0060/f

    XBAR16: 0040
xbar:
    input:
        - +1
        - -1
        - SUM2-
        - SUM1+
        - SUM1-
        - SUM0+
        - SUM0-
        - MLT1+
        - MLT0+
        - MLT0-
        - INT2-
        - INT1+
        - INT1-
        - INT0+
        - INT0-
    output:
        - INT0a
        - INT0b
        - INT1a
        - INT1b
        - INT2a
        - INT2b
        - MLT0a
        - MLT0b
        - MLT1a
        - MLT1b
        - SUM0a
        - SUM0b
        - SUM1a
        - SUM1b
        - SUM2a
        - SUM2b
problem:
    IC:
        INT1ic: +.1 # Must start with + or -!
    times:
        ic: 20
        op: 400
    coefficients:
        INT1a: .25
        INT2a: .2
        MLT0a: 1
        MLT0b: 1
        MLT1a: 1
        MLT1b: 1
        SUM0a: .02
        SUM0b: .08
        SUM1a: .1
        SUM1b: .25
    circuit:
        INT1a: INT2-
        INT2a: SUM0-
        MLT0a: INT1-
        MLT0b: INT1-
        MLT1a: INT2-
        MLT1b: SUM1-
        SUM0a: INT1-
        SUM0b: MLT1+
        SUM1a: MLT0+
        SUM1b: -1


The setup shown above will not fit your particular analog computer configuration; it just serves as an example. The remaining 
parameters nevertheless apply in general and are mostly self-explanatory. 'poll_interval' and 'poll_attempts' control how often 
this interface will poll the hybrid controller to get a response to a command issued before. The values shown above are overly 
pessimistic but this won't matter during normal operation.

If the number of values specified in the array 'values' does not match the number of configured potentiometers, the function will 
abort.

The 'types' section contains the mapping of the devices types as returned by the analog computer's readout system to their module 
names. This should not be changed but will be expanded when new analog computer modules will be developed.

The 'elements' section contains a list of computing elements defined by an arbitrary name and their respective address in the 
computer system. Calling read_all_elements() will switch the computer into HALT-mode, read the values of all elements in this list 
and return a reference to a hash containing all values and IDs of the elements read. (If jitter during readout is to be minimized, 
a readout-group should be defined instead, see below.)

Ideally, all manual potentiometers are listed under 'manual_potentiometers' which is used for automatic readout of the settings 
of these potentiometers by calling read_mpts(). This is useful, if a simulation has been parameterized manually and these 
parameters are required for documentation purposes or the like. Caution: All potentiometers to be read out by read_mpts() must be 
defined in the elements-section.

The new() function will clear the communication buffer of the hybrid controller by reading and discarding and data until a timeout 
will be reached. This currently equals the product of 'poll_interval' and 'poll_attempts' and may take a few seconds during startup.

=cut

sub new {
    my ($class, $config_filename) = @_;

    confess "Only one instance of a HyCon-object at a time is supported!" if $instance++;

    ($config_filename = basename($0)) =~ s/\.pl$/\.yml/ unless defined($config_filename);

    my $config = LoadFile($config_filename) or confess "Could not read configuration YAML-file: $!";

    my $port = Device::SerialPort->new($config->{serial}{port}) or confess "Unable to open USB-port: $!\n";
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
            manual_potentiometers => [ split(/\s*,\s*/, $config->{manual_potentiometers}) ],
            problem => $config->{problem},
            xbar    => $config->{xbar},
        }, $class);
    }

    return $object;
}

=head2 get_response()

In some cases, e.g. external HALT conditions, it is necessary to query the hybrid controller for any messages which may have 
occured since the last command. This can be done with this method - it will poll the controller for a period of 'poll_interval' 
times 'poll_attemps' microseconds. If this timeout value is not suitable, a different value (in milliseconds) can be supplied as 
first argument of this method. If this argument is zero or negative, get_response will wait indefinitely for a response from the 
hybrid controller.

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

This method switches the analog computer to IC (initial condition) mode during which the integrators are (re)set to their respective
initial value. Since this involves charging a capacitor to a given value, this mode should be activated for the a minimum duration 
as required by the time scale factors involved. 

ic() and the two following methods should not be used when timing is critical. Instead, IC- and OP-times should be setup explicitly 
(see below) and then a single-run should be initiated which will be under control of the hybrid controller. This avoids latencies 
involved with the communication to and from the hybrid controller and allows sub-millisecond resolution.

=head2 op()

This method switches the analog computer to operating-mode. 

=head2 halt()

Calling this method causes the analog computer to switch to HALT-mode. In this mode the integrators are halted and store their last 
value. After calling halt() it is possible to return to OP-mode by calling op() again. Depending on the analog computer being 
controlled, there will be a more or less substantial drift of the integrators in HALT-mode, so it is advisable to keep the 
HALT-periods as short as possible to minimize errors. 

A typical operation cycle may look like this: IC-OP-HALT-OP-HALT-OP-HALT. This would start a single computation with the possibility
of reading values from the analog computer during the HALT-intervals.

Another typical cycle is called 'repetitive operation' and looks like this: IC-OP-IC-OP-IC-OP... This is normally used with the 
integrators set to time-constants of 100 or 1000 and allows to display a solution as a more or less flicker free curve on an 
oscilloscope for example.

=head2 enable_ovl_halt()

During a normal computation on an analog computation there should be no overloads of summers or integrators. Such overload 
conditions are typically the result of an erroneous computer setup (normally caused by wrong scaling of the underlying equations). 
To catch such problems it is usually a good idea to switch the analog computer automatically to HALT-mode when an overload occurs.  
The computing element(s) causing the overload condition can the easily identified on the analog computer's console and the variables
of the computation run can be read out to identify the cause of the problem.

=head2 disable_ovl_halt()

Calling this method will disable the automatic halt-on-overload functionality of the hybrid controller. 

=head2 enable_ext_halt()

Sometimes it is necessary to halt a computation when some condition is satisfied (some value reached etc.). This is normally 
detected by a comparator used in the analog computer setup. The hybrid controller features an EXT-HALT input jack that can be 
connected to such a comparator. After calling this method, the hybrid controller will switch the analog computer from OP-mode to 
HALT as soon as the input signal patched to this input jack goes high.

=head2 disable_ext_halt()

This method disables the HALT-on-overflow feature of the hybrid controller.

=head2 single_run()

Calling this method will initiate a so-called 'single-run' on the analog computer which automatically performs the sequence 
IC-OP-HALT. The times spent in IC- and OP-mode are specified with the methods set_ic_time() and set_op_time() (see below).

It should be noted that the hybrid controller will not be blocked during such a single-run - it is still possible to issue other 
commands to read or set ports etc.

=head2 single_run_sync()

This function behaves quite like single_run() but waits for the termination of the single run, thus blocking any further program 
execution. This method returns true, if the single-run mode was terminated by an external halt condition. undef is returned 
otherwise.

=head2 repetitive_run()

This initiates repetitive operation, i.e. the analog computer is commanded to perform an IC-OP-IC-OP-... sequence. The hybrid 
controller will not block during this sequence. To terminate a repetitive run either ic() or halt() may be called. Note that these 
methods act immediately and will interrupt any ongoing IC- or OP-period of the analog computer.

=head2 pot_set()

This function switches the analog computer to POTSET-mode, i.e. the integrators are set implicitly to HALT while all (manual) 
potentiometers are connected to +1 on their respective input side. This mode can be used to read the current settings of the 
potentiometers.

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
        confess "No response from hybrid controller! Command was \'' .  $methods{$_}[0] . '\'." unless $response;
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
    confess "No Response from hybrid controller! Command was 'F'" unless $response;
    confess "Unexpected response:\n\tCOMMAND='F', RESPONSE='$response'\n" if $response !~ /^SINGLE-RUN/;
    my $timeout = 1.1 * ($self->{times}{ic_time} + $self->{times}{op_time});
    $response = get_response($self, $timeout);
    confess "No Response during single_run_sync within $timeout ms" unless $response;
    confess "Unexpected response after single_run_sync: '$response'\n" if $response !~ /^EOSR/ and $response !~ /^EOSRHLT/;
    # Return true if the run was terminated by an external halt condition
    return $response =~ /^EOSRHLT/; 
}

=head2 set_ic_time($milliseconds)

It is normally advisable to let the hybrid controller take care of the overall timing of OP and IC operations since the 
communication with the digital host introduces quite some jitter. This method sets the time the analog computer will spend in 
IC-mode during a single- or repetitive run. The time is specified in milliseconds and must be positive and can not exceed 999999 
milliseconds due to limitations of the hybrid controller firmware.

=cut

# Set IC-time
sub set_ic_time {
    my ($self, $ic_time) = @_;
    confess 'IC-time out of range - must be >= 0 and <= 999999!' if $ic_time < 0 or $ic_time > 999999;
    my $pattern = "^T_IC=$ic_time\$";
    my $command = sprintf("C%06d", $ic_time);
    $self->{port}->write($command);
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: '$pattern'" if $response !~ /$pattern/;
    $self->{times}{ic_time} = $ic_time;
}

=head2 set_op_time($milliseconds)

This method specifies the duration of the OP-cycle(s) during a single- or repetitive analog computer run. The same limitations hold 
with respect to the value specified as for the set_ic_time() method.

=cut

# Set OP-time
sub set_op_time {
    my ($self, $op_time) = @_;
    confess 'OP-time out of range - must be >= 0 and <= 999999!' if $op_time < 0 or $op_time > 999999;
    my $pattern = "^T_OP=$op_time\$";
    my $command = sprintf("c%06d", $op_time);
    $self->{port}->write($command);
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: '$pattern'" if $response !~ /$pattern/;
    $self->{times}{op_time} = $op_time;
}

=head2 read_element($name)

This function expects the name of a computing element specified in the configuation YML-file and applies the corresponding 16 bit 
value $address to the address lines of the analog computer's bus system, asserts the active-low /READ-line, reads one value from 
the READOUT-line, and de-asserts /READ again. read_element(...) returns a reference to a hash containing the keys 'value' and 'id'.

=cut

sub read_element {
    my ($self, $name) = @_;
    my $address = hex($self->{elements}{$name});
    confess "Computing element $name not configured!\n" unless defined($address);
    $self->{port}->write('g' . sprintf("%04X", $address & 0xffff));
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my ($value, $id) = split(/\s+/, $response);
    $id = $self->{types}{$id & 0xf} || 'UNKNOWN';
    return { value => $value, id => $id};
}

=head2 read_element_by_address($address)

This function expects the 16 bit address of a computing element as parameter and returns a data structure identically to that 
returned by read_element. This routine should not be used in general as computing elements are better addressed by their name. It 
is mainly provided for completeness.

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

=head2 get_data()

get_data() reads data from the internal logging facility of the hybrid controller. When a readout group has been defined and a 
single_run is executed, the hybrid controller will gather data from the readout-group automatically. There are 1024 memory cells 
for 16 bit data in the hybrid controller. The sample rate is automatically determined.

=cut

sub get_data {
    my ($self) = @_;
    my $data = [];
    $self->{port}->write('l');
    while (1) {
        my $response = get_response($self);
        last if $response eq 'No data!' or $response =~ /EOD/;
        my @values = split(/\s+/, $response);
        push(@$data, @values == 1 ? $values[0] : \@values);
    }

    $self->{data} = $data; # Store data in the object
    return $data;          # Just in case someone needs the data directly
}

=head2 read_all_elements()

The routine read_all_elements() reads the current values from all elements listed in the 'elements' section of the configuration 
file. It returns a reference to a hash containing all elements read with their associated values and IDs. It may be advisable to 
switch the analog computer to HALT mode before calling read_all_elements() to minimize the effect of jitter. After calling this 
routine the computer has to be switched back to OP mode again. A better way to readout groups of elements is by means of a 
readout-group (see below).

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

This function defines a readout group, i.e. a group of computing elements specified by their respective names as defined in the 
configuration file. All elements of such a readout group can be read by issuing a single call to read_ro_group(), thus reducing the 
communications overhead between the HC and digital computer substantially. A typical call would look like this (provided the names 
are defined in the configuration file):

    $ac->set_ro_group('INT0_1', 'SUM2_3');

=cut

sub set_ro_group {
    my ($self, @names) = @_;

    my @addresses;
    for my $name (@names) {
        confess "Computing element $name not configured!\n" unless defined($self->{elements}{$name});
        push(@addresses, $self->{elements}{$name});
    }
    $self->{'RO-GROUP'} = \@names;
    my $command = 'G' . join(';', @addresses) . '.';
    $self->{port}->write($command);
}

=head2 read_ro_group()

read_ro_group() reads all elements defined in a readout group. This minimizes the communications overhead between digital and 
analog computer and reduces the effect of jitter during readout as well as the risk of a serial line buffer overflow on the side of 
the hybrid controller. The function returns a reference to a hash containing the names of the elements forming the readout group 
with their associated values.

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

In addition to these analog readout capabilities, the hybrid controller also features eight digital inputs which can be used to read
the state of comparators or other logic elements of the analog computer being controlled. This method returns an array-reference 
containing values of 0 or 1 for each of the digital input ports.

=cut

# Read digital inputs
sub read_digital {
    my ($self) = @_;
    $self->{port}->write('R');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my $pattern = '^' . '\d+\s+' x (DIGITAL_INPUT_PORTS - 1) . '\d+';
    confess "Unexpected response: '$response', expected: '$pattern'" if $response !~ /$pattern/;
    return [ split(/\s+/, $response) ];
}

=head2 digital_output($port, $value)

The hybrid controller also features eight digital outputs which can be used to control the electronic switches which are part of the
comparator unit. Calling digital_output(0, 1) will set the first (0) digital output to 1 etc.

=cut

# Set/reset digital outputs
sub digital_output {
    my ($self, $port, $state) = @_;
    confess '$port must be >= 0 and < ' . DIGITAL_OUTPUT_PORTS if $port < 0 or $port > DIGITAL_OUTPUT_PORTS;
    $self->{port}->write(($state ? 'D' : 'd') . $port);
}

=head2 set_xbar()

set_xbar creates and sends a configuration bitstream to an XBAR-module specified by its name in the elements section of the 
configuration file. The routine is called like this:

    xbar(name, config-string);

where name is the name of the XBAR-module to be configured and config-string is a string describing the mapping of output lines to 
input lines at the XBAR. This string consists of 16 single hex digits or '-'. Each digit/'-' denotes one output of the XBAR-module, 
starting with output 0. An output denoted by '-' is disabled. 

To connect output 0 to input B and output 2 to input E while all other outputs are disabled, the following call would be issued:

xbar(name, 'B-E-------------');

=cut

sub _create_xbar_bitmap {
    my @data = split(//, $_[0]);
    confess "Not enough data. Got >>$_[0]<<." unless @data == 16;
    map { $_ = undef if $_ eq '-' }@data;

    my $connections;
    $connections .= defined($_) ? sprintf('1%04b', hex($_)) : '00000' for reverse(@data);

    my $config;
    for my $i (0 .. 3) { # Split $group into four 20 bit chunks and convert these 
        my $packet = substr($connections, $i * 20, 20);
        $config .= substr(sprintf("%08X", unpack('N', pack('B32', $packet))), 0, 5);
    }

    return $config;
}

sub set_xbar {
    my ($self, $name, $rest) = @_;
    confess "XBAR-module >>$name<< not defined!" unless defined($self->{elements}{$name});

    my $config = _create_xbar_bitmap($rest);

    my $address = sprintf('%04X', hex($self->{elements}{$name}));
    my $command = "X$address$config";
    $self->{port}->write($command);
    my $response = get_response($self); # Get response
    confess 'No response from hybrid controller!' unless $response;
    confess "Configuring XBAR failed: >>$response<<." unless $response eq 'XBAR READY';

    #  I am quite unhappy about the following two lines but as of now (20200116), I have no idea what causes the following problem:
    # After calling setup() which in turn calls set_xbar(), the first attempt to set a digital potentiometer by set_pt() fails
    # silently, i.e. has no effect at all. The following command sets a non-existing digital potentiometer to zero which basically
    # has no effect but causes all subsequent calls to set_pt() to succeed. This is only a workaround until I find the reason behind
    # this strange behaviour...
    $self->{port}->write('P0000000000');
    get_response($self), "\n";
}

=head2 read_mpts()

Calling read_mpts() returns a reference to a hash containing the current settings of all manual potentiometers listed in the 
'manual_potentiometers' section in the configuration file. To accomplish this, the analog computer is switched to POTSET-mode 
(implying HALT for the integrators). In this mode, all inputs of potentiometers are connected to the positive machine unit +1, so 
that their current setting can be read out. ("Free" potentiometers will behave erroneously unless their second input is connected 
to ground, refer to the analog computer manual for more information on that topic.)

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

To set a digital potentiometer, set_pt() is called. The first argument is the name of the the digital potentiometer to be set as 
specified in the elements section in the configuration YML-file (an entry like 'DPT24-2: 0060/2'). The second argument is a floating
point value 0 <= v <= 1. If the potentiometer to be set can not be found in the configuration data or if the value is out of bounds,
the function will die.

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
    $number  = sprintf('%02X', hex($number));  # Make sure we have a two digital pot number

    $self->{port}->write("P$address$number$value");

    my $response = get_response($self);      # Get response
    confess 'No response from hybrid controller!' unless $response;
    my ($raddress, $rnumber, $rvalue) = $response =~ /^P([^.]+)\.([^=]+)=(\d+)$/;
    confess "set_pt failed! $address vs. $raddress, $rnumber vs. $number, $value vs. $rvalue" 
        if (hex($address) != hex($raddress)) or (hex($number) != hex($rnumber)) or ($value != $rvalue);
}

=head2 read_dpts()

Read the current setting of all digital potentiometers. Caution: This does not query the actual potentiometers as there is not 
readout capability on the modules containing DPTs, instead this function will query the hybrid controller to return the values it 
has stored when DPTs were set.

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

Calling get_status() yields a reference to a hash containing all current status information of the hybrid controller. A typical 
hash structure returned may look like this:

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

In this case the IC-time has been set to 500 ms while the OP-time is set to one second. The analog computer is currently in 
HALT-mode and the hybrid controller is in its normal state, i.e. it is not currently performing a single- or repetitive-run. HALT 
on overload and external HALT are both disabled. A readout-group has been defined, too.

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

In some applications it is useful to be able to determine how long the analog computer has been in OP-mode. As time as such is the 
only free variable of integration in an analog-electronic analog computer, it is a central parameter to know. Imagine that some 
integration is being performed by the analog computer and the time which it took to reach some threshold value is of interest. In 
this case, the hybrid controller would be configured so that external-HALT is enabled. Then the analog computer would be placed to 
IC-mode and then to OP-mode. After an external HALT has been triggered by some comparator of the analog commputer, the hybrid 
controller will switch the analog computer to HALT-mode immediately. Afterwards, the time the analog computer spent in OP-mode can 
be determined by calling this method. The time will be returned in microseconds (the resolution is about +/- 3 to 4 microseconds).

=cut

# Get current time the AC spent in OP-mode
sub get_op_time {
    my ($self) = @_;
    $self->{port}->write('t');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    my $pattern = 't_OP=\-?\d*';
    confess "Unexpected response: '$response', expected: '$pattern'" if $response !~ /$pattern/;
    my ($time) = $response =~ /=\s*(\-?\d+)$/;
    return $time ? $time : -1;
}

=head2 reset()

The reset() method resets the hybrid controller to its initial setup. This will also reset all digital potentiometer settings 
including their number!  During normal operations it should not be necessary to call this method which was included primarily to 
aid debugging.

=cut

sub reset {
    my ($self) = @_;
    $self->{port}->write('x');
    my $response = get_response($self);
    confess 'No response from hybrid controller!' unless $response;
    confess "Unexpected response: '$response', expected: 'RESET'" if $response ne 'RESET';
}

=head2

store_data() stores data gathered from an analog computer run into a file. If no arguments are supplied, the data is read from the 
current object where it has to have been stored by previously invoking get_data().  

If external data and/or an external filename should be used these are expected as optional named parameters as in this example:

store_data(data => [...], filename => 'scratch.dat');

=cut

sub store_data {
    my ($self, %rest) = @_;

    my $data = defined($rest{data}) ? $rest{data} : $self->{data};
    confess 'No data to store!' if !defined($data) or @$data == 0;

    my ($filename, $handle);
    if (defined($rest{filename})) {
        $filename = $rest{filename};
        open($handle, '>', $filename) or confess "Could not create file $filename: $!\n";
    } else {
        $handle = File::Temp->new(UNLINK => 0, SUFFIX => '.dat');
        $filename = $handle; # It's a kind of magic :-)
    }

    for my $tupel (@$data) {
        if (ref($tupel) eq 'ARRAY') {
            print $handle join("\t", @$tupel), "\n";
        } else {
            print $handle "$tupel\n";
        }
    }

    close($handle);
    return $filename;
}

=head2

plot() uses gnuplot (which must be installed and be found in PATH) to plot data gathered by get_data(). If no argument is given, it 
uses the data stored in the ac-object. Otherwise, data can be given as an optional named parameter which consists of a reference to 
an array which either contains data values or arrays of data tuples in case multiple variables were logged during an analog computer
run:

plot(data => [...]);

If the data set to be plotted contains two element tuples, a phase space plot can be created by specifying the named parameter type:

plot(type => phase);

=cut

sub plot {
    my ($self, %rest) = @_;

    my $data = defined($rest{data}) ? $rest{data} : $self->{data};
    confess 'Nothing to plot - no data!' if !defined($data) or @$data == 0;
    my $columns = ref($data->[0]) eq 'ARRAY' ? @{$data->[0]} : 1;
    my $data_file = $self->store_data(data => $data);

    # Now create a control file for gnuplot
    confess "Data contains $columns-tuples which is not compatible with the option 'phase'!" 
        if defined($rest{type}) and $rest{type} eq 'phase' and $columns != 2;

    my $handle = File::Temp->new(UNLINK => 0, SUFFIX => '.dat');
    my $control_file = $handle; # Magic, again...
    if (defined($rest{type}) and $rest{type} eq 'phase') {
        print $handle "plot '$data_file' using 1:2 with lines title 'phase'\n";
    } else {
        print $handle 'plot ', join(', ', map{ "'$data_file' using $_ with lines title '$_'" }(1 .. $columns)), "\n";
    }
    close($handle);

    system("gnuplot $control_file");
    unlink($control_file);
    unlink($data_file);
}

=head2

setup() prepares a problem based on the information contained in the problem section of the configuration YAML-file. 

=cut

sub setup {
    my ($self, $xbar_address) = @_;

    confess 'Nothing to setup as no problem section has been defined!' unless defined($self->{problem});

    $self->reset();

    # Set times:
    $self->set_ic_time($self->{problem}{times}{ic}) if defined($self->{problem}{times}{ic});
    $self->set_op_time($self->{problem}{times}{op}) if defined($self->{problem}{times}{op});

    # Set initial conditions:
    for my $element (keys(%{$self->{problem}{IC}})) {
        my $value    = $self->{problem}{IC}{$element};
        my $sign     = $value !~ /^-/ or 0; # true -> negative initial condition
        my ($number) = $element =~ /^INT(\d+)ic/;
        $value = abs($value);

        confess "Could not determine number of digital output for setting IC for >>$element<<!" unless defined($number);
        confess "0 <= value <= 1 is not satisfied: value = >>$value<<!" if $value < 0 or $value > 1;

        $self->digital_output($number, $sign); # Determine the sign for the initial condition
        $self->set_pt($element, $value);
    }

    # Set coefficients:
    $self->set_pt($_, $self->{problem}{coefficients}{$_}) for keys(%{$self->{problem}{coefficients}});

    # Define read out group if specified:
    $self->set_ro_group(@{$self->{problem}{'ro-group'}}) if defined ($self->{problem}{'ro-group'});

    # Derive the required XBAR setup:
    if (defined($self->{problem})) {
        confess 'XBAR configuration not found!' unless defined($self->{xbar});
        confess 'No circuit description found!' unless defined($self->{problem}{circuit});

        my ($counter, %inputs, %outputs) = (0);
        $inputs{$_} = sprintf("%X", $counter++) for @{$self->{xbar}{input}};
        $counter = 0;
        $outputs{$_} = $counter++ for @{$self->{xbar}{output}};

        my @rows = split('', '-' x 16);
        for my $element (keys(%{$self->{problem}{circuit}})) {
            my $source = $inputs{$self->{problem}{circuit}{$element}};
            confess "Source $self->{problem}{circuit}{$element} not defined on XBAR!" unless defined($source);

            my $destination = $outputs{$element};
            confess "Destination $element not defined on XBAR!" unless defined($destination);

            $rows[$destination] = $source;
        }
        my $config_string = join('', @rows);
        $self->set_xbar($xbar_address, $config_string);
    }
}

=head1 Examples

The following example initates a repetitive run of the analog computer with 20 ms of operating time and 10 ms IC time:

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
