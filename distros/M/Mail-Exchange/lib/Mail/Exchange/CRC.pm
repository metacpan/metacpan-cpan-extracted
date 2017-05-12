package Mail::Exchange::CRC;

=head1 NAME
Mail::Exchange::CRC - implement the CRC algorithm used in RTF compression
and the named property to index PPS streams

=head1 SYNOPSIS

    use Mail::Exchange::CRC;

    my $crc=Mail::Exchange::CRC::new();
    while (<FILE>) {
	    $crc->append($_);
    }
    print $crc->value;

    print Mail::Exchange::CRC::crc($string);

=head1 DESCRIPTION

Mail::Exchange::CRC can be used in function mode or in object oriented mode.
In function mode, you pass a string and get back the crc immediately,
while in object mode, you initialize an object via C<new>, then append data
to the object as needed, and fetch the resulting value at the end.

The crc algorithm is documented in [MS-OXRTFCP], and happens to be the CRC-32
algorithm that is used in a lot of different places as well, for example
in the the IEEE 802.3 Ethernet CRC specification.

=cut

use strict;
use warnings;
use 5.008;

use Exporter;
use vars qw(@ISA @EXPORT_OK $VERSION);

@ISA=qw(Exporter);
@EXPORT_OK=qw(crc);
$VERSION = "0.02";

our @crctable;
my $initialized;

# taken from Image::Dot which uses the same values

sub _make_crc_table {
	my ($c, $n, $k);
	for ($n = 0; $n < 256; $n++) {
		$c = $n;
		for ($k = 0; $k < 8; $k++) {
			if ($c & 1) {
				$c = 0xEDB88320 ^ ($c >> 1);
			} else {
				$c = $c >> 1;
			}
		}
		$crctable[$n] = $c;
	}
}

=head2 new()

$crc=Mail::Exchange::CRC::new([string]) - initialize a new CRC value

Initialize a new CRC calculator, and calculate the CRC of C<string> if
provided.

=cut

sub new {
	my $class=shift;
	my $string=shift;

	unless ($initialized) {
		_make_crc_table();
		die "internal error" unless $crctable[255] == 0x2D02EF8D;
		$initialized=1;
	}

	my $self={};
	bless($self, $class);

	$self->{currval}=0;
	if ($string) {
		$self->append($string);
	}
	return $self;
}

=head2 append()

$crc->append(string)

Appends another string to a CRC, calculating the CRC of the two strings
concatenated to each other

The following are supposed to be equal:

	$crc1=Mail::Exchange::CRC::new("hello world");


	$crc2=Mail::Exchange::CRC::new("hello");
	$crc2->append(" world");
=cut

sub append {
	my $self=shift;
	my $string=shift;

	foreach my $byte (unpack("C*", $string)) {
		$self->{currval}=$crctable[($self->{currval} ^ $byte) & 0xff]
				^ ($self->{currval} >> 8);
	}
	return $self->{currval};
}

=head2 value()

$crcval=$crc->value()

Returns the calculated value of the CRC.

=cut

sub value {
	my $self=shift;
	return $self->{currval};
}

=head2 crc()

$crc=Mail::Exchange::CRC::crc($string)

Calculates the CRC of a string in an easy-to-use, non-object-oriented way.

=cut

sub crc {
	my $string=shift;
	return Mail::Exchange::CRC->new($string)->value;
}

1;
