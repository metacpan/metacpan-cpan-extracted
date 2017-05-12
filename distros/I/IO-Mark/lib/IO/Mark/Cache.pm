package IO::Mark::Cache;

use strict;
use warnings;
use Carp;

sub _new {
    my $class = shift;
    my $fh    = shift;

    return bless {
        fh        => $fh,
        buf       => '',
        eof       => 0,
        ref_count => 1,

        # Field we maintain on behalf of the IO::Mark::Buffer that gets
        # added to the master file handle
        master_pos => 0,
    }, $class;
}

sub _get_master_pos {
    my $self = shift;
    return $self->{master_pos};
}

sub _inc_master_pos {
    my $self = shift;
    my $inc  = shift;
    $self->{master_pos} += $inc;
}

sub _inc_ref_count {
    my $self = shift;
    return ++$self->{ref_count};
}

sub _dec_ref_count {
    my $self = shift;

    my $count = --$self->{ref_count};

    if ( $count == 0 ) {
        $self->{fh}->close;
    }

    return $count;
}

sub _read {
    my $self = shift;

    #    my ($buf, $len, $pos) = @_;

    my $got = 0;
    my $fh  = $self->{fh};

    # Only buffer if there is more than one handle watching
    if ( $self->{ref_count} > 1 && !$self->{eof} ) {
        my $want = ( $_[2] + $_[1] ) - length( $self->{buf} );
        if ( $want > 0 ) {
            my $got = $fh->read( $self->{buf}, $want, length( $self->{buf} ) );
            $self->{eof} = $want > $got;
        }
    }

    # How much in buffer?
    my $avail = length( $self->{buf} ) - $_[2];
    $avail = $_[1] if $avail > $_[1];

    # Read the data into the supplied buffer
    $_[0] = substr $self->{buf}, $_[2], $avail;
    $got = $avail;

    # If the buffer is exhausted but we're not at eof read some more.
    # Once we're in single watcher mode and the buffer is empty all
    # reads come straight here.
    if ( !$self->{eof} && $got < $_[1] ) {
        my $want = $_[1] - $got;
        my $got2 = $fh->read( $_[0], $want, length( $_[0] ) );
        $self->{eof} = $want > $got2;
        $got += $got2;
    }

    return $got;
}

1;

=head1 NAME

IO::Mark::Cache - Stream cache for IO::Mark

=head1 VERSION

This document describes IO::Mark version 0.0.1

=head1 SYNOPSIS

Don't use IO::Mark::Cache directly; it has no usable public interface.
Use instead L<IO::Mark>.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-io-mark@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Andy Armstrong  C<< <andy@hexten.net> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2007, Andy Armstrong C<< <andy@hexten.net> >>. All rights reserved.

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
