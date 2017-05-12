package IO::Die;

use 5.006;
use strict;

#not in production
#use warnings;

=head1 NAME

IO::Die - Namespaced, error-checked I/O

=head1 VERSION

Version 0.057

=cut

our $VERSION = '0.057';

#----------------------------------------------------------------------
#PROTECTED

#Override in subclasses as needed
sub _CREATE_ERROR {
    shift;
    return shift() . ": " . join( ' ', map { defined() ? $_ : q<> } @_ );
}

sub _DO_WITH_ERROR { die $_[1] }

#----------------------------------------------------------------------
#PRIVATES

sub __THROW {
    my ( $NS, $type, @args ) = @_;

    $NS->_DO_WITH_ERROR(
        $NS->_CREATE_ERROR(
            $type,
            @args,
            OS_ERROR          => $!,
            EXTENDED_OS_ERROR => $^E,
        )
    );
}

sub __is_a_fh {
    my ($thing) = @_;

    my $is_fh;

    #Every file handle is a GLOB reference. This would be sufficient, except
    #GLOBs can also be symbol table references.
    if ( UNIVERSAL::isa( $thing, 'GLOB' ) ) {

        # You can’t tie() a symbol table reference, so if we’re tied(),
        # then this is a filehandle.
        #
        # If we’re not tied(), then we have to check fileno().
        $is_fh = ( tied *{$thing} ) || defined( CORE::fileno($thing) );
    }

    return $is_fh;
}

#----------------------------------------------------------------------

our $AUTOLOAD;
sub AUTOLOAD {
    $AUTOLOAD =~ s<.*::><>;

    local ($!, $^E);

    my $reldir = __PACKAGE__;
    $reldir =~ s<::></>g;

    require "$reldir/$AUTOLOAD.pm";

    return __PACKAGE__->can($AUTOLOAD)->(@_);
}

sub import {
    my ($class, @tags) = @_;

    for my $t (@tags) {
        if ($t eq ':preload') {
            $class->_preload();
        }
    }

    return;
}

sub _preload {
    my ($class) = @_;

    my $path = __FILE__;
    $path =~ s<\.pm\z><>;

    my $reldir = __PACKAGE__;
    $reldir =~ s<::></>g;

    $class->opendir( my $dh, $path );
    local ($!, $^E);
    while ( my $node = readdir $dh ) {
        next if substr( $node, -3 ) ne '.pm';
        require "$reldir/$node";
    }

    return;
}

1;

__END__

=pod

=encoding utf-8

=head1 SYNOPSIS

    use IO::Die;

    #Will throw on error:
    IO::Die->open( my $fh, '<', '/path/to/file' );
    IO::Die->print( $fh, 'Some output...' );
    IO::Die->close( $fh );

    #----------------------------------------------
    #...or, perhaps more usefully:

    package MyIO;

    use parent 'IO::Die';

    sub _CREATE_ERROR {
        my ( $NS, $type, %args ) = @_;

        return MyErrorClass->new( $type, %args );
    }

    sub _DO_WITH_ERROR {
        my ( $NS, $err ) = @_;  #$err is the result of _CREATE_ERROR() above

        return warn $err;
    }

    MyIO->open( .. );   #will warn() a MyErrorClass object on error

    #----------------------------------------------
    # You can also do:

    package MyDynamicIO;

    use parent 'IO::Die' qw(:preload);  #load everything at once

    sub new {
        #...something that sets an internal coderef “_create_err_cr”
    }

    sub _CREATE_ERROR {
        my ( $self, $type, %args ) = @_;
        return $self->{'_create_err_cr'}->($type, %args);
    }

    MyDynamicIO->sysopen( .. );     #uses “_create_err_cr” above

=head1 DETAILS

This module wraps most of Perl’s built-in I/O functions with code that
throws exceptions if the requested operation fails.
It confers many of C<autodie>’s benefits but with some distinctions
from that module that you may appreciate:

* C<IO::Die> does not overwrite Perl built-ins.

* C<IO::Die> does not clobber globals like $! and $^E.

* C<IO::Die> does not use function prototypes and does not export:
all calls into C<IO::Die> (or subclasses) “look like” what they are.

* C<IO::Die> does not try to impose its own error handling; you can customize
both how to represent errors and what to do with them.

* C<IO::Die> seems lighter than C<autodie> in simple memory usage checks. YMMV.

For the most part, you can simply replace:

    read( ... );

...with:

    IO::Die->read( ... );

This module, though, explicitly rejects certain “unsafe” practices that Perl
built-ins still support. Neither bareword file handles nor one-/two-arg
C<open()>, for example, are supported here--partly because it’s more
complicated to implement, but also because those patterns seem best avoided
anyway. Damian Conway’s “Perl Best Practices” and the present author’s
experience largely inform discernment of the above, which is admittedly
subjective by nature.

This module also rejects use of a single Perl command to operate on multiple
files, as e.g. Perl’s C<chmod()> allows. This is because that is the only
way to have reliable error checking, which is the whole point of this module.

Finally, since this doesn’t use function prototypes, some of the syntaxes
that Perl’s built-ins support won’t work here. You’ll likely find yourself
needing more parentheses here.

The intent, though, is that no actual functionality of Perl’s built-ins
is unimplemented; you may just need to rewrite your calls a bit
to have this module perform a given operation. For example:

    open( GLOBALS_R_BAD, '>somefile' );
    IO::Die->open( my $good_fh, '>', 'somefile');

    chown( $uid, $gid, qw( file1 file2 file 3 ) );
    IO::Die->chown( $uid, $gid, $_ ) for ( qw( file1 file2 file3 ) );

    print { $wfh } 'Haha';
    IO::Die->print( $wfh, 'Haha' );

