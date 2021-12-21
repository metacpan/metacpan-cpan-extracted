package File::PCAP::Reader;

use 5.006;
use strict;
use warnings;

use Carp;
use File::PCAP;

=head1 NAME

File::PCAP::Reader - read PCAP files with pure Perl

=head1 VERSION

Version v0.1.1

=cut

use version; our $VERSION = qv('v0.1.1');


=head1 SYNOPSIS

This module reads PCAP files that are written with tcpdump.

    use File::PCAP::Reader;

    my $fpr = File::PCAP::Reader->new( $fname );

    my $gh = $fpr->global_header();

    my $tsec = $fpr->next_packet();

=head1 SUBROUTINES/METHODS

=head2 new( $fname )

Open a PCAP file and read it's global header.

=cut

sub new {
    my ($self,$fname) = @_;
    my $type = ref($self) || $self;

    $self = bless {
        fname => $fname,
    }, $type;

    $self->_init();

    return $self;
} # new()

=head2 global_header()

Return a reference to a hash that contains the data of the global header of
the PCAP file.

This hash contains the following keys:

=over 4

=item magic_number

The magic number 0xa1b2c3d4 or 0xa1b23c4d for nanosecond-resolution files.

At the moment this version of the library does not handle files from
architectures with a different byte ordering.

=item version_major

The major version number.

=item version_minor

The minor version number.

=item thiszone

The GMT to local time correction.

=item sigfigs

The accuracy of the timestamps in the file.

=item snaplen

The maximum length of the captured packets in octets.

=item network

The data link type of the packets in this file.

=back

=cut

sub global_header {
    my $self = shift;
    return $self->{global_header};
} # global_header()

=head2 link_layer_header_type()

Returns either the link type name of the global header field I<network> or its numerical value.

=cut

sub link_layer_header_type {
    my $self = shift;
    my $llht = $self->{global_header}->{network};
    if ( defined $File::PCAP::linktypes->{$llht} ) {
        return $File::PCAP::linktypes->{$llht}->[1];
    }
    else {
        return $llht;
    }
} # link_layer_header_type()

=head2 next_packet()

Read the next datagram record in the PCAP file.

Returns a hash reference containing the data of the next packet
or nothing at the end of the PCAP file.

This hash contains the following keys

=over 4

=item I<< ts_sec >>

The date and time when this packet was captured.
This value is in seconds since January 1, 1970 00:00:00 GMT.

=item I<< ts_usec >>

The microseconds when this packet was captured as an offset to I<< ts_sec >>.

=item I<< incl_len >>

The number of octets of packet data saved in the file.

=item I<< orig_len >>

The length of the packet as it appeared on the network when it was captured.

=item I<< buf >>

The actual packet data as a blob.
This buffer should contain at least I<< inc_len >> bytes.

=back

You may want to use it like this:

  while(my $np = $fpr->next_packet()) {
    # ... do something with $np
  }

=cut

sub next_packet {
    my ($self) = @_;
    my $fh = $self->{fh};
    my $record;
    my $rr = read($fh, $record, 16);
    if (not defined $rr) {
        croak "Can't read packet data from file '$!'";
    }
    elsif (16 > $rr) {
        if ($rr) {
            carp "Reached EOF before reading packet header!";
        }
        return;
    }
    my ($ts_sec,$ts_usec,$incl_len,$orig_len) = unpack("LLLL",$record);
    my $buf;
    $rr = read($fh, $buf, $incl_len);
    if (not defined $rr) {
        croak "Can't read packet data from file '$!'";
    }
    if ($incl_len > $rr) {
        carp "Reached EOF before reading packet buffer!";
        return;
    }
    return {
        ts_sec   => $ts_sec,
        ts_usec  => $ts_usec,
        incl_len => $incl_len,
        orig_len => $orig_len,
        buf      => $buf,
    }
} # next_packet()

# internal functions

# _init() - initialize the object
#
sub _init {
    my ($self) = @_;

    my $fname = $self->{fname};
    if ($fname) {
        if (open(my $fh, '<', $fname)) {
            binmode $fh;
            $self->{fh} = $fh;
            $self->_read_pcap_global_header();
        }
        else {
            croak "Can't open file '$fname' for reading";
        }
    }
    else {
        croak "Need a filename to read PCAP data from";
    }
} # _init()

sub DESTROY {
    my $self = shift;

    close($self->{fh}) if ($self->{fh});
    delete $self->{fh};
} # DESTROY()

# _read_pcap_global_header() - reads a PCAP global header from the file
#                              named in $self->{fname}
#
# This function reads a global header with PCAP version 2.4.
#
sub _read_pcap_global_header {
    my ($self) = @_;
    my $fh = $self->{fh};
    my $data;
    unless (24 == read($fh, $data, 24)) {
        croak "Couldn't read global header of PCAP file";
    }
    my ($magic,$vmajor,$vminor,$tzone,$sigfigs,$snaplen,$dlt) = unpack("LSSlLLL",$data);

    if (0xa1b2c3d4 == $magic || 0xa1b23c4d == $magic) {
        if (2 != $vmajor or 4 != $vminor) {
            croak "Can't handle file version $vmajor.$vminor"
        }
        $self->{global_header} = {
            magic_number    => $magic,
            version_major   => $vmajor,
            version_minor   => $vminor,
            thiszone        => $tzone,
            sigfigs         => $sigfigs,
            snaplen         => $snaplen,
            network         => $dlt,
        };
    }
    else {
        my $hex = sprintf("%x", $magic);
        croak "Don't know how to handle file with magic number 0x$hex";
    }
} # _read_pcap_global_header()

=head1 DIAGNOSTICS

=over 4

=item  Need a filename to read PCAP data from

You need to specify a filename with the constructor.

=item Can't open file '$fname' for reading

The file you specified with C<< $fname >> is not readable.

=item Don't know how to handle file with magic number 0xaabbccdd

The magic number in the first 4 bytes of a PCAP file is 0xa1b2c3d4.
This number is used to detect the file format itself and the byte ordering.

At the moment this module just handles PCAP files with the same byte order as the computer this program is running on.

=item Can't handle file version $vmajor.$vminor

At the moment this module just handles PCAP file version 2.4.

=item Can't read packet data from file '$!'

There was a problem reading the packet data from the file.

=item Reached EOF before reading packet header!

The file reached EOF while trying to read the last packet header.

This may be a hint to a shortened file.

=item Reached EOF before reading packet buffer!

The file reached EOF while trying to read the last packet buffer.

This may be a hint to a shortened file.

=back

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-pcap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-PCAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::PCAP::Reader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-PCAP>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/File-PCAP>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/File-PCAP>

=item * Search CPAN

L<http://search.cpan.org/dist/File-PCAP/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2017 Mathias Weidner.

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

# vim: set sw=4 ts=4 et:
1; # End of File::PCAP::Reader
