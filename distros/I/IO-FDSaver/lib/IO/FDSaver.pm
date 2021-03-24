package IO::FDSaver;

use strict;
use warnings;

our $VERSION = '0.01';

=encoding utf-8

=head1 NAME

IO::FDSaver - Save file descriptors from Perl’s garbage collection.

=head1 SYNOPSIS

    my $saver = IO::FDSaver->new();

    my $fd_from_xsub = 5;

    # $fh can be garbage-collected, but Perl will never close FD 5.
    my $fh = $saver->get_fh( $fd_from_xsub );

=head1 DESCRIPTION

Perl’s ability to create a filehandle from a given file descriptor
is critical for advanced IPC functionality like accepting a file descriptor
across an C<exec()> or via UNIX socket (i.e., SCM_RIGHTS).

It’s also useful when interfacing with C libraries (i.e., via XSUBs), but
in this context there’s a catch: Perl expects to “own” all of its file
handles’ file descriptors. So if Perl garbage-collects its last file handle
that refers to a given file descriptor, Perl will close that file descriptor.
Thus, your C code—which has no idea there’s this Perl thing calling into
it—will suddenly start getting EBADF when trying to use its file
descriptors. These errors can be confusing and time-consuming to fix.

The present module solves this problem by retaining an index of file descriptors
and Perl file handles. As long as a given instance of this class survives,
Perl will never auto-close the file descriptors given to that object
because there will always remain at least one file handle that refers to each
file descriptor.

(NB: File descriptors I<not> given to such an object will behave as usual.)

=head1 METHODS

=head2 $obj = I<CLASS>->new()

Instantiates this class.

=cut

sub new { return bless {}, shift }

=head2 $fh = I<OBJ>->get_fh( $FD )

This module’s “workhorse” method: takes in a file descriptor and returns
a file handle for it.

The returned filehandle will be opened read/write—even if the underlying file
descriptor is read-only or write-only. The caller is expected to discipline
itself not to misuse the returned filehandle.

(There might be virtue in allowing a mode to pass to the underlying C<open()>;
file a feature request if you’d like that.)

=cut

sub get_fh {
    return $_[0]->{ $_[1] } = _create( $_[1] );
}

sub _create {

    # The mode doesn’t seem to make a difference as long as it
    # expresses read/write.
    open my $s, '+>>&=' . $_[0] or die "FD ($_[0]) to Perl FH failed: $!";

    $s;
}

=head1 AUTHOR & COPYRIGHT

Copyright 2021 Gasper Software Consulting

=head1 LICENSE

This library is licensed under the same license as Perl.

=cut

1;
