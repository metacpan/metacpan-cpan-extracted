use strict;
use warnings;
package Game::Tibia::Cam;

# ABSTRACT: Read/Convert TibiCam .rec files to pcaps
our $VERSION = '0.003'; # VERSION

use Carp;
use Game::Tibia::Packet::Login 0.006;
use Net::PcapWriter;
use Time::HiRes;
use Scalar::Util 'openhandle';

=pod

=encoding utf8

=head1 NAME

Game::Tibia::Cam - Read/Convert TibiCam .rec files to pcaps


=head1 SYNOPSIS

    # cam2pcap script
    use Game::Tibia::Cam;
    local $/;
    print Game::Tibia::Cam->new(rec => <>)->pcap;


=head1 DESCRIPTION

With programs like TibiCam, Tibia game sessions can be saved to a custom format and replayed with a modified game client.

This plugin allows conversion between some of these formats and the more main-stream pcap format.

=head1 METHODS AND ARGUMENTS

=over 4

=item new(rec => $recording, [is_str => undef])

Here, the [] indicate an optional parameter.

Constructs a new C<Game::Tibia::Cam> instance. C<$recording> is either a binary string
resulting from reading a recording in the C<*.rec> format or the filename of such a recording.

When C<$is_str> is C<undef>, the type of C<$recording>'s contents is inferred from the first bytes.

Function croaks if opening file fails.

=cut

sub new {
    my $class = shift;

    my $self = {
        @_
    };

    $self->{sig} = unpack 'S>', $self->{rec};
    $self->{is_str} //= _getversion($self->{sig});

    unless ($self->{is_str}) {
        my $file = $self->{rec};
        croak 'No file name provided' if !defined $file || $file eq '';

        local $/;
        open(my $fh, '<:raw', $file) or croak "Failed to open file '$file' for reading: $!";

        my $self->{rec} = <$fh>;
        close($fh);

        croak "Reading from '$file' returned undef" unless defined $self->{rec};
    }

    $self->{sig} = unpack 'S>', $self->{rec};
    ($self->{min_version}, $self->{max_version}) = _getversion($self->{sig});
    $self->{max_version} //= $self->{min_version};

    croak "Not a valid TibiCam recording" unless defined $self->{min_version};
    croak 'Encrypted TibiCam files not yet supported' if $self->{sig} >= 0x502;

    # https://github.com/gurka/OldSchoolTibia/blob/master/tools/libs/recording.py
    $self->{ptotal} = unpack 'xx L<', $self->{rec};
    $self->{ptotal} -= 57 if $self->{sig} >= 0x302;
    (my $s, $self->{sizesize}) = $self->{sig} == 0x301 ? ('L', 4) : ('S', 2);
    $self->{template} = "($s L X[L]X[$s] $s x[L] /a)<";

    bless $self, $class;
    return $self;
};

=item ptotal()

Returns the total number of packets in the recording. This is C<O(1)>.

=cut

sub ptotal {
    my $self = shift;
    $self->{ptotal};
}

=item version()

Returns the recording's protocol version. If the version can't be precisely determined, return value should be interpreted as C<($min, $max)> instead. Otherwise, C<($ver, $ver)>.

=cut

sub _getversion {
    my ($sig) = @_;

    $sig == 0x301 and return @{[721, 724]};
    $sig == 0x302 and return @{[730, 760]};
    $sig == 0x402 and return @{[770]};
    $sig == 0x502 and return @{[770, 790]};
    $sig == 0x602 and return @{[810]};

    return undef;
}

