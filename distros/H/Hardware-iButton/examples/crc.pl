#!/usr/bin/perl -w

$id = "0c" . "cf6403000000" . "38";
$id = "10" . "cec514000000" . "b1";
#$id = "09" . "cc7058010000" . "2c";

{
    my $crc;

    sub init {
	$crc = 0;
    }

    sub addbit {
	my($bit) = @_;
	printf("addbit($bit): 0x%02x -> ",$crc);;
	my $in = ($crc & 1) ^ $bit;
	$crc ^= 0x18 if $in;
	$crc >>= 1;
	$crc |= 0x80 if $in; #??
	printf("0x%02x\n",$crc);
    }

    sub dump {
	return $crc;
    }
}

$bits = unpack("b*", pack("H16", $id));
print "bits: $bits\n";

init();
@bits = split(//,$bits);
foreach (@bits) {
    addbit($_);
}
&dump();
