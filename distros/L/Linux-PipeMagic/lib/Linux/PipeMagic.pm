package Linux::PipeMagic;

use 5.010001;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Linux::PipeMagic ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	systee
    syssplice
    syssendfile
    SPLICE_F_MOVE
    SPLICE_F_NONBLOCK
    SPLICE_F_MORE
    SPLICE_F_GIFT
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.05';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Linux::PipeMagic::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Linux::PipeMagic', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

Linux::PipeMagic - Perl extension to use the zero copy IO syscalls

=head1 SYNOPSIS

  use Linux::PipeMagic qw/ systee syssplice syssendfile /;
  systee($fh_in, $fh_out, $num_bytes, 0);
  syssplice($fh_in, $fh_out, $num_bytes, 0);
  syssendfile($fh_out, $fh_in, $num_bytes);

=head1 DESCRIPTION

Linux::PipeMagic is a Perl XS wrapper around the L<splice(2)>, L<tee(2)> and L<sendfile(2)>
syscalls.  You can use them to efficiently copy data from one file descriptor to
another inside the kernel (splice), or to efficiently copy data from one pipe
to another (tee).

=head1 FUNCTIONS

=over

=item sysplice($fh_in, $fh_out, $num_bytes, $flags)

Copies C<$num_bytes> from C<$fh_in> to C<$fh_out>.  This is roughly equivalent to,

    sysread($fh_in, my $buf, $num_bytes);
    syswrite($fh_out, $buf);

although the transfer takes place entirely in kernel space.

Returns the number of bytes transferred.

=item systee($fh_in, $fh_out, $num_bytes, $flags)

Copies C<$num_bytes> from C<$fh_in> to C<$fh_out>.  The filehandles must both
be of type pipe.  This works similarly like C<syssplice> but does not advance the
read pointer in C<$fh_in>.

Returns the number of bytes transferred.

=item syssendfile($fh_out, $fh_in, $num_bytes)

Copies C<$num_bytes> from C<$fh_in> to C<$fh_out>.  With current versions of
Linux, C<$fh_in> must be a file opened for reading, and C<$fh_out> must be a
writable socket.  Note the different order of parameters compared to the other
functions.

=back

=head1 CONSTANTS

=over

=item *
SPLICE_F_MOVE

=item *
SPLICE_F_NONBLOCK

=item *
SPLICE_F_MORE

=item *
SPLICE_F_GIFT

=back

=head1 CAVEATS

Only Linux is supported, on other OSs the calls will fail with C<ENOSYS> and
the constants will not be available. L<tee(2)> and L<splice(2)> syscalls only
exist on Linux. L<sendfile(2)> is provided by the BSDs, however it takes different
parameters to the Linux call.

=head1 SEE ALSO

=over

=item *
L<http://github.com/davel/Linux-PipeMagic/>

=back

See the Linux manpages for more details on how splice and tee can be used,
including the flags.

=over

=item *
L<splice(2)>

=item *
L<tee(2)>

=item *
L<sendfile(2)>

=back

=head1 AUTHOR

Dave Lambley, E<lt>dlambley@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2011, 2012, 2022 by Dave Lambley

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
