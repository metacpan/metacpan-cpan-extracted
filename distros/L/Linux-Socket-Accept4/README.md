[![Build Status](https://travis-ci.org/tokuhirom/Linux-Socket-Accept4.svg?branch=master)](https://travis-ci.org/tokuhirom/Linux-Socket-Accept4)
# NAME

Linux::Socket::Accept4 - accept4(2) bindings for Perl5

# SYNOPSIS

    use Linux::Socket::Accept4;

    accept4(CSOCK, SSOCK, SOCK_CLOEXEC);

# DESCRIPTION

Linux::Socket::Accept4 is a wrapper module for accept4(2).
This module is only available on GNU Linux.

accept4(2) is faster than accept(2) in some case.

# FUNCTIONS

- `my $peeraddr = accept4($csock, $ssock, $flags);`

    Accept a connection on a socket.

# CONSTANTS

All constants are exported by default.

- `SOCK_CLOEXEC`
- `SOCK_NONBLOCK`

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

- [reintroduce accept4](http://git.kernel.org/cgit/linux/kernel/git/torvalds/linux.git/commit/?id=de11defebf00007677fb7ee91d9b089b78786fbb)
- [accept4 in ruby](http://svn.ruby-lang.org/cgi-bin/viewvc.cgi?revision=33596&view=revision)
