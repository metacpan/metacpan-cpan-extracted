#!/home/markt/usr/local/Linux/bin/perl -w

use utf8;
my $glis = "\x{395}\x{3CD}\x{3B1}\x{3B3}\x{3B3}\x{3B5}\x{3BB}\x{3CA}\x{3B1}\x{65}\x{66}";
$num = 333;
print "HEX: ",&dectohex($num),"\n";
print "BIN: ",&dectobin($num),"\n";
my @ch = split //, $glis;
foreach (@ch)
{
	print "CHAR: $_\n";
	my $x = unpack("U",$_);
	my @bytes = &get_chars_from_dec($x);
	push @all, @bytes;
	print "NUM: $x = $bytes[0] $bytes[1]\n";
}

local $" = ",";
print "@all\n";
exit;

@chars = &get_chars_from_decs(@num);
$" = ",";
print "@chars\n";

sub get_chars_from_decs
{
	my @ret;
	foreach(@_)
	{
		push @ret, &get_chars_from_dec($_);
	}
	
	@ret;
}
	

sub get_chars_from_dec
{
	unpack("C*",pack("n",shift));
}

sub bintodec 
{
	unpack("N", pack("B32", substr("0" x 32 . shift, -32)));
}

sub dectobin
{
	unpack("B32", pack("N", shift));
}

sub dectohex
{
	unpack("h*", pack("n", shift));
}

