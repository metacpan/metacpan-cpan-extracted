# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Digest-PSHA.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use Test::More tests => 1;
BEGIN { use_ok('Digest::PSHA') };

#########################

use Digest::PSHA qw / p_sha1 p_sha256 /;

my $secret = ' 55 aa eb f9 51 b3 ed ef 84 c6 02 c5 f1 72 c1 aa ';
my $salt   = ' 13 e6 db 5d c1 23 5c f6 4f 89 ce 70 41 0c 52 8d ';

my $key1 = ' fb 8e d7 e6 d3 98 0b b6 88 57 fc 2f a9 47 ce 6d ';
my $key2 = ' 20 0b dd 3a 92 1d 94 9c e9 95 36 75 dd 6e a6 eb ';
my $key3 = ' e4 5a 9a 53 44 c3 ec cf f8 8b d6 21 d4 e1 be c4 ';

my $key4 = ' b8ff1523b6b8ee1bc084b961fdf0632e0d9b1d7817a23721da98145865b9f27b '; 
my $key5 = ' 2d787bf8b43eb929f33c6053e80a502f22c8d2af494c8ae393a93961d85f5f57 ';
my $key6 = ' 652c7daa552e702c6b39f223d0cf76fb6dbd1c87003cc12abfc307cf0c83de54 ';

print STDERR "\n", '   secret: ', $secret , "\n";
print STDERR '   salt  : ', $salt , "\n";


$_ = $secret; s/\s//g;
my $secret_bin = pack ("H*" , $_ );
$_ = $salt; s/\s//g;
my $salt_bin = pack ("H*" , $_ );


print STDERR "   +++ P_SHA-1 +++\n";

# 1
my $key_exp = $key1; $key_exp =~ s/\s//g;
my $key_calc = unpack ('H*', p_sha1 ( $secret_bin, $salt_bin, 128,0) );
_compare_or_die();

# 2
$key_exp = $key2; $key_exp =~ s/\s//g;
$key_calc = unpack ('H*', p_sha1 ( $secret_bin, $salt_bin, 128,128) );
_compare_or_die();

# 3
$key_exp = $key3; $key_exp =~ s/\s//g;
$key_calc = unpack ('H*', p_sha1 ( $secret_bin, $salt_bin, 128,256) );
_compare_or_die();


print STDERR "   +++ P_SHA256 +++\n";

$secret_bin .= $secret_bin;
$salt_bin .= $salt_bin;

# 4
$key_exp = $key4; $key_exp =~ s/\s//g;
$key_calc = unpack ('H*', p_sha256 ( $secret_bin, $salt_bin, 256,0) );
_compare_or_die();

# 5
$key_exp = $key5; $key_exp =~ s/\s//g;
$key_calc = unpack ('H*', p_sha256 ( $secret_bin, $salt_bin, 256,256) );
_compare_or_die();

# 5
$key_exp = $key6; $key_exp =~ s/\s//g;
$key_calc = unpack ('H*', p_sha256 ( $secret_bin, $salt_bin, 256,512) );
_compare_or_die();

exit 0;

sub _compare_or_die
{
    print STDERR "$key_calc == $key_exp   => ";

    if ($key_exp ne $key_calc ) {
        die "NO\n";
    } else { 
        print STDERR "YES\n";
    }
}

__END__
