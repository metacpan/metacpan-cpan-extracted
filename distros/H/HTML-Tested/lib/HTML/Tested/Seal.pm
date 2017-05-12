use strict;
use warnings FATAL => 'all';

package HTML::Tested::Seal;
use base 'Class::Singleton';
use Crypt::CBC;
use Digest::CRC qw(crc8);
use Carp;
use Digest::MD5 qw(md5);
use bytes;

sub _new_instance {
	my ($class, $key) = @_;
	my $self = bless({}, $class);
	confess "No key!" unless $key;
	my $iv = substr(md5($key), 0, 8);
	my $c = Crypt::CBC->new(-key => $key, -cipher => 'Blowfish'
			, -iv => $iv, -header => 'none');
	confess "No cipher!" unless $c;
	$self->{_cipher} = $c;
	return $self;
}

sub encrypt {
	my ($self, $data) = @_;
	confess "# No data to encrypt given!" unless defined($data);
	my $c = crc8($data);
	return $self->{_cipher}->encrypt_hex(pack("Ca*", $c, $data));
}

sub decrypt {
	my ($self, $data) = @_;
	my $d;
	eval { $d = $self->{_cipher}->decrypt_hex($data) };
	return undef unless defined($d);

	my ($c, $res) = unpack("Ca*", $d);
	return undef unless (defined($c) && defined($res));
	my $c1 = crc8($res);
	return $c1 == $c ? $res : undef;
}

1;
