# NAME

Linux::PacketFilter - Simple interface to Linux packet filtering

# SYNOPSIS

    # Reject any packet that starts with a period:
    my $filter = Linux::PacketFilter->new(

        # Load the accumulator with the 1st byte in the packet:
        [ 'ld b abs', 0 ],

        # If the accumulator value is an ASCII period, continue;
        # otherwise, skip a line.
        [ 'jmp jeq k', ord('.'), 0, 1 ],

        # If we continued, we’ll get here and thus reject the packet.
        [ ret => 0 ],

        # If we get here, we skipped a line above. That means
        # the packet’s first byte wasn’t an ASCII period,
        # so we'll return the full packet.
        [ ret => 0xffffffff ],
    );

    $filter->apply( $socket );

# DESCRIPTION

This module is a simple, small, pure-Perl compiler for Linux’s
“classic” Berkeley Packet Filter (BPF) implementation.

# HOW TO USE THIS MODULE

If you’re familiar with BPF already, the SYNOPSIS above should mostly make
sense “out-of-the-box”. If you’re new to BPF, though, take heart; it’s
fairly straightforward.

The best source I have found for learning about BPF itself is
[bpf(4) in the BSD man pages](https://man.openbsd.org/bpf.4#Filter_machine);
see the section entitled **FILTER MACHINE**.

Linux-specific implementation notes are available in the kernel
source tree at [/Documentation/networking/filter.txt](https://www.kernel.org/doc/Documentation/networking/filter.txt). This contains a lot of detail
about uses for BPF that don't pertain to packet filtering, though.

[Here is another helpful guide.](https://web.archive.org/web/20130125231050/http://netsplit.com/2011/02/09/the-proc-connector-and-socket-filters/) Take
especial note of the need to convert between network and host byte order.
(See below for a convenience that this module provides for this conversion.)

You might also take interest in [the original BPF white paper](http://www.tcpdump.org/papers/bpf-usenix93.pdf).

**NOTE:** This module works with Linux’s _“classic”_ BPF, not the
much more powerful (and complex) “extended” BPF.

# METHODS

## $obj = _CLASS_->new( @filters )

Creates an object that represents an array of instructions for
the BPF filter machine. Each @filters member is an array reference
that represents a single instruction and has either 2 or 4 members,
which correspond with the BPF\_STMT and BPF\_JUMP macros, respectively.

The first member of each array reference is, rather than a number,
a space-separated string of options, lower-cased and without the
leading `BPF_`. So where in C you would write:

    BPF_LD | BPF_W | BPF_ABS

… in this module you write:

    'ld w abs'

The full list of options for a single instruction is:

- `b`, `h`, `w`
- `x`, `k`, `k_n`, `k_N` (See below for
an explanation of the last two.)
- `ld`, `ldx`, `st`, `stx`, `alu`, `jmp`, `ret`, `misc`
- `imm`, `abs`, `ind`, `mem`, `len`, `msh`
- `add`, `sub`, `mul`, `div`, `or`, `and`, `lsh`, `rsh`,
`neg`, `mod`, `xor`
- `ja`, `jeq`, `jgt`, `jge`, `jset`

### Byte order conversion

Since it’s common to need to do byte order conversions with
packet filtering, Linux::PacketFilter adds a convenience for this:
the codes `k_n` and `k_N` indicate to encode the given constant value
in 16-bit or 32-bit network byte order, respectively. These have the same
effect as calling `htons(3)` and `htonl(3)` in C.

**NOTE:** Linux’s exact behavior regarding byte order in BPF isn’t
always clear, and this module is only tested thus far on little-endian
systems. It seems that only certain operations, like `jeq`, require the
conversion.

## $ok = _OBJ_->attach( $SOCKET )

Attaches the filter instructions to the given $SOCKET.

Note that this class purposely omits public access to the value that
is given to the underlying [setsockopt(2)](http://man.he.net/man2/setsockopt) system call. This is because
that value contains a pointer to a Perl string. That pointer is only valid
during this object’s lifetime, and bad stuff (e.g., segmentation faults)
can happen when you give the kernel pointers to strings that Perl has
already garbage-collected.

The return is the same as the underlying call to Perl’s
["setsockopt" in perlfunc](https://metacpan.org/pod/perlfunc#setsockopt) built-in. `$!` is set as that function leaves it.

# AUTHOR

Copyright 2019 Gasper Software Consulting ([http://gaspersoftware.com](http://gaspersoftware.com))

# SEE ALSO

[Linux::SocketFilter::Assembler](https://metacpan.org/pod/Linux::SocketFilter::Assembler) suits a similar purpose to this
module’s but appears to be geared solely toward PF\_PACKET sockets.
It also defines its own language for specifying the filters, which I find
less helpful than this module’s approach of “porting” the C macros
to Perl, thus better capitalizing on existing documention.
