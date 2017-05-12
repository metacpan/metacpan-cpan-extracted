#!/usr/bin/perl -w

sub xs {
    my($s) = @_;
    print "length(\$s) = ",length($s),"\n";
    print join(',', map {sprintf('0x%02x',$_)} unpack("C*",$s)),"\n";
}

sub xa {
    my(@b) = @_;
    print "scalar(\@b) = ",scalar(@b),"\n";
    print "int: ",join(',',map {sprintf('0x%02x',$_)} @b),"\n";
    print "chars: ",join(',',map {sprintf('0x%02x',ord($_))} @b),"\n";
}

$b = "0001001000110100";

# each creates a string of length 2
# the first 8 chars of $b are used to create the first char of $c
$c = pack("b16", $b); # treats string as b0,b1,b2,b3,b4,b5,b6,b7, b0,b1..
xs($c);
print "unpack: ",unpack("b16", $c),"\n";
$c = pack("B16", $b); # treats string as b7,b6,b5,b4,b3,b2,b1,b0, b7,b6..
xs($c);
print "unpack: ",unpack("B16", $c),"\n";

# packing to send out
$b1 = $b;
$b1 =~ s/(.)/0 . $1/ge;
print "b1: $b1\n";
$b2 = pack("b32", $b1);
xs($b2);


# unpacking on the way in
# test string: r0r1.. is 10100011, d0d1.. is 00010000
$d = "01100010" . "10100000";
@d = unpack("C2", pack("B16", $d));
xa(@d);
# we get a series of bytes. Each one is:
#  r3d3r2d2r1d1r0d0
#  r7d7r6d6r5d5r4d4 ...
# and we want to split it into d0,d1,d2,d3 ... and r0,r1,r2,r3 ...

# first, unpack the bytes into a string 'd0r0d1r1d2r2d3r3'. Then we can 
# concatenate them. test string should give '01000110 00000101'
$d1 = join('', map { unpack("b8",chr($_)) } @d);
print "d1: $d1\n";

# now extract every other bit (char) into a separate array
$d2d = $d1; $d2r = $d1;
$d2d =~ s/(.)./$1/g; # throw out second, fourth, etc chars
$d2r =~ s/.(.)/$1/g; # throw out first, third, etc chars

print "d2d: $d2d\n";
print "d2r: $d2r\n";

@r = split(//, $d2r); @d = split(//, $d2d);
print "\@r:\n";
xa(@r);
print "\@d:\n";
xa(@d);

