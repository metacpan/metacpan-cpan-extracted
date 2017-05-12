package Device::PiFace;
use 5.010001;
use strict;
use warnings;
use constant {
    # pifacedigital_wait_for_input || Device::PiFace::wait_for_input return codes
    R_SUCCESS => 1,
    R_TIMEOUT => 0,
    R_FAILURE => -1
};
use parent "Exporter";
use Carp ();
require XSLoader;

our $VERSION = "0.01";

# Exporter configuration
# basic constants
our %EXPORT_TAGS = (
    registers => [ qw(
        IODIRA IODIRB IPOLA IPOLB GPINTENA GPINTENB DEFVALA DEFVALB INTCONA INTCONB
        IOCON GPPUA GPPUB INTFA INTFB INTCAPA INTCAPB GPIOA GPIOB OLATA OLATB
    ) ],
    piface_constants => [ qw(INPUT OUTPUT R_SUCCESS R_TIMEOUT R_FAILURE) ]
);
# mcp23s17 constants
$EXPORT_TAGS{mcp23s17_constants} = [
    @{$EXPORT_TAGS{registers}},
    qw(
        WRITE_CMD READ_CMD BANK_OFF BANK_ON INT_MIRROR_ON INT_MIRROR_OFF
        SEQOP_OFF SEQOP_ON DISSLW_ON DISSLW_OFF HAEN_ON HAEN_OFF
        ODR_ON ODR_OFF INTPOL_HIGH INTPOL_LOW GPIO_INTERRUPT_PIN
    ),
];
# all constants
$EXPORT_TAGS{all_constants} = [
    @{$EXPORT_TAGS{mcp23s17_constants}},
    @{$EXPORT_TAGS{piface_constants}}
];
# libpifacedigital methods & constants
$EXPORT_TAGS{piface} = [
    @{$EXPORT_TAGS{piface_constants}},
    map { "pifacedigital_$_" } qw(
        open open_noinit close read_reg write_reg read_bit write_bit digital_read
        digital_write enable_interrupts disable_interrupts wait_for_input
    )
];
# mcp23s17 methods & constants
$EXPORT_TAGS{mcp23s17} = [
    @{$EXPORT_TAGS{mcp23s17_constants}},
    map { "mcp23s17_$_" } qw(
        open read_reg write_reg read_bit write_bit
        enable_interrupts disable_interrupts wait_for_interrupt
    )
];
# everything
$EXPORT_TAGS{all} = [ @{$EXPORT_TAGS{piface}}, @{$EXPORT_TAGS{mcp23s17}} ];

our @EXPORT_OK = ( @{$EXPORT_TAGS{all}} );

XSLoader::load ("Device::PiFace", $VERSION);

# This AUTOLOAD is used to 'autoload' constants from the constant() XS function.
# Thanks to the author of Device::BCM2835.
sub AUTOLOAD
{
    our $AUTOLOAD;
    (my $constname = $AUTOLOAD) =~ s/.*:://;
    Carp::croak "Undefined subroutine \&$AUTOLOAD called" if $constname eq "constant";
    my ($error, $val) = constant ($constname);
    Carp::croak $error if $error;
    {
        no strict "refs";
        *$AUTOLOAD = sub { $val }
    }
    # Don't worry -- this isn't the goto you all are frightened about!
    # Check https://metacpan.org/pod/perlfunc#goto-NAME for further information.
    goto &$AUTOLOAD;
}

# OO interface
sub new
{
    my ($class, %options) = @_;
    Carp::croak "ERROR: missing 'hw_addr' param from Device::PiFace->new"
        unless exists $options{hw_addr};
    bless {
        %options,
        fd => $options{no_init} ?
                pifacedigital_open_noinit ($options{hw_addr}) :
                pifacedigital_open ($options{hw_addr})
    }, $class;
}

sub open { &new }

sub DESTROY
{
    shift->close
}

sub close
{
    my $self = shift;
    return if exists $self->{closed};
    $self->{closed} = 1;
    pifacedigital_close ($self->hw_addr)
}