(And, yes, unlike C<autodie>, C<IO::Die> has a C<print()> function!)

Most Perl built-ins that C<autodie> overrides have corresponding functions in this module.
Some functions, however, are not implemented here by design:

* C<readline()> and C<readdir()>: Perl’s built-ins do lots of "magic" (e.g.,
considering '0' as true in a C<while()>) that would be hard to implement.

* C<system()>: This one does a lot “under the hood”, and it’s not feasible
to avoid clobbering global $? if you use it.

* C<tell()> doesn’t write to $! and so can’t be error-checked.

* C<printf()> seems not to have much advantage over combining C<print()>
and C<sprintf()>. (?)

Some functions are thus far not implemented, including C<write()>, C<ioctl()>,
C<syscall()>, semaphore functions, etc. These can be implemented as needed.

=head1 PRELOADING

As of version 0.057, this module only loads in a stub at first; each I/O
method that you call from this module is then lazy-loaded. This is meant to
make this module use the least amount of memory possible.

If you want to load everything all at once (as 0.056 and prior versions did),
pass the C<:preload> tag when you C<use()> this module, e.g.:

    use IO::Die qw(:preload);

=head1 FUNCTIONS THAT DIFFER SIGNIFICANTLY FROM THEIR PERL BUILT-INS

The following are not complete descriptions of each function; rather,
this describes the B<differences> between the relevant Perl built-in and
C<IO::Die>’s wrapper of it. It is assumed that the reader is familiar
with the built-in form.

Note that NONE of the following functions support bareword filehandles.

=head2 open()

This supports all built-in forms of 3 or more arguments. It ONLY supports
the two-argument form when the second argument (i.e., the MODE) is “|-” or “-|”.

=head2 select()

Only the four-argument form is permitted.

=head2 chmod()

=head2 chown()

=head2 kill()

=head2 unlink()

=head2 utime()

Unlike Perl’s built-ins, these will only operate on one filesystem node at a time.
This restriction is necessary for reliable error reporting because Perl’s
built-ins have no way of telling us which of multiple filesystem nodes produced
the error.

=head2 exec()

This always treats the first argument as the program name, so if you do:

    IO::Die->exec('/bin/echo haha');

… that will actually attempt to execute a program named C<echo haha> in the
directory C</bin>, which probably isn’t what you wanted and will thus fail.
(In the above case, what was likely desired was:

    IO::Die->exec('/bin/echo', 'haha');

=head1 CONVENIENCE FUNCTIONS

=head2 systell( FILEHANDLE )

This function returns the unbuffered file pointer position.

=head1 FUNCTIONS THAT LARGELY MATCH THEIR RELEVANT PERL BUILT-INS

The remaining functions intend to match their corresponding Perl built-ins;
differences should be regarded as bugs to be fixed!

=head1 CUSTOM ERROR HANDLING

C<IO::Die>’s default error format is a rather primitive one that just
consists of the error parameters in a string. By default, this error is
thrown via Perl’s C<die()> built-in. If you need more
robust/flexible error handling, subclass this module, and override the
C<_CREATE_ERROR()> and/or C<_DO_WITH_ERROR> methods.

C<_DO_WITH_ERROR()> receives these parameters:

* The namespace

* The error (i.e., the error as returned by C<_CREATE_ERROR()>)

C<_CREATE_ERROR()> receives these parameters:

* The namespace.

* A name for the error type, e.g., “FileOpen”.

* A list of key/value pairs that describe the error.

The error types are proprietary to this module and listed below.

=head1 PROPRIETARY ERROR TYPES

Each error type always has the following attributes, which are the same values
as their corresponding variables as described in “perldoc perlvar”.

* OS_ERROR

* EXTENDED_OS_ERROR

Additional attributes for each type are listed below.

=over 4

=item Binmode           layer

=item Chdir             OPTIONAL: path

=item Chmod             permissions, path

=item Chown             uid, gid, path

=item Chroot            filename

=item Close

=item DirectoryClose

=item DirectoryCreate   path, mask

=item DirectoryDelete   path

=item DirectoryOpen     path

=item DirectoryRewind

=item Exec              path, arguments

=item Fcntl             function, scalar

=item FileOpen          mode, path; OPTIONAL: mask

=item Fileno

=item FileSeek          whence, position

=item FileTruncate

=item Flock             operation

=item Fork

=item Kill              signal, process

=item Link              oldpath, newpath

=item Pipe

=item Read              length

=item Rename            oldpath, newpath

=item ScalarOpen

=item Select

=item SocketAccept

=item SocketBind        name

=item SocketConnect     name

=item SocketGetOpt      level, optname

=item SocketListen      queuesize

=item SocketOpen        domain, type, protocol

=item SocketPair        domain, type, protocol

=item SocketReceive     length, flags

=item SocketSend        length, flags

=item SocketSetOpt      level, optname, optval

=item SocketShutdown    how

=item Stat              path

=item SymlinkCreate     oldpath, newpath

=item SymlinkRead       path

=item Unlink            path

=item Utime             atime, mtime; OPTIONAL: path

=item Write             length

=back

=head1 AUTHOR

Felipe Gasper, working for cPanel, Inc.

=head1 REPOSITORY

L<https://github.com/FGasper/io-die>

=head1 REPORTING BUGS

Open an issue at the GitHub URL above. Patches are welcome!

=head1 TODO

=over 4

=item * More tests.

=item * Reduce testing dependencies.

=item * Right now this B<kind> of works on Windows, but the tests use fork(),
so there all kinds of weird failures that, while they can happen in real code,
don’t really stem from this module.

=back

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc IO::Die

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Felipe Gasper.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut
