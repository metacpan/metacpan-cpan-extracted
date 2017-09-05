use strict;
use warnings;
use v5.16.0;
package Game::Tibia::Packet;

# ABSTRACT: Minimal session layer support for the MMORPG Tibia
our $VERSION = '0.006'; # VERSION

use Digest::Adler32 qw(adler32);
use Crypt::XTEA 0.0108;
use Crypt::ECB 2.0.0;
use Carp;

sub version;

=pod

=encoding utf8

=head1 NAME

Game::Tibia::Packet - Session layer support for the MMORPG Tibia

=head1 SYNOPSIS

    use Game::Tibia::Packet;

    # decrypt Tibia packet
    my $read; my $ret = $sock->recv($read, 1024);
    my $res = Game::Tibia::Packet->new(packet => $read, xtea => $xtea_key);
    $packet_type = unpack('C', $res->payload);


    # encrypt a Tibia speech packet
    my $p = Game::Tibia::Packet->new;
    $p->payload .= pack("C S S S/A S C SSC S/A",
        0xAA, 0x1, 0x0, "Perl", 0, 1, 1, 1, 8,
        "Game::Tibia::Packet says Hi!\n:-)");
    $sock->send($p->finalize($xtea_key}))

=begin HTML

<p><img src="http://athreef.github.io/Game-Tibia-Packet/img/hi.png" alt="Screenshot"></p>

=end HTML


=head1 DESCRIPTION

Methods for constructing Tibia Gameserver (XTEA) packets. Handles checksum calculation and symmetric encryption depending on the requested Tibia version.

Should work with all Tibia versions less than 9.80.

=head1 METHODS AND ARGUMENTS

=over 4

=item new(version => $version, [packet => $payload, xtea => $xtea])

Constructs a new Game::Tibia::Packet instance of version C<$version>. If payload and XTEA are given, the payload will be decrypted and trimmed to correct size.

=cut

sub new {
    my $type = shift;
    my $self = {
        payload => '',
        packet => '',
        xtea => undef,
        padding => '',
        @_
    };

    croak 'A protocol version < 9.80 must be supplied' if !defined $self->{version} || $self->{version} >= 980;
    $self->{versions}{client} = version $self->{version} unless ref $self->{version};

    if ($self->{packet} ne '')
    {
        #return undef unless isValid($self->{packet});
        my $ecb = Crypt::ECB->new(
            -cipher => Crypt::XTEA->new($self->{xtea}, 32, little_endian => 1)
        );
        $ecb->padding('null');

        my $digest_size = defined $self->{versions}{client}{adler32} ? 4 : 0;
        $self->{payload} = $ecb->decrypt(substr($self->{packet}, 2 + $digest_size));
        $self->{payload} .= "\0" x ((8 - length($self->{payload})% 8)%8);
        $self->{padding} = substr $self->{payload}, 2 + unpack('v', $self->{payload});
        $self->{payload} = substr $self->{payload}, 2,  unpack('v', $self->{payload});
    }

    bless $self, $type;
    return $self;
}

=item isValid($packet)

Checks if packet's adler32 digest matches (A totally unnecessary thing on Cipsoft's part, as we already have TCP checksum. Why hash again?)

=cut

sub isValid {
    my $packet = shift;

    my ($len, $adler) = unpack('(S a4)<', $packet);
    return 0 if $len + 2 != length $packet;

    my $a32 = Digest::Adler32->new;
    $a32->add(substr($packet, 6));
    return 0 if $a32->digest ne reverse $adler;
    1;
    #TODO: set errno to checksum failed or length doesnt match
}

=item payload() : lvalue

returns the payload as lvalue (so you can concat on it)

=cut

sub payload : lvalue {
    my $self = shift;
    return $self->{payload};
}

=item finalize([$XTEA_KEY])

Finalizes the packet. XTEA encrypts, prepends checksum and length.

=cut


sub finalize {
    my $self = shift;
    my $XTEA = $self->{xtea} // shift;

    my $packet = $self->{payload};
    if ($self->{versions}{client}{xtea} and defined $XTEA) {
        $packet = pack('v', length $packet) . $packet;

        my $ecb = Crypt::ECB->new(
            -cipher => Crypt::XTEA->new($XTEA, 32, little_endian => 1)
        );
        $ecb->padding('null');

        # $packet .= "\0" x ((8 - length($packet)% 8)%8);
        my $padding_len = (8 - length($packet)% 8)%8;
        $packet .= pack("a$padding_len", unpack('a*', $self->{padding}));
        my $orig_len = length $packet;
        $packet = $ecb->encrypt($packet);
        substr($packet, $orig_len) = '';
    }

    my $digest = '';
    if ($self->{versions}{client}{adler32}) {
        my $a32 = Digest::Adler32->new;
        $a32->add($packet);
        $digest = unpack 'H*', pack 'N', unpack 'L', $a32->digest;
    }

    $packet = CORE::pack("S/a", $digest.$packet);

    $packet;
}


=item version($version)

Returns a hash reference with protocol traits. For example for 840, it returns:

    { gmbyte => 1, outfit_addons => 1, adler32 => 1, acc_name => 1,
      stamina => 1, xtea => 1, VERSION => 840, rsa => 1, lvl_on_msg => 1 };

=cut

use constant TRUE => 1;

sub version {
    my $version = shift;
    $version = $version->{VERSION} if ref $version;
    $version =~ s/^v|[ .]//g;
    $version =~ /^\d+/ or croak 'Version format invalid';

    my %has;

    $has{gmbyte} = 1; # Not sure when the GM byte first appeared

    ($version >= 761) # 761 was a test client. 770 was the first release
        and $has{xtea} = $has{rsa} = TRUE;
    ($version >= 780)
        and $has{outfit_addons} = $has{stamina} = $has{lvl_on_msg} = TRUE;
    ($version >= 830)
        and $has{adler32} = $has{acc_name} = TRUE;
    ($version >= 841)
        and $has{hwinfo} = $has{nonce} = TRUE;
    ($version >= 953)
        and $has{ping} = TRUE;
    ($version >= 980)
        and $has{client_version} = $has{game_preview} = TRUE;
    ($version >= 1010)
        and $has{worldlist_in_charlist} = TRUE;
    ($version >= 1061)
        and $has{extra_gpu_info} = TRUE;
    ($version >= 1071)
        and $has{game_content_revision} = TRUE;
    ($version >= 1072)
        and $has{auth_token} = TRUE;
    ($version >= 1074)
        and $has{session_key} = TRUE;

    $has{VERSION} = $version;

    return \%has;
}

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Game-Tibia-Packet>

=head1 SEE ALSO

The protocol was reverse engineered as part of writing my L<Tibia Wireshark Plugin|https://github.com/a3f/Tibia-Wireshark-Plugin>.

L<Game::Tibia::Cam>

L<Game::Tibia::Packet::Login>

L<Game::Tibia::Packet::Charlist>


L<http://tpforums.org/forum/forum.php>
L<http://tibia.com>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 DISCLAIMER

Tibia is copyrighted by Cipsoft GmbH.

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