# R/W stuff
# %args = (
#     register => OUTPUT, # optional, defaults to INPUT
#     pin => 1 # optional
# )
sub read
{
    my ($self, %args) = @_;
    $args{register} //= $self->INPUT;
    my $v = exists $args{pin}
      ? pifacedigital_read_bit ($args{pin}, $args{register}, $self->hw_addr)
      : pifacedigital_read_reg ($args{register}, $self->hw_addr);
    # flip the bits if $args{register} is INPUT
    $args{register} == $self->INPUT
      ? (exists $args{pin} ? 0x1 : 0xFF) ^ $v # $v is just one bit when $args{pin} exists
      : $v
}

# %args = (
#     value => 1, # required
#     register => OUTPUT, # optional, defaults to INPUT
#     pin => 1 # optional
# )
sub write
{
    my ($self, %args) = @_;
    Carp::croak "ERROR: missing 'value' param from Device::PiFace->write"
        unless exists $args{value};
    $args{register} //= $self->OUTPUT;
    exists $args{pin}
      ? pifacedigital_write_bit ($args{value}, $args{pin}, $args{register}, $self->hw_addr)
      : pifacedigital_write_reg ($args{value}, $args{register}, $self->hw_addr)
}

# Interrupt-related methods
sub enable_interrupts
{
    !pifacedigital_enable_interrupts()
}

sub disable_interrupts
{
    !pifacedigital_disable_interrupts()
}

