package Lchmod;

use strict;
use warnings;
use FFI::Me;

$Lchmod::VERSION = '0.02';

my $LCHMOD_AVAILABLE = 0;
sub LCHMOD_AVAILABLE { return 1 if $LCHMOD_AVAILABLE; return; }

sub import {
    shift;
    my $caller = caller;

    if (@_) {

        # TODO ?: warn if @_ contains someting other than lchmod or LCHMOD_AVAILABLE

        no strict 'refs';    ## no critic
        *{ $caller . "::lchmod" }           = \&lchmod           if grep m/^lchmod$/,           @_;
        *{ $caller . "::LCHMOD_AVAILABLE" } = \&LCHMOD_AVAILABLE if grep m/^LCHMOD_AVAILABLE$/, @_;
    }
    else {
        no strict 'refs';    ## no critic
        *{ $caller . "::lchmod" } = \&lchmod;
    }
}

{
    local $@;
    eval {                   # 1st: try current process
        ffi _sys_lchmod => (
            rv  => ffi::int,
            arg => [ ffi::str, ffi::int ],
            sym => 'lchmod',
        );
    };
    $LCHMOD_AVAILABLE = 1 if !$@;
}

# ? needed ?
# if (!$LCHMOD_AVAILABLE) {
#     local $@;
#     eval { # 2nd: try explicit libc
#         ffi _sys_lchmod => (
#             lib => $^O eq 'darwin' ? 'libc.dylib' : 'libc.so', # or whatever
#             rv  => ffi::int,
#             arg => [ffi::str,ffi::int],
#             sym => 'lchmod',
#         );
#     };
#     $LCHMOD_AVAILABLE = 1 if !$@;
# }

sub lchmod {
    my ( $mode, @files ) = @_;

    if ( !LCHMOD_AVAILABLE() ) {
        $! = _get_errno_func_not_impl();    # ENOSYS
        return undef;                       ## no critic
    }

    my $count = 0;
    my $normalized_mode = sprintf( "%04o", $mode & 07777 );    ## no critic

    for my $path (@files) {
        if ( -l $path ) {
            _sys_lchmod( $path, oct($normalized_mode) );
        }
        else {
            chmod( oct($normalized_mode), $path );
        }

        my $current_mode = ( lstat($path) )[2];
        next if !$current_mode;

        $current_mode = sprintf( "%04o", $current_mode & 07777 );    ## no critic
        $count++ if $current_mode eq $normalized_mode;
    }

    return $count;
}

sub _get_errno_func_not_impl {

    # we don't want to load POSIX but if its there we want to use it
    # CONSTANTs are weird when not defined so we have to:

    local $^W = 0;
    no warnings;
    no strict;    ## no critic
    my $posix = POSIX::ENOSYS;
    return
        $posix ne 'POSIX::ENOSYS' ? POSIX::ENOSYS
      : $^O =~ /linux/i           ? 38
      :                             78;
}

1;

__END__

=encoding utf-8

=head1 NAME

Lchmod - use the lchmod() system call from Perl

=head1 VERSION

This document describes Lchmod version 0.02

=head1 SYNOPSIS

    use Lchmod;

    chmod(0600, $symlink) || die "Could not chown “$symlink”: $!\n";

    # $symlink is 0777, its target is 0600

    lchmod(0644, $symlink) || die "Could not lchown “$symlink”: $!\n";

    # $symlink is 0644, its target remains at 0600

=head1 DESCRIPTION

Similar to L<Lchown> but for setting a symlink’s mode instead of uid/gid.

lchmod() behaves like chmod() except that when given a symlink it operates on the symlink instead of the target.

=head1 INTERFACE

=head2 lchmod()

Takes a mode and list of files (just like L<chmod()>).

Returns the count of items that were succesfully modified (just like L<chmod()>).

Returns undef and sets $! to ENOSYS (just like L<chmod()>) when the system does not support lchown.

It is automatically imported and importable (just like L<Lchown>).

=head2 LCHMOD_AVAILABLE()

Exportable availabilty–check similar to what L<Lchown> provides.

Takes no arguments, returns true when lchmod() is available, false when it is not.

=head1 DIAGNOSTICS

Throws no errors or warnings of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Lchmod requires no configuration files or environment variables.

=head1 DEPENDENCIES

L<FFI::Me>

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-lchmod@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2015, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.