package File::PCAP::Writer;

use 5.006;
use strict;
use warnings;

use Carp;

=head1 NAME

File::PCAP::Writer - write PCAP files with pure Perl

=head1 VERSION

Version v0.1.0

=cut

use version; our $VERSION = qv('v0.1.0');


=head1 SYNOPSIS

This module writes PCAP files that can be read with tcpdump or wireshark.

    use File::PCAP::Writer;

    my $fpw = File::PCAP::Writer->new( {
        fname => 'file.pcap',
        dlt => 1,
    } );

    $fpw->packet( $tsec, $usec, $blen, $plen, $buf );

=head1 SUBROUTINES/METHODS

=head2 new( $args )

Create a new File::PCAP::Writer object.

Parameter I<< $args >> is a reference to a hash, that may contain the
following keys:

=over 4

=item fname

The corresponding value is the name of the PCAP file.
It defaults to C<< file.pcap >> if the key is omitted.

The file is created and filled with a global PCAP header.
It can be immediately read by tcpdump.

=item dlt

The corresponding value is the data link type that is written in the global
PCAP header.
It defaults to 1 (LINKTYPE_ETHERNET) if the key is omitted.

See L<< http://www.tcpdump.org/linktypes.html >> for more information about
link-layer header type values.

Note that this is only a hint for tcpdump or wireshark at the type
of packets to expect in the PCAP file.
You are responsible to add datagram packets that match the link-layer header
type in the global PCAP header.

=back

=cut

sub new {
    my ($self,$args) = @_;
    my $type = ref($self) || $self;

    my $fname = $args->{fname} || "file.pcap";
    my $dlt   = $args->{dlt}   || 1;

    $self = bless {
        fname => $fname,
        dlt   => $dlt,
    }, $type;

    $self->_init();

    return $self;
} # new()

=head2 packet( $tsec, $usec, $blen, $plen, $buf )

Write a new datagram record at the end of the PCAP file.

The arguments are:

=over 4

=item I<< $tsec >>

The date and time for this packets.
This value is in seconds since January 1, 1970 00:00:00 GMT.

=item I<< $usec >>

The microseconds when this packet was captured as an offset to I<< $tsec >>.

=item I<< $blen >>

The number of bytes of the packet data saved in the file.

=item I<< $plen >>

The length of the packet as it appeared on the network.

=item I<< $buf >>

The actual packet data as a blob.
This buffer should contain at least I<< $blen >> bytes.

Note that this packet data should match the link-layer type in the global
PCAP header.

=back

=cut

sub packet {
    my ($self,$tsec,$usec,$blen,$plen,$buf) = @_;
    my $fname = $self->{fname};
    if (open(my $fh, '>>', $fname)) {
        my $header = pack("LLLL", $tsec, $usec, $blen, $plen);
        binmode $fh;
        print $fh $header;
        print $fh $buf;
        close $fh;
    }
    else {
        croak "Can't write packet data to file '$fname'";
    }
} # packet()

# internal functions

# _init() - initialize the object
#
sub _init {
    my ($self) = @_;

    if ($self->{fname}) {
        $self->_write_pcap_global_header();
    }
    else {
        croak "Need a filename to write PCAP data";
    }
} # _init()

# _write_pcap_global_header() - writes a PCAP global header to the file
#                               named in $self->{fname}
#
# This function writes a global header with PCAP version 2.4,
# the timezone is set to GMT(UTC), the accuracy of the timestamps is
# set to 0, the snapshot length to 65535
# The link-layer header type is set to $self->{dlt} or 1 (Ethernet).
#
sub _write_pcap_global_header {
    my ($self) = @_;
    my $dlt    = $self->{dlt};
    my $fname  = $self->{fname};
    if (open(my $fh, '>', $fname)) {
        my $header = pack("LSSlLLL", 0xa1b2c3d4, 2, 4, 0, 0, 65535, $dlt);
        binmode $fh;
        print $fh $header;
        close $fh;
    }
    else {
        croak "Can't write global header to file '$fname'";
    }
} # _write_pcap_global_header()

=head1 DIAGNOSTICS

=over 4

=item Can't write global header to file '$fname'

The program can't write to file I<< $fname >>.
This is the name of the file for the PCAP data.
If I<< $fname >> is C<< file.pcap >> than you probably have
not specified a file name explicitely.

This message appears at the time when the File::PCAP::Writer object
is created. It often hints at problems with file permissions.

=item Can't write packet data to file '$fname'

The program can't write to file I<< $fname >>.
This is the name of the file for the PCAP data.
If I<< $fname >> is C<< file.pcap >> than you probably have
not specified a file name explicitely.

This message appears when new packet data shall be written.
It often hints at problems with a lack of disk space.

=item  Need a filename to write PCAP data

Since there is a default value for the filename,
you probably have it overwritten with an empty filename
when calling C<< new() >>.

=back

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-pcap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-PCAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::PCAP::Writer


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
1; # End of File::PCAP::Writer
