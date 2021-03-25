# Demonstrate the basics of Rmpz_import, Rmpz_export, Rmpz_import_UV and Rmpz_export_UV

use warnings;
use strict;
use Math::GMPz qw(:mpz);
use Config;

use Test::More;

################################################################
# Firstly, show the relationship between the string handed to  #
# Rmpz_import and the value that is created from that string.  #
################################################################

my $string = 'aBc';
my $words  = 3; # length($string)
my $order  = 1; # Read the most significant word first.
my $size   = 1; # 1 byte per word.
my $endian = 0; # Use native endianness. We have specified only 1 byte
                # per word, so the order in which the bytes are read
                # is immaterial, anyway.
my $nails  = 0; # Read *all* of the bits in each byte.


# Calculate the expected value by hand.
# If $order were set to -1, we would need to do:
# my $expected = Math::GMPz->new((ord('c') * (256 ** 2)) + (ord('B') * 256) + ord('a'));
# But $order is set to +1:
my   $expected = Math::GMPz->new((ord('a') * (256 ** 2)) + (ord('B') * 256) + ord('c'));

my $got = Math::GMPz->new();

# Have Rmpz_import do its calculation.
Rmpz_import($got, $words, $order, $size, $endian, $nails, 'aBc');

print "Rmpz_import of the string 'aBc' results in a value of $got\n\n";

cmp_ok($got, '==', $expected, "Rmpz_import calculations agree");

########################################################################
# Now check that we can retrieve the original string using Rmpz_export #
########################################################################

my $check = Rmpz_export( $order, $size, $endian, $nails, $got);

cmp_ok($check, 'eq', 'aBc', "string retrieval succeeds");

####################################################################
# Now, do the same for Rmpz_import_UV and Rmpz_export_UV.          #
# Firstly, show the relationship between the array of UVs handed   #
# to Rmpz_import_UV and the value that is created from that string #
####################################################################

my @uv = (1234567890, 876543210, ~0, 2233445566);
my $bits = $Config{ivsize} * 8; # size of UV in bits.

$expected =  Math::GMPz->new($uv[3]) +
            (Math::GMPz->new($uv[2]) <<  $bits) +
            (Math::GMPz->new($uv[1]) << ($bits * 2)) +
            (Math::GMPz->new($uv[0]) << ($bits * 3));

$size = $Config{ivsize}; # We now specify multi-byte words.

# Because we now have multi-byte words, the value of $endian becomes
# significant. A value of +1 will read the most significant byte first,
# whereas a value of -1 will read the least significant byte first.
# A value of 0, is equivalent to +1 on a big endian architecture, and
# equivalent to -1 on a little endian architecture.
# For portability, we leave $endian set to zero.

Rmpz_import_UV($got, scalar(@uv), $order, $size, $endian, $nails, \@uv);

cmp_ok($got, '==', $expected, "Rmpz_import_UV calculations agree");

##########################################################################
# Now check that we can retrieve the original array using Rmpz_export_UV #
##########################################################################

my @ret = Rmpz_export_UV($order, $size, $endian, $nails, $got);

is_deeply(\@ret, \@uv, "array retrieval succeeds");


####################################################################
# Next we'll deal with an array of numbers, all less than 2 ** 16, #
# treating them as 16-bit integers rather than $Config{ivsize}-bit #
# integers.                                                        #
####################################################################

@uv = (57840, 9271, 37925, 52962);

$expected =  Math::GMPz->new($uv[3]) +
            (Math::GMPz->new($uv[2]) <<  16) +
            (Math::GMPz->new($uv[1]) << (16 * 2)) +
            (Math::GMPz->new($uv[0]) << (16 * 3));

# Set $nails such that all but the 16 least siginificant
# bits of each IV will be ignored:

$nails = $bits - 16;

Rmpz_import_UV($got, scalar(@uv), $order, $size, $endian, $nails, \@uv);

cmp_ok($got, '==', $expected, "Rmpz_import_UV correctly handles 16-bit values");

@ret = Rmpz_export_UV($order, $size, $endian, $nails, $got);

is_deeply(\@ret, \@uv, "array retrieval of 16-bit values succeeds");

done_testing();
