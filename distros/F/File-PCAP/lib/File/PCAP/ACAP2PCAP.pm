package File::PCAP::ACAP2PCAP;

use 5.006;
use strict;
use warnings;

use File::PCAP::Writer;
use Time::Local;

=head1 NAME

File::PCAP::ACAP2PCAP - convert ASA capture to PCAP

=head1 VERSION

Version v0.0.6

=cut

use version; our $VERSION = qv('v0.0.6');

=head1 SYNOPSIS

This module converts Cisco ASA packet capture outputs to PCAP files.

    use File::PCAP::ACAP2PCAP;

    my $a2p = File::PCAP::ACAP2PCAP->new( $args );

    $a2p->parse(\*STDIN);

=head1 SUBROUTINES/METHODS

=head2 new( $args )

Creates a new object, takes a hash reference as argument with
the following keys:

 my $a2p = File::PCAP::ACAP2PCAP( {
     dlt    => $dlt,                # data link type, see below
     output => $fname,              # filename for PCAP output
 } );

The data link type is put in the PCAP global header.
It defaults to 1 (Ethernet).
There are some versions of Cisco software that output raw IP headers.
For these use 101 (Raw IP) and for more information on data link types, see
L<http://www.tcpdump.org/linktypes.html>.

=cut

sub new {
	my ($self,$args) = @_;
	my $type = ref($self) || $self;
	
	my $now   = time;
	my @today = localtime($now);
	$today[0] = $today[1] = $today[2] = 0;

	my $fpwargs = {};
	if (exists $args->{dlt}) {
		$fpwargs->{dlt} = $args->{dlt};
	}
    if (exists $args->{output}) {
        $fpwargs->{fname} = $args->{output};
    }
    else {
        $fpwargs->{fname} = 'asa.pcap';
    }
	
	my $fpw = File::PCAP::Writer->new($fpwargs);
	
	$self = bless {
		state        => 'unknown',
		sot          => timelocal(@today), # start of today
		now          => $now,
		fpw          => $fpw,
		packet_bytes => "",
	}, $type;
	return $self;
} # new()

=head2 parse( $fd )

This function does the parsing of the ASA output from an IO stream.

To parse STDIN, you would do something like the following:

  $a2p->parse(\*STDIN);

To parse a file given by name, you open it and take the file handle:

  if (open(my $input,'<',$filename)) {
    $a2p->parse($input);
    close $input;
  }

To write the packets into the PCAP file this function uses
L<< File::PCAP::Writer->packet()|File::PCAP::Writer >>.

=cut

sub parse {
    my ($self,$fd) = @_;
    
    while (my $line = <$fd>) {
        $self->_read_line($line);
    }
	$self->_write_packet();
} # parse()

# internal functions and variables

my $r_strt = qr/^([0-9]+) packets? captured$/;
my $r_empt = qr/^$/;
my $r_dscr = qr/^\s*([0-9]+): ([0-9]{2}):([0-9]{2}):([0-9]{2})\.([0-9]+)\s+(.+)$/;
my $r_mdsc = qr/^\s+(\S.*)$/;
my $r_stop = qr/^([0-9]+) packets? shown$/;
my $r_dump = qr/^(0x[0-9a-f]+)\s+([0-9a-f][0-9a-f ]{38})\s{8}(.+)$/;

# The function _read_line() reads the input one line at a time and
# decides what to do with that line.
#
# The basic knowledge (a state machine driven by the input line) is encoded
# in the hash $states.
#
sub _read_line {
	my ($self,$line) = @_;
	my $states = {
		unknown => sub {
			return ($line =~ $r_strt) ? $self->_l_strt($1)
			     :                      'unknown'
			     ;
		},
		strt => sub {
			return ($line =~ $r_empt) ? 'strt'
			     : ($line =~ $r_dscr) ? $self->_l_dscr($1,$2,$3,$4,$5,$6)
			     :                      'unknown'
			     ;
		},
		dscr => sub {
			return ($line =~ $r_dscr) ? $self->_l_dscr($1,$2,$3,$4,$5,$6)
			     : ($line =~ $r_mdsc) ? $self->_l_mdsc($1)
			     : ($line =~ $r_dump) ? $self->_l_dump($1,$2,$3)
			     : ($line =~ $r_stop) ? $self->_l_stop()
                 : ($line =~ $r_empt) ? 'dump'
			     :                      'unknown'
			     ;
		},
		dump => sub {
			return ($line =~ $r_dump) ? $self->_l_dump($1,$2,$3)
			     : ($line =~ $r_dscr) ? $self->_l_dscr($1,$2,$3,$4,$5,$6)
			     : ($line =~ $r_stop) ? $self->_l_stop()
			     :                      'unknown'
			     ;
		},
		stop => sub {
			return                      'unknown';
		},
	};
	my $state = $self->{state};
	$self->{state} = $states->{$state}->($line);
	if ($self->{debug}) {
		print "$state -> $self->{state}: $line";
	}
} # _read_line()

# The _l_*() functions are called, when a corresponding regular
# expression $_r_* matches the input.
#
sub _l_strt {
	my ($self,$count) = @_;
	$self->{captured} = $count;
	return 'strt';
} # _l_strt()

sub _l_dscr {
	my ($self,$nr,$hour,$min,$sec,$usec,$dscr) = @_;
	$self->_write_packet();
	$self->{packet_number} = $nr;
	$self->{packet_dscr}   = $dscr;
	$self->{packet_secs}   = $self->{sot} + 3600 * $hour + 60 * $min + $sec;
	$self->{packet_usec}   = $usec;
	return 'dscr';
} # _l_dscr()

sub _l_mdsc {
	my ($self,$dscr) = @_;
	$self->{packet_dscr} .= " $dscr";
	return 'dscr';
} # _l_mdsc()

sub _l_dump {
	my ($self,$offset,$hex,$printable) = @_;
	my $bytes = $hex;
	$bytes =~ s/ //g;
	my $len = length $self->{packet_bytes};
	if ($len == 2 * hex($offset)) {
		$self->{packet_bytes} .= $bytes;
	} else {
		$len = sprintf( "0x%x", $len / 2);
		my $pn = $self->{packet_number};
		die "Bad things happened: have $len bytes and offset is $offset in packet $pn";
	}
	return 'dump';
} # _l_dump()

sub _l_stop {
	_write_packet(@_);
	return 'stop';
} # _l_stop()

# _write_packet() writes the actual datagram data including the packet
# header at the end of the PCAP file.
#
sub _write_packet {
	my ($self) = @_;
	if (my $len = length($self->{packet_bytes})) {
		my $sec  = $self->{packet_secs};
		my $usec = $self->{packet_usec};
		my $buf  = pack('H*', $self->{packet_bytes});
		$len /= 2;
		$self->{fpw}->packet($sec,$usec,$len,$len,$buf);
		$self->{packet_bytes}  = "";
	}
} # _write_packet()

=head1 SEE ALSO

Libpcap File Format
  L<https://wiki.wireshark.org/Development/LibpcapFileFormat>

Link-Layer Header Types
  L<http://www.tcpdump.org/linktypes.html>

=head1 AUTHOR

Mathias Weidner, C<< <mamawe at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-file-pcap at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-PCAP>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc File::PCAP

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
1; # End of File::PCAP
