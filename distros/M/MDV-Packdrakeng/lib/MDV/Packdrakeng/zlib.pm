##- Nanar <nanardon@mandrake.org>
##-
##- This program is free software; you can redistribute it and/or modify
##- it under the terms of the GNU General Public License as published by
##- the Free Software Foundation; either version 2, or (at your option)
##- any later version.
##-
##- This program is distributed in the hope that it will be useful,
##- but WITHOUT ANY WARRANTY; without even the implied warranty of
##- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##- GNU General Public License for more details.
##-
##- You should have received a copy of the GNU General Public License
##- along with this program; if not, write to the Free Software
##- Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

#- This package provides functions to use Compress::Zlib instead of gzip.

package MDV::Packdrakeng::zlib;

use strict;
use Compress::Zlib;
use base qw(MDV::Packdrakeng);

(our $VERSION) = q($Id: zlib.pm 225628 2007-08-09 11:00:15Z nanardon $) =~ /(\d+)/;

my $gzip_header = pack("C" . 10,
    31, 139, 
    8, 0,0,0,0,0,0, 3);

# true if wrapper writes directly in archive and not into temp file
sub direct_write { 1; }

sub method_info { "internal zlib $VERSION" }

sub compress_handle {
    my ($pack, $sourcefh) = @_;
    my ($insize, $outsize) = (0, 0); # aka uncompressed / compressed data length

    # If $sourcefh is not set, this means we want a flush(), for end_block()
    # EOF, flush compress stream, adding crc
    if (!defined($sourcefh)) {
        return(undef, $pack->compress_data());
    }

    binmode $sourcefh;
    while (my $lenght = sysread($sourcefh, my $buf, $pack->{bufsize})) {
        my $wres = $pack->compress_data($buf);
        $outsize += $wres;
        $insize += $lenght;
    }

    ($insize, $outsize)
}

sub compress_data {
    my ($pack, $data) = ($_[0], \$_[1]);
    my $outsize = 0;
    if (! defined($$data)) {
        if (defined($pack->{cstream_data}{object})) {
            my ($cbuf, $status) = $pack->{cstream_data}{object}->flush();
            $outsize += syswrite($pack->{handle}, $cbuf);
            $outsize += syswrite($pack->{handle}, pack("V V", $pack->{cstream_data}{crc}, $pack->{cstream_data}{object}->total_in()));
        }
        $pack->{cstream_data} = undef;
        return($outsize);
    }
    
    if (!defined $pack->{cstream_data}{object}) {
        # Writing gzip header file
        $outsize += syswrite($pack->{handle}, $gzip_header);
	$pack->{cstream_data}{object} = deflateInit(
	    -Level         => $pack->{level},
	    # Zlib does not create a gzip header, except with this flag
	    -WindowBits    =>  - MAX_WBITS(),
	);
    }
        
    $pack->{cstream_data}{crc} = crc32($$data, $pack->{cstream_data}{crc});
    my ($cbuf, $status) = $pack->{cstream_data}{object}->deflate($$data);
    my $wres = syswrite($pack->{handle}, $cbuf) || 0;
    $wres == length($cbuf) or do {
	$pack->{destroyed} = 1;
        die "Can't push all data to compressor\n";
    };
    $outsize += $wres;
    return($outsize);
}

