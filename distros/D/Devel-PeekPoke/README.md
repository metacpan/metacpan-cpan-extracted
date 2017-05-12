# NAME

Devel::PeekPoke - All your bytes are belong to us

# DESCRIPTION

This module provides a toolset for raw memory manipulation (both reading and
writing), together with some tools making it easier to examine memory chunks.

All provided routines expect memory addresses as regular integers (not as their
packed representations). Note that you can only manipulate memory of your
current perl process, this is __not__ a general memory access tool.

# PORTABILITY

The implementation is very portable, and is expected to work on all
architectures and operating systems supported by perl itself. Moreover no
compiler toolchain is required to install this module (in fact currently no
XS version is available).

In order to interpret the results, you may need to know the details of the
underlying system architecture. See [Devel::PeekPoke::Constants](https://metacpan.org/pod/Devel::PeekPoke::Constants) for some
useful constants related to the current system.

# USE RESPONSIBLY

It is apparent with the least amount of imagination that this module can be
used for great evil and general mischief. On the other hand there are some
legitimate uses, if nothing else as a learning/debugging tool. Hence this
tool is provided ( [with Larry Wall's blessing! ](http://groups.google.com/group/alt.hackers/msg/8ce9ba2e5554e8e6))
in the interest of free speech and all. The authors expect a user of this
module to exercise maximum common sense.



# EXPORTABLE FUNCTIONS

The following functions are provided, with ["peek"](#peek) and ["poke"](#poke) being
exported by default.

## peek

    my $byte_string = peek( $address, $size );

Reads and returns `$size` __bytes__ from the supplied address. Expects
`$address` to be specified as an integer.

## poke

    my $bytes_written = poke( $address, $bytes );

Writes the contents of `$bytes` to the memory location `$address`. Returns
the amount of bytes written. Expects `$bytes` to be a raw byte string, throws
an exception when (possible) characters are detected.

## peek\_address

    my $address = peek_address( $pointer_address );

A convenience function to retrieve an address from a known location of a
pointer. The address is returned as an integer. Equivalent to:

    unpack (
      Devel::PeekPoke::Constants::PTR_PACK_TYPE,
      peek( $pointer_address, Devel::PeekPoke::Constants::PTR_SIZE ),
    )

## poke\_address

    my $addr_size = poke_address( $pointer_address, $address_value );

A convenience function to set a pointer to an arbitrary address an address
(you need to ensure that `$pointer_address` is in fact a pointer).
Equivalent to:

    poke( $pointer_address, pack (
      Devel::PeekPoke::Constants::PTR_PACK_TYPE,
      $address_value,
    ));

## peek\_verbose

    peek_verbose( $address, $size )

A convenience wrapper around ["describe_bytestring"](#describe_bytestring). Equivalent to:

    print STDERR describe_bytestring( peek($address, $size), $address);

## describe\_bytestring

    my $desc = describe_bytestring( $bytes, $start_address )

A convenience aid for examination of random bytestrings. Useful for those of
us who are not skilled enough to read hex dumps directly. For example:

    describe_bytestring( "Har har\t\x13\x37\xb0\x0b\x1e\x55 !!!", 46685601519 )

    returns the following on a little-endian system (regardless of pointer size):

                 Hex  Dec  Oct    Bin     ASCII      32      32+2          64
                --------------------------------  -------- -------- ----------------
    0xadeadbeef   48   72  110  01001000    H     20726148          0972616820726148
    0xadeadbef0   61   97  141  01100001    a     ___/              _______/
    0xadeadbef1   72  114  162  01110010    r     __/      61682072 ______/
    0xadeadbef2   20   32   40  00100000  (SP)    _/       ___/     _____/
    0xadeadbef3   68  104  150  01101000    h     09726168 __/      ____/
    0xadeadbef4   61   97  141  01100001    a     ___/     _/       ___/
    0xadeadbef5   72  114  162  01110010    r     __/      37130972 __/
    0xadeadbef6   09    9   11  00001001  (HT)    _/       ___/     _/
    0xadeadbef7   13   19   23  00010011  (DC3)   0BB03713 __/      2120551E0BB03713
    0xadeadbef8   37   55   67  00110111    7     ___/     _/       _______/
    0xadeadbef9   B0  176  260  10110000  "\260"  __/      551E0BB0 ______/
    0xadeadbefa   0B   11   13  00001011  (VT)    _/       ___/     _____/
    0xadeadbefb   1E   30   36  00011110  (RS)    2120551E __/      ____/
    0xadeadbefc   55   85  125  01010101    U     ___/     _/       ___/
    0xadeadbefd   20   32   40  00100000  (SP)    __/      21212120 __/
    0xadeadbefe   21   33   41  00100001    !     _/       ___/     _/
    0xadeadbeff   21   33   41  00100001    !              __/
    0xadeadbf00   21   33   41  00100001    !              _/

# AUTHOR

ribasushi: Peter Rabbitson <ribasushi@cpan.org>

# CONTRIBUTORS

None as of yet

# COPYRIGHT

Copyright (c) 2011 the Devel::PeekPoke ["AUTHOR"](#author) and ["CONTRIBUTORS"](#contributors)
as listed above.

# LICENSE

This library is free software and may be distributed under the same terms
as perl itself.
