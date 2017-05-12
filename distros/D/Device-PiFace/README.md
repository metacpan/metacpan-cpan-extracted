# Name

Device::PiFace - Perl module to manage PiFace boards

# Synopsis

```perl
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
```

# Description

This module provides the functions and constants available in
[libpifacedigital](https://github.com/piface/libpifacedigital) and
[libmcp23s17](https://github.com/piface/libmcp23s17). In addition, an OO interface is provided,
which makes the module extremely easy to use.

The two libraries specified before are required to install and run this module. Instructions on
how this is done are available on the respective webpages.

# Methods

[Device::PiFace](https://metacpan.org/pod/Device::PiFace) implements the following methods.

## new

```perl
my $piface = Device::PiFace->new (%options);
```

Creates a new [Device::PiFace](https://metacpan.org/pod/Device::PiFace) instance.

`%options` may contain the following:

- `hw_addr => 0`

    The hardware address of your PiFace, specified using the on-board jumpers.

    If you have only one PiFace board, then this number is usually `0`.

    **This is required! The method will croak if this option is not specified.**

- `no_init => 0`

    If specified and true, this option disables the initialization of the PiFace board.

    **WARNING:** this requires the initialization to be performed manually.

## open

```perl
my $piface = Device::PiFace->open (%options);
```

Alias of ["new"](#new).

## close

```perl
$piface->close;
```

This method frees up resources associated with the current instance of [Device::PiFace](https://metacpan.org/pod/Device::PiFace).

It is automatically called when the instance of the class is being destroyed. This means that
in most cases it isn't necessary to call this method explicitly.

## read

```perl
my $val = $piface->read; # read from the register INPUT
$val = $piface->read (register => OUTPUT); # requires :piface_constants
$val = $piface->read (pin => 0);
$val = $piface->read (register => OUTPUT, pin => 0);
```

Reads a value from a register (by default `INPUT`). Accepts an hash containing:

- `register => INPUT`

    The register where the read operation is going to be performed.

    The value of this option must be one of the following constants:
    `INPUT`, `OUTPUT`, `IODIRA`, `IODIRB`, `IPOLA`, `IPOLB`, `GPINTENA`, `GPINTENB`,
    `DEFVALA`, `DEFVALB`, `INTCONA`, `INTCONB`, `IOCON`, `GPPUA`, `GPPUB`, `INTFA`,
    `INTFB`, `INTCAPA`, `INTCAPB`, `GPIOA`, `GPIOB`, `OLATA`, `OLATB`.

    Defaults to `INPUT` (`GPIOB`).

- `pin => 0`

    The pin number, used to obtain the value of a single pin (bit) instead of the whole register.

    The value of this option must be between `0` and `7` (inclusive).

**WARNING:** when `register` is `INPUT`, the bits of the resulting value are flipped.
This is because on the `INPUT` register an idle pin is represented with `1`, while an
active pin is represented with `0` (i.e., `0xFF` when no input is active).

## write

```perl
$piface->write (value => 0xFF); # write to the register OUTPUT
$piface->write (register => OUTPUT, value => 0xFF); # same as before
$piface->write (pin => 0, value => 1); # turns on pin 0
```

Writes a value to a register (by default `OUTPUT`). Accepts an hash containing:

- `register => OUTPUT`

    The register where the write operation is going to be performed.

    See ["read"](#read) for a list of possible values.

    Defaults to `OUTPUT` (`GPIOA`).

- `pin => 0`

    The pin number, used to change the value of a single pin instead of the whole register.

    The value of this option must be between `0` and `7` (inclusive).

## enable\_interrupts

```perl
$piface->enable_interrupts or die 'Something went wrong!';
```

Enables interrupts on this PiFace board.

Returns `1` on success.

**WARNING:** `pifacedigital_enable_interrupts()` returns `0` on success. This method returns
`1` on success, and an empty string on failure.

## disable\_interrupts

```perl
$piface->disable_interrupts or die 'Something went wrong!';
```

Disables interrupts on this PiFace board.

Returns `1` on success.

**WARNING:** `pifacedigital_disable_interrupts()` returns `0` on success. This method returns
`1` on success, and an empty string on failure.

## wait\_for\_input

```perl
my $success = $piface->wait_for_input;
my ($success, $value) = $piface->wait_for_input;
$piface->wait_for_input (timeout => 5000);
```

Waits for a change of any of the input pins on the PiFace board. Accepts an hash containing:

- `timeout => 1000`

    The maximum amount of time permitted for this operation, in milliseconds.

    A value of `-1` (which is the default) represents an infinite maximum waiting time.

In scalar context, it returns one of `R_SUCCESS`, `R_TIMEOUT`, `R_FAILURE` (`$success`).

In list context, it returns `$success` and the current state of all inputs (the equivalent of
a ["read"](#read) call).

Requires that interrupts are enabled with ["enable\_interrupts"](#enable_interrupts) first.

**WARNING:** this method blocks until an input pin changes, or the timeout is reached. Be careful.

# get\_mask

```perl
my $mask = $piface->get_mask (@pins);
```

Returns a mask usable with ["write"](#write), containing the pins specified in `@pins`.

**NOTE:** instead of doing this:

```perl
$piface->write (value => $piface->get_mask (qw(1 3 5 7)));
```

Do this!

```perl
$piface->write (value => 0b10101010);
```

# mask\_has\_pins

```perl
my $bool = $piface->mask_has_pins ($mask, @pins);
```

Checks if `$mask` contains `@pins`. Useful to check if a determined set of pins is currently
turned on:

```perl
printf "Pin 1, 5, 7 active? %s\n",
       $piface->mask_has_pins ($piface->read, qw(1 5 7)) ? "yes" : "no";
```

**NOTE:** you can do this by yourself if you have a mask representing the pins to check:

```perl
my $bool = ($mask & 0b10000001) == $mask; # pin 0 and 7 turned on?
```

# hw\_addr

```perl
my $hw_addr = $piface->hw_addr;
```

Retrieves the hardware address associated with this instance.

# fd

```perl
my $fd = $piface->fd;
```

Retrieves the file descriptor returned by `pifacedigital_open()`.

# A note about exportable constants and functions

You may export constants/functions either directly
(with `use Device::PiFace qw(CONST1 func1 ...)`) or using ["EXPORT TAGS"](#export-tags).
They are then usable without any prefix.

Otherwise, if you prefer to export nothing, you can refer to constants with

```perl
Device::PiFace->CONSTANT_NAME
```

And to functions with

```perl
Device::PiFace::function_name
```

This approach is useful to reduce namespace pollution, but it is uglier and longer to write.

# Export

None by default.

# Export tags

[Device::PiFace](https://metacpan.org/pod/Device::PiFace) specifies the following export tags:

- `:registers`

    This tag exports all the registers usable with ["read"](#read) and ["write"](#write).

    See ["read"](#read) for a list.

    **NOTE:** this does not include `INPUT` and `OUTPUT`! Use `:all_constants` or
    `:piface_constants` if you need these. You may also refer to them directly as
    explained in ["A NOTE ABOUT EXPORTABLE CONSTANTS AND FUNCTIONS"](#a-note-about-exportable-constants-and-functions).

- `:piface_constants`

    This tag exports all the constants sufficient for a basic usage of the
    object-oriented API of [Device::PiFace](https://metacpan.org/pod/Device::PiFace).

    ```perl
    INPUT
    OUTPUT
    R_SUCCESS
    R_TIMEOUT
    R_FAILURE
    ```

- `:mcp23s17_constants`

    This includes all the constants of `:registers`, plus:

    ```perl
    WRITE_CMD READ_CMD
    BANK_OFF BANK_ON
    INT_MIRROR_OFF INT_MIRROR_ON
    SEQOP_OFF SEQOP_ON
    DISSLW_OFF DISSLW_ON
    HAEN_OFF HAEN_ON
    ODR_OFF ODR_ON
    INTPOL_LOW INTPOL_HIGH
    GPIO_INTERRUPT_PIN
    ```

- `:all_constants`

    This includes all the constants of `:piface_constants` and `:mcp23s17_constants`.

- `:piface`

    This tag exports all the constants and functions necessary for a basic usage of the
    functional interface of [Device::PiFace](https://metacpan.org/pod/Device::PiFace) (`libpifacedigital`).
    It includes all the constants of `:piface_constants`, plus the following functions:

    ```perl
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
    ```

- `:mcp23s17`

    This tag exports all the constants and functions necessary to use the interface of `libmcp23s17`.
    It includes all the constants of `:mcp23s17_constants`, plus the following functions:

    ```perl
    mcp23s17_open
    mcp23s17_read_reg
    mcp23s17_write_reg
    mcp23s17_read_bit
    mcp23s17_write_bit
    mcp23s17_enable_interrupts
    mcp23s17_disable_interrupts
    mcp23s17_wait_for_interrupt
    ```

- `:all`

    This tag exports every function and constant of `libpifacedigital` and `libmcp23s17`.

# See also

[libpifacedigital](https://github.com/piface/libpifacedigital),
[libmcp23s17](https://github.com/piface/libmcp23s17),
[http://piface.github.io/](http://piface.github.io/)

# Author

Roberto Frenna (robertof AT cpan DOT org)

# Bugs

Please report any bugs or feature requests to
[https://github.com/Robertof/perl-device-piface](https://github.com/Robertof/perl-device-piface).

# License

Copyright (C) 2015, Roberto Frenna.

This program is free software, you can redistribute it and/or modify it under the terms of the
Artistic License version 2.0.
