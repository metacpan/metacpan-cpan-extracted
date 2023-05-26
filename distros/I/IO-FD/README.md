# NAME

IO::FD - Faster accept, socket, listen with file descriptors, not handles

# SYNOPSIS

Create and bind a STREAM socket (server):

```perl
    use IO::FD;
    use Socket ":all";

    die "Error creating socket"
            unless IO::FD::socket(my $listen_fd, AF_INET, SOCK_STREAM, 0);

    my ($err, @sockaddr)=addrinfo "0.0.0.0", 80, {
            family=>        AF_INET,
            socktype=>      SOCK_STREAM,
            flags=>         AI_NUMERICHOST|AI_PASSIVE
    };

    die "Error binding"
            unless FD::IO::bind($listen_fd, $sockaddr[0]{addr});    

    
    die "Error accepting" 
            unless IO::FD::accept(my $client_fd, $listen_fd);
    
    #read and write here
    
```

Create and connect a STREAM socket(client):

```perl
    use IO::FD;
    use Socket ":all";

    die "Error creating socket"
            unless IO::FD::socket(my $fd, AF_INET,SOCK_STREAM,0);

    my ($err,@sockaddr)=addrinfo "127.0.0.1", 80, {
            family=>        AF_INET,
            socktype=>      SOCK_STREAM,
            flags=>         AI_NUMERICHOST
    };

    die "Error connecting";
            unless FD::IO::connect($fd, $sockaddr[0]{addr});

    #read and write here
```

Open a file

```perl
    use IO::FD;
    use Fcntl;
    die "could not open file" 
            unless IO::FD::sysopen(my $fd, "path.txt", O_RDONLY);
    
```

Read/Write/Close an fd

```perl
    use IO::FD;

    my $fd; #From IO::FD::socket, IO::FD::accept IO::FD::sysopen, POSIX::open

    die "Error writing"
            unless IO::FD::syswrite $fd, "This is some data"; #Length and optional offset

    die "Error reading"
            unless IO::FD::sysread $fd, my $buffer, $length); 

    die "Error closing" 
            unless IO::FD::close $fd;
```

Advanced:

```
      fcntl
sendfile
accept4
accept_multiple

      #TODO:
      ioctl...
```

# DESCRIPTION

IO::FD is an XS module implementing common core Perl system I/O functions to
work with **file descriptors** instead of Perl **file handles**. Functions
include but are not limited to `accept`, `connect`, `socket`, `bind`,
`sysopen`, `sysread`, and `syswrite`.

Many non core system functions such as `sendfile`, `dup` and `mkstemp`,
`pread`, `pwrite`, `mkfifo` which work with file descriptors are also
implemented.

Additional support for streamlined connection accepting is included via
`accept_multiple`.

This module can significantly lower memory usage per file descriptor and
decrease file/socket opening and socket accepting times.  `accept` performance
is particularly improved with much higher connection handling rates for a given
backlog.

Actual byte throughput (read/write) is basically unchanged compared to the core
Perl sysread/syswrite.  Please see the PERFORMANCE section later in this
document

The supported interfaces mostly resemble the core Perl implementations of similarly
named functions. 

For example:

```perl
    #Perl:
    sysopen(my $file_handle, ...);
    sysread($file_handle, ...);

    #IO::FD
    IO::FD::sysopen(my $file_descriptor, ...);
    IO::FD::sysread($file_descriptor, ...);
```

