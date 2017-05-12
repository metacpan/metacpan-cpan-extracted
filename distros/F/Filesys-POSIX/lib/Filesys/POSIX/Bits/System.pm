# Copyright (c) 2014, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

package Filesys::POSIX::Bits::System;

use strict;
use warnings;

use Fcntl ();
use Filesys::POSIX::Bits;

=head1 NAME

Filesys::POSIX::Bits::System - Bitfield and constant conversions for file modes
and system call flags to system values

=head1 DESCRIPTION

This file contains functions to convert the values of bitfields and constants
from the values defined in C<Filesys::POSIX::Bits> to the values used by the
system, defined in C<Fcntl>.  Only exported values are supported.

The following (unexported) functions are provided:

=over

=item C<convertFlagsToSystem($flags)>

Converts the constants beginning with 'C<$O_>' to their values on the current
system.  These constants are generally used in the C<$flags> field of
C<sysopen>.

Values that are not supported by this system will throw a warning and will be
left out of the returned value.  The flags must include an access mode (e.g.
C<$O_RDONLY>, C<$O_WRONLY>, xor C<$O_RDWR>) in addition to any other values
desired.  If an access mode is not provided or its value is unknown to
C<Filesys::POSIX::Bits>, then the function will die.

Note that C<$O_EVTONLY> is specific to this module and unsupported by C<Fcntl>.
Trying to convert it to a system value will result in a warning.

=cut

sub convertFlagsToSystem {
    my $value = shift;
    my $out;

    # Handle access modes first
    my $access = $value & $Filesys::POSIX::Bits::O_MODE;
    if ( $access == $O_RDWR ) {
        $out = &Fcntl::O_RDWR;
    }
    elsif ( $access == $O_WRONLY ) {
        $out = &Fcntl::O_WRONLY;
    }
    elsif ( $access == $O_RDONLY ) {
        $out = &Fcntl::O_RDONLY;
    }
    else {
        die "Unknown access mode: $access";
    }

    $out |= _getOrWarn('O_APPEND')   if $value & $O_APPEND;
    $out |= _getOrWarn('O_CREAT')    if $value & $O_CREAT;
    $out |= _getOrWarn('O_EXCL')     if $value & $O_EXCL;
    $out |= _getOrWarn('O_EXLOCK')   if $value & $O_EXLOCK;
    $out |= _getOrWarn('O_NOFOLLOW') if $value & $O_NOFOLLOW;
    $out |= _getOrWarn('O_NONBLOCK') if $value & $O_NONBLOCK;
    $out |= _getOrWarn('O_SHLOCK')   if $value & $O_SHLOCK;
    $out |= _getOrWarn('O_TRUNC')    if $value & $O_TRUNC;

    warn "O_EVTONLY is not supported by Fcntl" if $value & $O_EVTONLY;

    return $out;
}

=item C<convertModeToSystem($mode)>

Converts the constants beginning with 'C<$S_I>' to their values on the current
system.  These constants are generally used in the C<$mode> field of C<sysopen>
and in the C<$mode> field of C<stat>.

File types that are not supported by this system will throw a warning and will
be left out of the returned value.  The mode may include zero or one file type
(values beginning with C<$S_IF>), but not more.  If a file type unknown to
C<Filesys::POSIX::Bits> is provided, then the function will die.

=cut