sub version {
    my $self = shift;

    return wantarray ? ($self->{min_version}, ($self->{max_version} // $self->{min_version}))
                     : $self->{min_version};
}

=item pfirst()

Returns the first packet in a capture

=cut

sub _reset {
    my $self = shift;
    my ($offset, $pnum) = @_;

    ($self->{offset}, $offset) = ($offset, $self->{offset});
    ($self->{pnum}, $pnum) = ($pnum, $self->{pnum});
    $self->{eof} = ($self->{pnum} // 0) == $self->{ptotal};

    return ($offset, $pnum);
}

sub pfirst {
    my $self = shift;

    $self->_reset(6, 0);
    (undef, $self->{first_ts}, undef)
        = unpack $self->{template}, substr($self->{rec}, $self->{offset});
    return $self->pnext;
}

=item pnum()

Returns the number of the packet that has just been read by C<pnext>
=cut

sub pnum {
    my $self = shift;
    $self->{pnum};
}

=item pnext()

Returns the next packet in a capture

=cut

sub pnext {
    my $self = shift;

    return $self->pfirst unless defined $self->{offset};
    return undef if $self->{eof};

    (my $len, $self->{last_ts}, my $data)
        = unpack $self->{template}, substr($self->{rec}, $self->{offset});
    $len == length($data)
        or croak "Packet length " . length($data) . " smaller than reported $len at offset " . $self->{offset} . "/" . length($self->{rec});

    $self->{offset} += $self->{sizesize} + 4 + $len;
    if (++$self->{pnum} == $self->{ptotal}) {
        $self->{eof} = 1;
        $self->{duration} = ($self->{last_ts} - $self->{first_ts}) / 1000;
    }

    return { timestamp => $self->{last_ts} / 1000, data => $data }
}

=item duration()

Returns the duration of the clip. This requires traversing all unparsed packets, so calling it after C<pnext> returns C<undef> is preferable.

=cut

sub _forrest {
    my $self = shift;
    $self->_foreach(@_, $self->_reset);
}

sub _foreach {
    my ($self, $code, @off) = @_;

    my @pos = $self->_reset(@off); # save seek pointer

    if (defined $code) {
        while (my $p = $self->pnext) { $code->($p); }
    } else {
        while (my $p = $self->pnext) { }
    }

    $self->_reset(@pos); # restore seek pointer
}


sub duration {
    my $self = shift;

    unless (defined $self->{duration}) {
        $self->_forrest; # Does a lot of useless copies
    }

    return $self->{duration};
}

=item pcap([ file => undef, synthesize_login  => 1])

Either creates a new pcap file or append the data to a file handle if specified. In both cases, it returns a file handle for possible further appending. If C<file> is C<undef>, which it is by default, a string with the contents is returned instead.

Unless, C<< synthesize_login => 0 >>, a Tibia game server login packet is prepended to the pcap. This allows the pcap to be directly read into wireshark and dissected with the Tibia dissector, because otherwise Wireshark wouldn't know for sure what version and possibly XTEA key, the capture has.

If RSA encryption is required, the OTServ RSA key is used.

=cut

sub pcap {
    my $self = shift;
    my %args = (
        synthesize_login => 1,
        @_
    );

    my $fh = openhandle $args{file};

    my $pcap;

    unless ($fh) {
        if (defined $args{file}) {
            open($fh, '>:raw', $args{file}) or croak "Can't open '$args{file}' for pcap: $!";
        } else {
            open($fh, '>:raw', \$pcap) or croak "Can't open in-memory file for pcap: $!";
        }
    }

    my $writer = Net::PcapWriter->new($fh);
    my $conn = $writer->tcp_conn('127.0.0.1',57171  =>  '127.0.0.1',7171);


    if ($args{synthesize_login} == 1) {
        my $login = Game::Tibia::Packet::Login->new(
            version  => scalar $self->version,
            character => __PACKAGE__,
        );

        $conn->write(0, $login->finalize);
    }


    my $basetime = Time::HiRes::gettimeofday;

    my $n = 0;
    $self->_foreach(sub {
        my ($p) = @_;
        $conn->write(1, $p->{data}, $basetime + $p->{timestamp});
    });
    $conn->shutdown(0);

    return $pcap // $fh;
}

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Game-Tibia-Cam>

=head1 SEE ALSO

L<Game::Tibia::Packet>

L<Tibia Wireshark Plugin|https://github.com/a3f/Tibia-Wireshark-Plugin>.

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
