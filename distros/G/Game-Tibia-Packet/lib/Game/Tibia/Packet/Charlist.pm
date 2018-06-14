use strict;
use warnings;
use v5.16.0;
package Game::Tibia::Packet::Charlist;

# ABSTRACT: Character list packet support for the MMORPG Tibia
our $VERSION = '0.007'; # VERSION

use Carp;
use Game::Tibia::Packet;

=pod

=encoding utf8

=head1 NAME

Game::Tibia::Packet::Charlist - Character list packet support for the MMORPG Tibia


=head1 SYNOPSIS

    use Game::Tibia::Packet::Charlist;

    my $p = Game::Tibia::Packet::Charlist->new(
        packet => $packet,
        xtea    => $xtea,
        version => 830
    );

    $p->{premium_days} = 0xff;
    $sock->send($p->finalize);


=head1 DESCRIPTION

Decodes Tibia Login packets into hashes and vice versa.

=cut

our %params;
sub import {
    (undef, %params) = (shift, %params, @_);
    die "Malformed Tibia version\n" if exists $params{tibia} && $params{tibia} !~ /^\d+$/;
}

use constant DLG_MOTD     => 0x14;
use constant DLG_INFO     => 0x15;
use constant DLG_ERROR    => 0x0a;
use constant DLG_CHARLIST => 0x64;

=head1 METHODS AND ARGUMENTS

=over 4

=item new([packet => $packet, version => $version, xtea => $xtea])

Constructs a new Game::Tibia::Packet::Charlist instance of version C<$version>. When C<packet> and C<xtea> are specified, the supplied packet is decrypted and is then retrievable with the C<payload> subroutine.

=cut

sub new {
	my $class = shift;

	my $self = {
        packet => undef,
        xtea    => undef,

        @_
    };

    $self->{version} //= $params{tibia};
    croak " 761 <= protocol version < 980 isn't satisfied" if !defined $self->{version} || ! (761 <= $self->{version} && $self->{version} < 980);
    croak "Packet was specified without XTEA key" if defined $self->{packet} && !defined $self->{xtea};
    $self->{versions}{client} = Game::Tibia::Packet::version $self->{version} unless ref $self->{version};

    if (defined $self->{packet}) {
        my $packet = Game::Tibia::Packet->new(
            packet  => $self->{packet},
            xtea    => $self->{xtea},
            version => $self->{version},
        );

        my $payload = $packet->payload;
        (my $type, $payload) = unpack 'Ca*', $payload;
        if      ($type eq DLG_MOTD) {
            ($self->{motd}, $payload) = unpack '(S/a)< a*', $payload;
        } elsif ($type eq DLG_INFO) {
            ($self->{info}, $payload) = unpack '(S/a)< a*', $payload;
        } elsif ($type eq DLG_ERROR) {
            ($self->{error}, $payload) = unpack '(S/a)< a*', $payload;
        }
        ($type, $payload) = unpack 'Ca*', $payload;
        if ($type eq DLG_CHARLIST) {
            (my $count, $payload) = unpack 'Ca*', $payload;
            $self->{characters} = undef;
            my @chars;
            while ($count--) {
                my $char;
                ($char->{name}, $char->{world}{name}, $char->{world}{ip}, $char->{world}{port}, $payload)
                = unpack '(S/a S/a a4 S)< a*', $payload;
                $char->{world}{ip} = join '.', unpack('C4', $char->{world}{ip});
                push @chars, $char;
            }
            $self->{characters} = \@chars;
        }
        $self->{premium_days} = unpack 'S<', $payload;
    }

	bless $self, $class;
	return $self;
}

=item finalize([$xtea]])

Finalizes the packet. encrypts with XTEA and prepends header

=cut


sub finalize {
    my $self = shift;
    my $xtea = shift // $self->{xtea};

    my $packet = Game::Tibia::Packet->new(version => $self->{version});
    $packet->payload .= pack '(C S/a)<', DLG_MOTD, $self->{motd} if defined $self->{motd};
    $packet->payload .= pack '(C S/a)<', DLG_INFO, $self->{info} if defined $self->{info};
    $packet->payload .= pack '(C S/a)<', DLG_ERROR, $self->{error} if defined $self->{error};
    if (defined $self->{characters} && @{$self->{characters}} > 0) {
    $packet->payload .= pack 'C C', DLG_CHARLIST, scalar @{$self->{characters}};
        foreach my $char (@{$self->{characters}}) {
            $packet->payload .= pack '(S/a S/a a4 S)<',
                $char->{name}, $char->{world}{name},
                pack("C4", split('\.', $char->{world}{ip})), $char->{world}{port};
        }
    }
    $packet->payload .= pack('S<', $self->{premium_days}); # pacc days
    return $packet->finalize($xtea);
}


1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Game-Tibia-Packet>

=head1 SEE ALSO

L<Game::Tibia::Packet>

L<Game::Tibia::Packet::Login>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