sub convertModeToSystem {
    my $value = shift;

    my $out = 0;

    # Convert file types (system support may vary)
    my $type = $value & $S_IFMT;
    if ($type) {
        my $name;
        $name = 'S_IFIFO'  if $type == $S_IFIFO;
        $name = 'S_IFCHR'  if $type == $S_IFCHR;
        $name = 'S_IFDIR'  if $type == $S_IFDIR;
        $name = 'S_IFBLK'  if $type == $S_IFBLK;
        $name = 'S_IFREG'  if $type == $S_IFREG;
        $name = 'S_IFLNK'  if $type == $S_IFLNK;
        $name = 'S_IFSOCK' if $type == $S_IFSOCK;
        $name = 'S_IFWHT'  if $type == $S_IFWHT;
        die "Unknown file type: $type" if !$name;

        $out = _getOrWarn($name);
    }

    # Convert permissions
    $out |= &Fcntl::S_IRUSR if $value & $S_IRUSR;
    $out |= &Fcntl::S_IWUSR if $value & $S_IWUSR;
    $out |= &Fcntl::S_IXUSR if $value & $S_IXUSR;
    $out |= &Fcntl::S_IRGRP if $value & $S_IRGRP;
    $out |= &Fcntl::S_IWGRP if $value & $S_IWGRP;
    $out |= &Fcntl::S_IXGRP if $value & $S_IXGRP;
    $out |= &Fcntl::S_IROTH if $value & $S_IROTH;
    $out |= &Fcntl::S_IWOTH if $value & $S_IWOTH;
    $out |= &Fcntl::S_IXOTH if $value & $S_IXOTH;

    # Convert sticky bits
    $out |= &Fcntl::S_ISUID if $value & $S_ISUID;
    $out |= &Fcntl::S_ISGID if $value & $S_ISGID;
    $out |= &Fcntl::S_ISVTX if $value & $S_ISVTX;

    return $out;
}

=item C<convertWhenceToSystem($whence)>

Converts the constants beginning with 'C<$SEEK_>' to their values on the
current system.  These constants are generally used in the C<$whence> field
of C<sysseek>.

If a value unknown to C<Filesys::POSIX::Bits> is provided, then the function
will die.

=cut

sub convertWhenceToSystem {
    my $value = shift;

    if ( $value == $SEEK_SET ) {
        return &Fcntl::SEEK_SET;
    }
    elsif ( $value == $SEEK_CUR ) {
        return &Fcntl::SEEK_CUR;
    }
    elsif ( $value == $SEEK_END ) {
        return &Fcntl::SEEK_END;
    }
    else {
        die "Unknown whence value: $value";
    }
}

=back

=cut

# Private function that either returns the requested value from Fcntl or
# throws a warning.  If a warning is thrown, the value 0 is returned.
sub _getOrWarn {
    my $var = shift;

    my $value = eval("\&Fcntl::$var") || 0;
    warn "$var is not supported by this system" if $@;

    return $value;
}

1;

=head1 DIAGNOSTICS

=over

=item I<CONSTANT> is not supported by this system

The system's Fcntl does not have a value defined for the given I<CONSTANT> and
thus it can't (and won't) be converted.

=item I<CONSTANT> is not supported by Fcntl

The Fcntl module does not define the given I<CONSTANT> and thus it can't (and
won't) be converted.

=item Unknown access mode: I<flag>

The access mode provided does not match C<$O_RDONLY>, C<$O_WRONLY>, xor
C<$O_RDWR>; or an access mode was not provided at all.

=item Unknown file type: I<mode>

The optional file type component that was provided does not match one of:
C<$S_IFIFO>, C<$S_IFCHR>, C<$S_IFDIR>, C<$S_IFBLK>, C<$S_IFREG>, C<$S_IFLNK>,
C<$S_IFSOCK>, xor C<$S_IFWHT>.

=item Unknown whence value: I<whence>

The whence value provided was not one of: C<$SEEK_SET>, C<$SEEK_CUR>, xor
C<$SEEK_END>.

=back

=head1 KNOWN ISSUES

=over

=item SEEK_END is assumed to exist

The C<Fcntl> value C<SEEK_END> is assumed to exist when it is not specified
by POSIX, but is rather an almost ubiquitously supported extension.

=back

=head1 AUTHORS

=over

=item Rikus Goodell <rikus.goodell@cpanel.net>

=item Brian Carlson <brian.carlson@cpanel.net>

=back

=head1 COPYRIGHT

Copyright (c) 2014, cPanel, Inc.  Distributed under the terms of the Perl
Artistic license.