This modules **IS NOT** intended to be a drop in replacement for core IO
subroutines in existing code. If you want a 'drop in replacement' please look
at [IO::FD::DWIM](https://metacpan.org/pod/IO%3A%3AFD%3A%3ADWIM) which is part of the same distribution.

Currently this module is focused on UNIX/Linux systems, as this is the natural
habitat of a file descriptor.

# IMPORTANT VERSION DIFFERENCES

## v0.3.0 and later

**New functions:**

`pread`, `pwrite`, `mkfifo`, `mkfifoat`, `open`, `openat`

## v0.2.0 and later

**New functions:**

`accept4`, `accept_multiple`, `sendfile`

**Changes:**

All functions creating a new fd now behave more perlish and apply  O\_CLOEXEC if
larger than `$^F`  to prevent fd leakage.  This may result in an extra system
call you didn't need if your program never calls `exec`. To disable this,
increase the value of `$^F` as per normal.

Functions now throw **exceptions** when output variables (fds) are read only
when they need to be writable. This matches Perl behaviour in the same scenario
for `sysopen` etc.

When function input fd variables doesn't look like an fd (an IV), a **warning**
'IO::FD::xxxx called with something other than a file descriptor' is generated,
return value is `undef` and the `$!` variable is set to `EBADF` (bad file
descriptor>). This is analogous to Perl behaviour when checking for valid
GLOB/refs with `sysread` and friends.

# WHERE SHOULD I USE THIS MODULE?

## Networking ... Oh Yes

Socket centric programs will benefit greatly from this module. The process of
socket creation/opening/accepting/listening, where it is INET/INET6 or UNIX
families is much improved. 

## Slurp entire file ... Yes

If a file can be loaded completely into memory for processing, this module will
provide improved opening and closing times. Any decoding and line processing
will need to be done manually

## Line Processing ... Hmmm, No

General text file line processing is best left to Perl file handles. File
handles do the heavy lifting of line splitting, EOL handling, encodings, which
this modules does not implement.

You can do it, but it is not in the scope of this module.

# LIMITATIONS

Perl does a lot of nice things when working with files and handles. When using
file descriptors directly **you will loose**:

- Buffering for file small read/write performance (via print and <FH>)
- Automatic close when out of scope
- Special variables not supported (ie '\_' in stat)
- <FH> 'readline' support
- IO::Handle inheritance

# MOTIVATION

Perl makes working with text files easy, thanks to **file handles**.  Line
splitting, UTF-8, EOL processing etc. are awesome and make your life easier.

However, the benefits of file handles when working within a network or binary
file context are not so clear cut. All the nice line ending and encoding
support doesn't help in these scenarios.

In addition, the OS kernel does a lot of buffering for networking already. Do we
really need to add more?

So if these features are not being fully utilised for binary/network
programming, the hypothesis is that opening and accepting operations would be
faster with file descriptors as less setup is required internally.

# APIs

Each of the APIs mimic the Perl counterpart, if applicable, as much as
possible. Unless explicitly mentioned, they should operate like built in
routines.  Consult perldoc -f FUNCTION for details.

As none of these functions are exported, they must be called with full package
name.

## Socket Manipulation

### IO::FD::socket

### IO::FD::socketpair

### IO::FD::bind

### IO::FD::listen

### IO::FD::accept

### IO::FD::accept4

```perl
my $ok=IO::FD::accept4 $new, $listen, $flags;

Constants: IO::FD::SOCK_NONBLOCK, IO::FD::SOCK_CLOEXEC
```

Implements the linux  `accept4` syscall. On non linux systems this is emulated
by calling `fcntl` to set the FD\_CLOEXEC flag and O\_NONBLOCK status. Returns
`undef` on error, for the user to test `$!`. 

The flags argument can be the bitwise or'ed value of `SOCK_NONBLOCK` and
`SOCK_CLOEXEC` from the [Socket](https://metacpan.org/pod/Socket) module on linux and bsd.  Darwin (macos)
does not have these values. so please use `IO::FD::SOCK_NONBLOCK`,
`IO::FD::SOCK_CLOEXEC` on that platform.

**NOTE:**Unlike other functions returning new file descriptors, this **DOES NOT**
automatically apply the CLOEXEC flag. The `$flags` argument must be set
accordingly to achieve this.

**NOTE:** On emulated systems, any errors reported are only from the accept
call, not subsequent `fcntl` calls

### IO::FD::accept\_multiple

```perl
    my @new_fds;
    my @peers;
    my $count=accept_multiple(@new_fds, @peers, $listen_sock);
```

**NOTE:** DO NOT use this function on a blocking socket!!

Accepts as many new connection sockets as available. The new sockets are stored
in `new_fds`, which is an array, not a array ref. The corresponding peers to
the connections are stored in `@peers`, also an array not a reference.

`$listen_sock` is the file descriptor from which  the sockets are accepted
from. It **MUST** be configured for non blocking  operation, otherwise your
program will just loop forever in this function

Because this function will only works for non blocking listening sockets, 
**the sockets/fds returned are configured for non blocking mode also**. 
On BSD type systems the socket will already be non blocking. On linux systems
the accept4 call is used to set the SOCK\_NONBLOCK flag.

Returns the number of sockets accepted until an error condition occurred.
Returns `undef` if no sockets where accepted. Check the `$!` for normal non
blocking error codes.

### IO::FD::connect

### IO::FD::getsockopt

### IO::FD::setsockopt

Note: Implements the integer shorthand as per perldoc -f setsockopt

### IO::FD::getpeername

### IO::FD::getsockname

### IO::FD::sendfile

```
sendfile $socket, $source_fd, $length, $offset
```

Calls system sendfile. Returns `undef` on error or the number of bytes
transferred otherwise. The error might be an **EAGAIN** for non blocking
sockets. Please reference the manual page for sendfile on your system, but be
mindful the position of the arguments might not match.

Currently advanced header/trailer features of BSD sendfile are not supported.

## File Maniupulation

### IO::FD::sysopen

### IO::FD::sysopen4

Same as `IO::FD::sysopen`, but expects all four arguments

### IO::FD::open

Binding to `open`. Please see your system manual. If no mode is specified,
the 'perlish' 0666, is used.

### IO::FD::openat

Binding to `openat`. Please see your system manual. If no mode is specified,
the 'perlish' 0666, is used.

### IO::FD::mktemp

Behaves similar to [File::Temp::mktemp](https://metacpan.org/pod/File%3A%3ATemp%3A%3Amktemp)

Requires at least six 'X' characters at the end of the template

The template string used as input is modified  and is the same as the return
value on success

**NOTE:** This function does not return a file descriptor. It might be included in
future versions of this module

### IO::FD::mkstemp

Behaves like [File::Temp::mkstemp](https://metacpan.org/pod/File%3A%3ATemp%3A%3Amkstemp)

Requires at least six 'X' characters at the end of the template

In list context returns `($fd,$path)`, where `$fd` is the already open file
descriptor, and `$path` is the unique path generated from the template.

The template string used as input is modified  and is the same as the `$path`
return value on success

### IO::FD::sysseek

## Pipes

### IO::FD::pipe

### IO::FD::syspipe

A alias of `IO::FD::pipe`.

### mkfifo

Binding to `mkfifo`. Please see your system manual. If no mode is specified,
the 'perlish' 0666, is used.

### mkfifoat

Binding to `mkfifoat`. Please see your system manual. If no mode is specified,
the 'perlish' 0666, is used.

## Common

### IO::FD::dup

### IO::FD::dup2

### IO::FD::close

### IO::FD::recv

### IO::FD::send

### IO::FD::sysread

**NOTE:** Versions prior to 0.1.4 would end up using fd = 0 (normally STDIN)
when it was non numeric.  This is fixed in 0.1.4. An fd which is not numeric
will cause an immediate return of undefined.

### IO::FD::sysread3

Same as `IO::FD::sysread`, but expects only 3 of 4 arguments

### IO::FD::sysread4

Same as `IO::FD::sysread`, but expects all four arguments

### IO::FD::syswrite

**NOTE:** Versions prior to 0.1.4 would end up using fd = 0 (normally STDIN)
when it was non numeric.  This is fixed in 0.1.4. An fd which is not numeric
will cause an immediate return of undefined.

### IO::FD::syswrite2

Same as `IO::FD::syswrite`, but expect 2 of 4 arguments.

### IO::FD::syswrite3

Same as `IO::FD::syswrite`, but expect 3 of 4 arguments.

### IO::FD::syswrite4

Same as `IO::FD::syswrite`, but expect 4 of 4 arguments.

### IO::FD::fcntl

### IO::FD::sysfcntl

Alias to `IO::FD::fcntl`

### IO::FD::stat

Likely differences to Perl stat for larger integer values.

TODO: fix this!

### IO::FD::lstat

Likely differences to Perl lstat for larger integer values

TODO: fix this!

### IO::FD::pread

Binding to `pread`. Please see your system manual.

### IO::FD:pwrite

Binding to `pwrite`. Please see your system manual.

## Experimental

These functions haven't really been tested, documented or finished. They exist
none the less.  You will need to Look at the code for documentation at the
moment. Their behaviour and interface are LIKELY TO CHANGE without notice.

### IO::FD::ioctl

Not complete

### IO::FD::sysioctl

Alias to ioctl

### IO::FD::clock\_gettime\_monotonic

### IO::FD::select

Broken. Probably will be removed as core Perl has this already.

### IO::FD::poll

Constants for use with poll are available via  `IO::FD:Constants`

### IO::FD::kqueue

### IO::FD::kevent

This is broken ok 32 bit BSD at the moment.
Constants for use with kevent are available via  `IO::FD:Constants`

### IO::FD::pack\_kevent

### IO::FD::sv\_to\_pointer

### IO::FD::pointer\_to\_sv

### IO::FD::SV

```
    IO::FD::SV($size)
```

Allocates a string SV with the given size preallocated. The current string
length is set to 0. For short string this is not the fastest way to allocate.
For 4k and above, it is much faster, and doesn't use extra memory in
compilation

### IO::FD::readline

```perl
    #SLURP A FILE
    local $/=undef;
    my $slurp=IO::FD::readline;

            #or
    #SLURP ALL RECORDS OF KNOWN LENGTH
    local $/=\1234;
    my @records=IO::FD::readline;
```

A read line function is available, but is only operates in file slurp or record
slurp mode (see perldoc -f readline). As no buffering is used, It does not
attempt to split lines or read a line at a time like the normal Perl readline
or  <> operator

# PERFORMANCE

Part of this distribution are benchmarking scripts. The following are typical
outputs from my Intel 2020 Macbook Pro.

## Listen Backlog

Results from benchmark/server-perl.pl benchmark/server.pl and benchmark/client.pl

```perl
    Listen Backlog: 10
            Perl server:
            Connections before client refused: 18

            IO::FD server
            Connections before client refuse: 9285

    Listen Backlog: 100
            Perl server:
            Connections before client refused: 190

            IO::FD server
            Connections before client refuse:  (none refused)

    Listen Backlog: 1000

            Perl server:
            Connections before client refused: 245

            IO::FD server
            Connections before client refuse:  (none refused)
```

## Accept 

Results from benchmark/server-perl.pl benchmark/server.pl and benchmark/client.pl

```
    Listen Backlog: 100
    
    Perl accept rate:    73568.4857256754/s
    IO::FD Accept rate: 150984.798776367/s
    
```

## Memory Usage

Results from benchmark/file-memory.pl

```
    Creating 2000 file handles/descriptors
    Start maxrss (kB): 4500

    Perl file handles
    Bytes: 905216, per handle: 452.608

    IO::FD
    Bytes: 4096, per fd: 2.048

    End maxrss (kB): 5692
```

## Socket creation 

Results from benchmark/socket-create.pl

```
                         Rate perl_socket_INET iofd_socket_INET
    perl_socket_INET  81919/s               --             -56%
    iofd_socket_INET 185679/s             127%               --
                          Rate perl_socket_INET6 iofd_socket_INET6
    perl_socket_INET6  81498/s                --              -57%
    iofd_socket_INET6 189253/s              132%                --
                         Rate perl_socket_UNIX iofd_socket_UNIX
    perl_socket_UNIX 113778/s               --             -78%
    iofd_socket_UNIX 508970/s             347%               --
```

## File open and close

Results from benchmark/file-open-close.pl

```
                        Rate     file_handle file_desc_posix           io_fd
    file_handle      91897/s              --            -35%            -37%
    file_desc_posix 140549/s             53%              --             -4%
    io_fd           146161/s             59%              4%              --
```

## Read Performance

Result from benchmark/file-read-write.pl

```
    Read performance:
    Read (bytes): 1024 x 2^0
                         Rate file_desc_posix     file_handle           io_fd
    file_desc_posix 1803743/s              --             -5%             -5%
    file_handle     1889325/s              5%              --             -0%
    io_fd           1890461/s              5%              0%              --
    Read (bytes): 1024 x 2^1
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1799026/s              --             -1%             -2%
    io_fd           1823610/s              1%              --             -1%
    file_handle     1837458/s              2%              1%              --
    Read (bytes): 1024 x 2^2
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1731140/s              --             -1%             -1%
    io_fd           1747626/s              1%              --             -0%
    file_handle     1747627/s              1%              0%              --
    Read (bytes): 1024 x 2^3
                         Rate           io_fd file_desc_posix     file_handle
    io_fd           1458670/s              --             -1%             -3%
    file_desc_posix 1470359/s              1%              --             -2%
    file_handle     1499189/s              3%              2%              --
    Read (bytes): 1024 x 2^4
                         Rate file_desc_posix     file_handle           io_fd
    file_desc_posix 1146879/s              --             -3%             -6%
    file_handle     1180322/s              3%              --             -3%
    io_fd           1214700/s              6%              3%              --
```

## Write Performance

Result from benchmark/file-read-write.pl

```
    Write performance:
    Write (bytes): 1024 x 2^0
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1978800/s              --             -7%            -12%
    io_fd           2117316/s              7%              --             -6%
    file_handle     2244774/s             13%              6%              --
    Write (bytes): 1024 x 2^1
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 2007408/s              --             -6%             -9%
    io_fd           2143700/s              7%              --             -3%
    file_handle     2205537/s             10%              3%              --
    Write (bytes): 1024 x 2^2
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1978800/s              --             -7%            -12%
    io_fd           2123851/s              7%              --             -5%
    file_handle     2244774/s             13%              6%              --
    Write (bytes): 1024 x 2^3
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1960478/s              --             -7%             -9%
    io_fd           2117316/s              8%              --             -2%
    file_handle     2163924/s             10%              2%              --
    Write (bytes): 1024 x 2^4
                         Rate file_desc_posix           io_fd     file_handle
    file_desc_posix 1997468/s              --             -5%             -8%
    io_fd           2104367/s              5%              --             -3%
    file_handle     2163924/s              8%              3%              --
```

# SEE ALSO

The [POSIX](https://metacpan.org/pod/POSIX) module provides an `open`, `close`, `read` and `write`
routines which return/work with file descriptors. If you are only concerned
with working with files, this is a better option as it is a core module, and
will give you the purported benefits of this module.  However it does not
provide any networking/socket support.

# FUTURE WORK (IDEAS/TODO)

```perl
Further emulate linux/bsd SOCK_NONBLOCK and SOCK_CLOEXEC on darwin
      Add more tests for stat and DWIM module
      Wider compatability for older Perls
      Add More system functions which work with fds
      Work with win32 sockets
      Maybe make an IO::Handle sub class
```

# AUTHOR

Ruben Westerberg, <drclaw@mac.com>

# REPOSITORTY and BUGS

Please report any bugs via git hub: [http://github.com/drclaw1394/perl-io-fd](http://github.com/drclaw1394/perl-io-fd)

# COPYRIGHT AND LICENSE

Copyright (C) 2023 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

# DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.
