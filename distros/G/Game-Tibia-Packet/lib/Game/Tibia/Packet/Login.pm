use strict;
use warnings;
use v5.16.0;
package Game::Tibia::Packet::Login;

# ABSTRACT: Login packet support for the MMORPG Tibia
our $VERSION = '0.005'; # VERSION

use Carp;
use File::ShareDir 'dist_file';
use Crypt::OpenSSL::RSA;
use Digest::Adler32;
use Game::Tibia::Packet;
use Scalar::Util qw(blessed);

=pod

=encoding utf8

=head1 NAME

Game::Tibia::Packet::Login - Login packet support for the MMORPG Tibia


=head1 SYNOPSIS

    use Game::Tibia::Packet::Login;


=head1 DESCRIPTION

Decodes Tibia Charlist packets into hashes and vice versa.  By default uses the OTServ RSA key, but allows different RSA keys to be supplied.

=cut

my $otserv = Crypt::OpenSSL::RSA->new_private_key(
    do { local $/; open my $rsa, dist_file('Game-Tibia-Packet', 'otserv.private') or die "Couldn't open private key $!"; <$rsa>; }
);

=head1 METHODS AND ARGUMENTS

=over 4

=item new([packet => $packet, rsa => OTSERV])

Constructs a new C<Game::Tibia::Packet::Login> instance. If C<packet> is supplied, decryption using the supplied rsa private key is attempted. If no C<rsa> is supplied, the OTServ RSA key is used.

=cut

sub new {
	my $class = shift;
    
	my $self = {
        packet => undef,
        rsa    => $otserv,

        @_
    };

    unless (blessed $self->{rsa}) {
        $self->{rsa} = Crypt::OpenSSL::RSA->new_private_key($self->{rsa});
    }
    $self->{rsa}->use_no_padding;

    if (defined $self->{packet}) {
        (my $len, $self->{os}, $self->{version}{client}, $self->{version}{spr}, $self->{version}{dat}, $self->{version}{pic}, my $payload)
            = unpack 'v x(S S L3)< a*', $self->{packet};

        my $decr = $self->{rsa}->decrypt($payload);
        croak q(Decoded RSA doesn't start with zero.) if $decr !~ /^\0/;

        my $acc_data_pattern =
            Game::Tibia::Packet::version($self->{version}{client})->{ACCNUM}
                             ?  '(V S/a)' : '(S/a S/a)<';
        ($self->{XTEA}, $self->{account}, $self->{password}, $self->{hwinfo}, $self->{padding})
            = unpack "(x a16 $acc_data_pattern)< a47 a*", $decr;
    }

	bless $self, $class;
	return $self;
}

=item finalize([$rsa])

Finalizes the packet. encrypts with RSA and prepends header

=cut


sub finalize {
	my $self = shift;
    my $rsa = shift // $self->{rsa};
    $self->{rsa}->use_no_padding;
    $self->{version}{client} = Game::Tibia::Packet::version $self->{version}{client} unless ref $self->{version}{client};
    $rsa = Crypt::OpenSSL::RSA->new_private_key($rsa) unless blessed $rsa || !$self->{version}{client}{RSA};
    my $expected_rsa_size = $self->{version}{client}{RSA};
    !defined $expected_rsa_size || $rsa->size == $expected_rsa_size
        or croak "Protocol $self->{version}{client}{VERSION} expects "
           . ($self->{version}{client}{RSA} * 8) . " bit RSA key, but ${\($rsa->size*8)} bit were provided";

    $self->{packet} = pack 'C (S S L3)<', 0x01, $self->{os}, $self->{version}{client}{VERSION}, $self->{version}{spr}, $self->{version}{dat}, $self->{version}{pic};

    my $acc_data_pattern =
        Game::Tibia::Packet::version($self->{version}{client})->{ACCNUM}
                         ? '(V S/a)' : '(S/a S/a)<' ;
    my $payload = pack "(C a16 $acc_data_pattern a47)<", 0x00, $self->{XTEA}, $self->{account}, $self->{password}, $self->{hwinfo};

    my $padding_len = $self->{version}{client}{RSA} - length($payload);
    $self->{padding} //= '';
    $payload .= pack "a$padding_len", $self->{padding};
    $payload = $self->{rsa}->encrypt($payload) if $self->{version}{client}{RSA};
    $self->{packet} .= $payload;


	if ($self->{version}{client}{ADLER32}) {
		my $a32 = Digest::Adler32->new;
		$a32->add($self->{packet});
        my $digest = unpack 'H*', pack 'N', unpack 'L', $a32->digest;
        $self->{packet} = $digest.$self->{packet};
	}

	$self->{packet} = pack("S/a", $self->{packet});

	$self->{packet};
}

1;
__END__

=back

=head1 GIT REPOSITORY

L<http://github.com/athreef/Game-Tibia-Packet>

=head1 SEE ALSO

L<Game::Tibia::Packet>

L<Game::Tibia::Packet::Charlist>

=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2016 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut


