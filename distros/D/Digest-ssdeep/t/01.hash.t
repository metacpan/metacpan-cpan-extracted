use Test::More tests => 32;
use File::Temp qw/tempfile/;

use Digest::ssdeep qw/ssdeep_hash ssdeep_hash_file/;

while (my $line = <DATA>) {
	next unless $line =~ /^\d+,/;

	my ($i, $hash, $file) = split /,/, $line;

	ok ( ssdeep_hash(rand_str($i)) eq $hash, "Tested $i characters long" );
}

# Test array output as well
my @expected = qw{24 ivk6g/3pXNpRobD3qebULKLTTSOcHwbKLmp/j/FdkAs5n4QKnn6mU5kOHQpBVUQY Ek6g/3pX/ebD3qebcKLTTcmKm/Tkx5nP};
my @got = ssdeep_hash(rand_str(1477));
is_deeply ( \@got, \@expected, 'Array output' );



# Test hash_file
my ($fh, $filename) = tempfile();
print $fh rand_str(11222);
close $fh;

@expected = qw{192 vuwl3pBbm9YPL2zSUnZBXGmy3977H63khOKmU4LoDdX7tbIi5h/GiLjNIpap7c6Q vuM3vmyp2ZBXGPPj8LapbIi//LLjKpYa};
@got = ssdeep_hash_file($filename);
is_deeply ( \@got, \@expected, 'Hash file (array output)' );

my $expected = '192:vuwl3pBbm9YPL2zSUnZBXGmy3977H63khOKmU4LoDdX7tbIi5h/GiLjNIpap7c6Q:vuM3vmyp2ZBXGPPj8LapbIi//LLjKpYa';
my $got = ssdeep_hash_file($filename);
ok ( $got eq $expected, 'Hash file (string output)' );

unlink $filename;




sub rand_str {
	my $i = shift;
	srand($i);
	return join "", map chr(rand(256)), 1..$i;
}

__DATA__
# Cannot use same-character string to test CTPH.
# The random string is the result of:
#
# for $i = ...
#	srand($i);
#	print join "", map chr(rand(256)), 1..$i;'
#
# Bash:
# for j in {1..35}; do i=$(echo "1.5^$j/1" | bc); echo -n $i,; i=$i perl -e '$i = $ENV{i}; srand($i); print join "", map chr(rand(256)), 1..$i;' | (ssdeep|grep -v filename) ; done > /tmp/gg
#
#
# bytes,blocksize:hash1:hash2,"filename"
1,3:v:v,"stdin"
2,3:Mn:Mn,"stdin"
3,3:xn:x,"stdin"
5,3:L:L,"stdin"
7,3:dzfn:Nn,"stdin"
11,3:uc1gC:uc1gC,"stdin"
17,3:uxFtK263n:uxw,"stdin"
25,3:YtuzKZXO:YtuzKpO,"stdin"
38,3:sFbOyjIJhgGUnEn:sFiybE,"stdin"
57,3:PMomopd2UfXYppfj:PMx0QLffj,"stdin"
86,3:opgonrBMOZB12pieqyrxBRNTDidtHMi:h6rqO/1ITrxBWdT,"stdin"
129,3:IxbXw09OOwvKtc76KwgSYvTt3lnNNqyph:I9XwMptc76rYL/J,"stdin"
194,3:Pfo9vJGQBNx9W3wMR+9rKTALvZq48HSR9IELUfjnLRUfmDDfbqjT:Pfov7GgB8MLB71IELmjnNU+DDDqX,"stdin"
291,6:AfzKNnARBm8mPTRaWGuvJV7n5Z0XB6hL7mSgQHf:oglTRaWjV75eMF/,"stdin"
437,6:Oujj0YPmJZ+7WduliNE4A2fT+iuYS0PV66XlyQMXm/pIZb9MSm6jxEMUGSFoK/YH:M3kliNE4A27uqPc6MQMY7l69xilhDP+,"stdin"
774,12:SCUqMuapucCeqQX1EXdjv8/Q/KkdAj92uEpz5SrBa8fHc+dn3MRdYhNiwk:jMu6uvHNjvwQ/KOM0pzoYu3MmNib,"stdin"
781,24:t2KPOJaY8jGIvIStgvaB/Jb06mP+g0cnXMSNsn:20amIrF/rMwsn,"stdin"
790,12:EFFzuHf0r7rBnz0yE1IdHpciXyMVzgh+sShm9vZUXK7IGtNZ:E7hv1pciCM0SmBv7tX,"stdin"
985,24:RuzbjIE/Z+dONABU13ZDj5xzHdBoX975kc8eFFhX:RyXI5dVBexzHvCpXFDX,"stdin"
1477,24:ivk6g/3pXNpRobD3qebULKLTTSOcHwbKLmp/j/FdkAs5n4QKnn6mU5kOHQpBVUQY:Ek6g/3pX/ebD3qebcKLTTcmKm/Tkx5nP,"stdin"
2216,48:xYD4x+0DrgLQ337bompHHYsJ8cfF0iXWrnOwFK4B76axlaztA6R5WeHc998AvNbo:xa440D4Q3fompYsjt7XaOoXPsz+6R5Wg,"stdin"
3325,96:evgnpMXzamDB84B2lbdCvaNpPyJCfA1k9vTR1x1:7md72NIC2JatFTT,"stdin"
4987,96:gjSMDET+aSRpDP6dEtJnHVq+3FyDa5Skna3vJmTxiV0qDOcQOXjU:UHgbmDSAHVq+34e51nYxqkOqTU,"stdin"
7481,192:5rn1Ka+ZNuwPf004r/LI/za5ISVh00wEs8NWmOI:5rnkaMPf0lLsST+38Z,"stdin"
11222,192:vuwl3pBbm9YPL2zSUnZBXGmy3977H63khOKmU4LoDdX7tbIi5h/GiLjNIpap7c6Q:vuM3vmyp2ZBXGPPj8LapbIi//LLjKpYa,"stdin"
25251,384:HgEQu3dxfXKHYINP/4iKjxhEXuydSP16Vac9TrN+y5sPRa73le/ejEFJjXgNIWo:HgIPK4CojxhEXuGVac9TrNMm+/8NTo,"stdin"
37876,768:rCuHZxxXi6BXUfX6IFX6UTfrCt/aizyg2JJM4+GDcDXm9qkDftzCF:/HFLBXCcUkaimgKaQUXcXVzY,"stdin"
85222,1536:wiP27adNLE8kqAomXaQxWOQLqbEqW6OxqNNx+wVmxjlYvvqwnSea:Wa7LvkrvXatOTFOMNxDVmxuvJ4,"stdin"
287626,6144:vAj/s/W02dAPOeb8I29VgXa3t5MezyGSLh+5Tw/U91tl3/MCL6:IAd6AWetbK3t5j9SLE5R91thB2,"stdin"