# %args = (
#     timeout => n # optional, defaults to -1
# )
# returns @val = ($success, $value)
# $success is either R_SUCCESS, R_TIMEOUT or R_FAILURE
sub wait_for_input
{
    my ($self, %args) = @_;
    my $value = 0;
    my $success = pifacedigital_wait_for_input ($value, $args{timeout} // -1, $self->hw_addr);
    $value ^= 0xFF; # flip the bits
    wantarray ? ($success, $value) : $success
}

# Utilities
sub mask_has_pins
{
    my ($self, $mask, @pins) = @_;
    Carp::croak "You probably want to specify at least one pin to Device::PiFace->mask_has_pins."
        unless @pins;
    my $submask = $self->get_mask (@pins);
    ($mask & $submask) == $submask
}

# or, instead of using get_mask, just use 0bNNNNNNNN, replacing N with zero or one depending
# if you want the pin to be turned off or on. the least significant bit is equivalent to pin 0
# example: 0b10000001 has pin 0 and 7 turned on, and all the others off
sub get_mask
{
    my ($self, @pins) = @_;
    my $mask = 0;
    $mask |= 1 << $_ foreach @pins;
    $mask
}

# Accessors
sub fd
{
    shift->{fd}
}

sub hw_addr
{
    shift->{hw_addr}
}

1;
__END__

=head1 NAME

Device::PiFace - Perl module to manage PiFace boards

=head1 SYNOPSIS

  use Device::PiFace;
  # OO interface
  my $piface = Device::PiFace->new (hw_addr => 0);
  $piface->write (value => 0b10000001); # turn pin 0 and 7 on
  $piface->write (pin => 4, value => 1); # turn pin 4 on
  printf "Status of the inputs: %08b\n", $piface->read;
  printf "Input pin 3 is active? %s\n",
         $piface->mask_has_pins ($piface->read, 3) ? "yes" : "no";
  # libpifacedigital API
  # http://piface.github.io/libpifacedigital/pifacedigital_8h.html
  use Device::PiFace ':piface';
  pifacedigital_write_reg (0, OUTPUT, $hw_addr);
  # libmcp23s17 API
  # http://piface.github.io/libmcp23s17/mcp23s17_8h.html
  use Device::PiFace ':mcp23s17';
  mcp23s17_write_reg (0xFF, GPIOA, $hw_addr, $fd);

=head1 DESCRIPTION

This module provides the functions and constants available in
L<libpifacedigital|https://github.com/piface/libpifacedigital> and
L<libmcp23s17|https://github.com/piface/libmcp23s17>. In addition, an OO interface is provided,
which makes the module extremely easy to use.

The two libraries specified before are required to install and run this module. Instructions on
how this is done are available on the respective webpages.

=head1 METHODS

L<Device::PiFace> implements the following methods.

=head2 new

    my $piface = Device::PiFace->new (%options);

Creates a new L<Device::PiFace> instance.

C<%options> may contain the following:

=over 4

=item * C<< hw_addr => 0 >>

The hardware address of your PiFace, specified using the on-board jumpers.

If you have only one PiFace board, then this number is usually C<0>.

B<This is required! The method will croak if this option is not specified.>

=item * C<< no_init => 0 >>

If specified and true, this option disables the initialization of the PiFace board.

B<WARNING:> this requires the initialization to be performed manually.

=back

=head2 open

    my $piface = Device::PiFace->open (%options);

Alias of L</"new">.

=head2 close

    $piface->close;

This method frees up resources associated with the current instance of L<Device::PiFace>.

It is automatically called when the instance of the class is being destroyed. This means that
in most cases it isn't necessary to call this method explicitly.

=head2 read

    my $val = $piface->read; # read from the register INPUT
    $val = $piface->read (register => OUTPUT); # requires :piface_constants
    $val = $piface->read (pin => 0);
    $val = $piface->read (register => OUTPUT, pin => 0);

Reads a value from a register (by default C<INPUT>). Accepts an hash containing:

=over 4

=item * C<< register => INPUT >>

The register where the read operation is going to be performed.

The value of this option must be one of the following constants:
C<INPUT>, C<OUTPUT>, C<IODIRA>, C<IODIRB>, C<IPOLA>, C<IPOLB>, C<GPINTENA>, C<GPINTENB>,
C<DEFVALA>, C<DEFVALB>, C<INTCONA>, C<INTCONB>, C<IOCON>, C<GPPUA>, C<GPPUB>, C<INTFA>,
C<INTFB>, C<INTCAPA>, C<INTCAPB>, C<GPIOA>, C<GPIOB>, C<OLATA>, C<OLATB>.

Defaults to C<INPUT> (C<GPIOB>).

=item * C<< pin => 0 >>

The pin number, used to obtain the value of a single pin (bit) instead of the whole register.

The value of this option must be between C<0> and C<7> (inclusive).

=back

B<WARNING:> when C<register> is C<INPUT>, the bits of the resulting value are flipped.
This is because on the C<INPUT> register an idle pin is represented with C<1>, while an
active pin is represented with C<0> (i.e., C<0xFF> when no input is active).

=head2 write

    $piface->write (value => 0xFF); # write to the register OUTPUT
    $piface->write (register => OUTPUT, value => 0xFF); # same as before
    $piface->write (pin => 0, value => 1); # turns on pin 0

Writes a value to a register (by default C<OUTPUT>). Accepts an hash containing:

=over 4

=item * C<< register => OUTPUT >>

The register where the write operation is going to be performed.

See L</"read"> for a list of possible values.

Defaults to C<OUTPUT> (C<GPIOA>).

=item * C<< pin => 0 >>

The pin number, used to change the value of a single pin instead of the whole register.

The value of this option must be between C<0> and C<7> (inclusive).

=back

=head2 enable_interrupts

    $piface->enable_interrupts or die 'Something went wrong!';

Enables interrupts on this PiFace board.

Returns C<1> on success.

B<WARNING:> C<pifacedigital_enable_interrupts()> returns C<0> on success. This method returns
C<1> on success, and an empty string on failure.

=head2 disable_interrupts

    $piface->disable_interrupts or die 'Something went wrong!';

Disables interrupts on this PiFace board.

Returns C<1> on success.

B<WARNING:> C<pifacedigital_disable_interrupts()> returns C<0> on success. This method returns
C<1> on success, and an empty string on failure.

=head2 wait_for_input

    my $success = $piface->wait_for_input;
    my ($success, $value) = $piface->wait_for_input;
    $piface->wait_for_input (timeout => 5000);

Waits for a change of any of the input pins on the PiFace board. Accepts an hash containing:

=over 4

=item * C<< timeout => 1000 >>

The maximum amount of time permitted for this operation, in milliseconds.

A value of C<-1> (which is the default) represents an infinite maximum waiting time.

=back

In scalar context, it returns one of C<R_SUCCESS>, C<R_TIMEOUT>, C<R_FAILURE> (C<$success>).

In list context, it returns C<$success> and the current state of all inputs (the equivalent of
a L</"read"> call).

Requires that interrupts are enabled with L</"enable_interrupts"> first.

B<WARNING:> this method blocks until an input pin changes, or the timeout is reached. Be careful.

=head1 get_mask

    my $mask = $piface->get_mask (@pins);

Returns a mask usable with L</"write">, containing the pins specified in C<@pins>.

B<NOTE:> instead of doing this:

    $piface->write (value => $piface->get_mask (qw(1 3 5 7)));

Do this!

    $piface->write (value => 0b10101010);

=head1 mask_has_pins

    my $bool = $piface->mask_has_pins ($mask, @pins);

Checks if C<$mask> contains C<@pins>. Useful to check if a determined set of pins is currently
turned on:

    printf "Pin 1, 5, 7 active? %s\n",
           $piface->mask_has_pins ($piface->read, qw(1 5 7)) ? "yes" : "no";

B<NOTE:> you can do this by yourself if you have a mask representing the pins to check:

    my $bool = ($mask & 0b10000001) == $mask; # pin 0 and 7 turned on?

=head1 hw_addr

    my $hw_addr = $piface->hw_addr;

Retrieves the hardware address associated with this instance.

=head1 fd

    my $fd = $piface->fd;

Retrieves the file descriptor returned by C<pifacedigital_open()>.

=head1 A NOTE ABOUT EXPORTABLE CONSTANTS AND FUNCTIONS

You may export constants/functions either directly
(with C<use Device::PiFace qw(CONST1 func1 ...)>) or using L</"EXPORT TAGS">.
They are then usable without any prefix.

Otherwise, if you prefer to export nothing, you can refer to constants with

    Device::PiFace->CONSTANT_NAME

And to functions with

    Device::PiFace::function_name

This approach is useful to reduce namespace pollution, but it is uglier and longer to write.

=head1 EXPORT

None by default.

=head1 EXPORT TAGS

L<Device::PiFace> specifies the following export tags:

=over 4

=item * C<:registers>

This tag exports all the registers usable with L</"read"> and L</"write">.

See L</"read"> for a list.

B<NOTE:> this does not include C<INPUT> and C<OUTPUT>! Use C<:all_constants> or
C<:piface_constants> if you need these. You may also refer to them directly as
explained in L</"A NOTE ABOUT EXPORTABLE CONSTANTS AND FUNCTIONS">.

=item * C<:piface_constants>

This tag exports all the constants sufficient for a basic usage of the
object-oriented API of L<Device::PiFace>.

    INPUT
    OUTPUT
    R_SUCCESS
    R_TIMEOUT
    R_FAILURE

=item * C<:mcp23s17_constants>

This includes all the constants of C<:registers>, plus:

    WRITE_CMD READ_CMD
    BANK_OFF BANK_ON
    INT_MIRROR_OFF INT_MIRROR_ON
    SEQOP_OFF SEQOP_ON
    DISSLW_OFF DISSLW_ON
    HAEN_OFF HAEN_ON
    ODR_OFF ODR_ON
    INTPOL_LOW INTPOL_HIGH
    GPIO_INTERRUPT_PIN

=item * C<:all_constants>

This includes all the constants of C<:piface_constants> and C<:mcp23s17_constants>.

=item * C<:piface>

This tag exports all the constants and functions necessary for a basic usage of the
functional interface of L<Device::PiFace> (C<libpifacedigital>).
It includes all the constants of C<:piface_constants>, plus the following functions:

    pifacedigital_open
    pifacedigital_open_noinit
    pifacedigital_close
    pifacedigital_read_reg
    pifacedigital_write_reg
    pifacedigital_read_bit
    pifacedigital_write_bit
    pifacedigital_digital_read
    pifacedigital_digital_write
    pifacedigital_enable_interrupts
    pifacedigital_disable_interrupts
    pifacedigital_wait_for_input

=item * C<:mcp23s17>

This tag exports all the constants and functions necessary to use the interface of C<libmcp23s17>.
It includes all the constants of C<:mcp23s17_constants>, plus the following functions:

    mcp23s17_open
    mcp23s17_read_reg
    mcp23s17_write_reg
    mcp23s17_read_bit
    mcp23s17_write_bit
    mcp23s17_enable_interrupts
    mcp23s17_disable_interrupts
    mcp23s17_wait_for_interrupt

=item * C<:all>

This tag exports every function and constant of C<libpifacedigital> and C<libmcp23s17>.

=back

=head1 SEE ALSO

L<libpifacedigital|https://github.com/piface/libpifacedigital>,
L<libmcp23s17|https://github.com/piface/libmcp23s17>,
L<http://piface.github.io/>

=head1 AUTHOR

Roberto Frenna (robertof AT cpan DOT org)

=head1 BUGS

Please report any bugs or feature requests to
L<https://github.com/Robertof/perl-device-piface>.

=head1 LICENSE

Copyright (C) 2015, Roberto Frenna.

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.

=cut