sub uncompress_handle {
    my ($pack, $destfh, $fileinfo) = @_;

    if (!defined $fileinfo) {
        $pack->{ustream_data} = undef;
        return 0;
    }

    if (defined($pack->{ustream_data}) && ($fileinfo->{coff} != $pack->{ustream_data}{coff} || $fileinfo->{off} < ($pack->{ustream_data}{off} || 0))) {
        $pack->{ustream_data} = undef;
    }

    if (!defined($pack->{ustream_data})) {
        $pack->{ustream_data}{coff} = $fileinfo->{coff};
        $pack->{ustream_data}{read} = 0; # uncompressed data read
        $pack->{ustream_data}{x} = inflateInit(
            -WindowBits     =>  - MAX_WBITS(),
        );
        $pack->{ustream_data}{cread} = 0; # Compressed data read
        {
            my $buf;
            # get magic
            if (sysread($pack->{handle}, $buf, 2) == 2) {
                my @magic = unpack("C*", $buf);
                $magic[0] == 31 && $magic[1] == 139 or do {
                    warn("Wrong magic header found\n");
                    return -1;
                };
            } else {
                warn("Unexpected end of file while reading magic\n");
                return -1;
            }
            my ($method, $flags);
            if (sysread($pack->{handle}, $buf, 2) == 2) {
                ($method, $flags) = unpack("C2", $buf);
            } else {
                warn("Unexpected end of file while reading flags\n");
                return -1;
            }

            if (sysread($pack->{handle}, $buf, 6) != 6) {
                warn("Unexpected end of file while reading gzip header\n");
                return -1;
            }

            $pack->{ustream_data}{cread} += 12; #Gzip header fixed size is already read
            if ($flags & 0x04) {
                if (sysread($pack->{handle}, $buf, 2) == 2) {
                    my $len = unpack("I", $buf);
                    $pack->{ustream_data}{cread} += $len;
                    if (sysread($pack->{handle}, $buf, $len) != $len) {
                        warn("Unexpected end of file while reading gzip header\n");
                        return -1;
                    }
                } else {
                    warn("Unexpected end of file while reading gzip header\n");
                    return -1;
                }
            }
        }
    } else {
        sysseek($pack->{handle}, $pack->{ustream_data}{cread} - 2, 1);
    }
    $pack->{ustream_data}{off} = $fileinfo->{off};
    my $byteswritten = 0;
    while ($byteswritten < $fileinfo->{size}) {
        my ($l, $out, $status) = (0, $pack->{ustream_data}{buf});
        $pack->{ustream_data}{buf} = undef;
        if (!defined($out)) {
            my $cl=sysread($pack->{handle}, my $buf, 
                $pack->{ustream_data}{cread} + $pack->{bufsize} > $fileinfo->{csize} ? 
                    $fileinfo->{csize} - $pack->{ustream_data}{cread} : 
                    $pack->{bufsize}) or do {
                warn("Unexpected end of file\n");
                return -1;
            };
            $pack->{ustream_data}{cread} += $cl;
            ($out, $status) = $pack->{ustream_data}{x}->inflate(\$buf);
            $status == Z_OK || $status == Z_STREAM_END or do {
                warn("Unable to uncompress data\n");
                return -1;
            };
        }
        $l = length($out) or next;
        if ($pack->{ustream_data}{read} < $fileinfo->{off} && $pack->{ustream_data}{read} + $l > $fileinfo->{off}) {
            $out = substr($out, $fileinfo->{off} - $pack->{ustream_data}{read});    
        }
        $pack->{ustream_data}{read} += $l;
        if ($pack->{ustream_data}{read} <= $fileinfo->{off}) { next }

        my $bw;
        if ($byteswritten + length($out) > $fileinfo->{size}) {
            $bw = $fileinfo->{size} - $byteswritten;
            $pack->{ustream_data}{buf} = substr($out, $bw); # keeping track of unwritten uncompressed data
            $pack->{ustream_data}{read} -= length($pack->{ustream_data}{buf});
        } else {
            $bw = length($out);
        }
        syswrite($destfh, $out, $bw) == $bw or do {
            warn "Can't write data into dest\n";
            return -1;
        };
        $byteswritten += $bw;

    }
    $byteswritten
}

1;

__END__

=head1 NAME

MDV::Packdrakeng::zlib - Internal zlib library for MDV::Packdrakeng

=head1 DESCRIPTION

This module is internally used by MDV::Packdrakeng in order to avoid using an
external F<gzip> executable.

=head1 SEE ALSO

L<MDV::Packdrakeng>
