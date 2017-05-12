#!/usr/bin/env perl
use strict;
use warnings;

use Benchmark qw(timethese);
use Getopt::Long qw(GetOptions :config no_ignore_case);
use List::Util qw(max);

# Install Task::Digest
use Crypt::RIPEMD160      ();
use Digest::BLAKE         ();
use Digest::BMW           ();
use Digest::CubeHash      ();
use Digest::ECHO          ();
use Digest::Fugue         ();
use Digest::GOST          ();
use Digest::Groestl       ();
use Digest::Hamsi         ();
use Digest::JH            ();
use Digest::Keccak        ();
use Digest::Luffa         ();
use Digest::MD2           ();
use Digest::MD4           ();
use Digest::MD5           ();
use Digest::MD6           ();
use Digest::Perl::MD4     ();
use Digest::Perl::MD5     ();
use Digest::SHA           ();
use Digest::SHA1          ();
use Digest::SHA::PurePerl ();
use Digest::SHAvite3      ();
use Digest::SIMD          ();
use Digest::Shabal        ();
use Digest::Skein         ();
use Digest::Whirlpool     ();

my %opts = (
    iterations => -1,
    size       => 1,  # kB
);
GetOptions(\%opts, 'iterations|i=i', 'size|s=f',);

my $data = '01234567' x (128 * $opts{size});

my %digests = (
    blake_224    => sub { Digest::BLAKE::blake_224($data) },
    blake_256    => sub { Digest::BLAKE::blake_256($data) },
    blake_384    => sub { Digest::BLAKE::blake_384($data) },
    blake_512    => sub { Digest::BLAKE::blake_512($data) },
    bmw_224      => sub { Digest::BMW::bmw_224($data) },
    bmw_256      => sub { Digest::BMW::bmw_256($data) },
    bmw_384      => sub { Digest::BMW::bmw_384($data) },
    bmw_512      => sub { Digest::BMW::bmw_512($data) },
    cubehash_224 => sub { Digest::CubeHash::cubehash_224($data) },
    cubehash_256 => sub { Digest::CubeHash::cubehash_256($data) },
    cubehash_384 => sub { Digest::CubeHash::cubehash_384($data) },
    cubehash_512 => sub { Digest::CubeHash::cubehash_512($data) },
    echo_224     => sub { Digest::ECHO::echo_224($data) },
    echo_256     => sub { Digest::ECHO::echo_256($data) },
    echo_384     => sub { Digest::ECHO::echo_384($data) },
    echo_512     => sub { Digest::ECHO::echo_512($data) },
    fugue_224    => sub { Digest::Fugue::fugue_224($data) },
    fugue_256    => sub { Digest::Fugue::fugue_256($data) },
    fugue_384    => sub { Digest::Fugue::fugue_384($data) },
    fugue_512    => sub { Digest::Fugue::fugue_512($data) },
    gost         => sub { Digest::GOST::gost($data) },
    groestl_224  => sub { Digest::Groestl::groestl_224($data) },
    groestl_256  => sub { Digest::Groestl::groestl_256($data) },
    groestl_384  => sub { Digest::Groestl::groestl_384($data) },
    groestl_512  => sub { Digest::Groestl::groestl_512($data) },
    hamsi_224    => sub { Digest::Hamsi::hamsi_224($data) },
    hamsi_256    => sub { Digest::Hamsi::hamsi_256($data) },
    hamsi_384    => sub { Digest::Hamsi::hamsi_384($data) },
    hamsi_512    => sub { Digest::Hamsi::hamsi_512($data) },
    jh_224       => sub { Digest::JH::jh_224($data) },
    jh_256       => sub { Digest::JH::jh_256($data) },
    jh_384       => sub { Digest::JH::jh_384($data) },
    jh_512       => sub { Digest::JH::jh_512($data) },
    keccak_224   => sub { Digest::Keccak::keccak_224($data) },
    keccak_256   => sub { Digest::Keccak::keccak_256($data) },
    keccak_384   => sub { Digest::Keccak::keccak_384($data) },
    keccak_512   => sub { Digest::Keccak::keccak_512($data) },
    luffa_224    => sub { Digest::Luffa::luffa_224($data) },
    luffa_256    => sub { Digest::Luffa::luffa_256($data) },
    luffa_384    => sub { Digest::Luffa::luffa_384($data) },
    luffa_512    => sub { Digest::Luffa::luffa_512($data) },
    md2          => sub { Digest::MD2::md2($data) },
    md4          => sub { Digest::MD4::md4($data) },
    md5          => sub { Digest::MD5::md5($data) },
    md6_224      => sub { Digest::MD6::md6_224($data) },
    md6_256      => sub { Digest::MD6::md6_256($data) },
    md6_384      => sub { Digest::MD6::md6_384($data) },
    md6_512      => sub { Digest::MD6::md6_512($data) },
    perl_md4     => sub { Digest::Perl::MD4::md4($data) },
    perl_md5     => sub { Digest::Perl::MD4::md4($data) },
    perl_sha_1   => sub { Digest::SHA::PurePerl::sha1($data) },
    perl_sha_224 => sub { Digest::SHA::PurePerl::sha224($data) },
    perl_sha_256 => sub { Digest::SHA::PurePerl::sha256($data) },
    perl_sha_384 => sub { Digest::SHA::PurePerl::sha384($data) },
    perl_sha_512 => sub { Digest::SHA::PurePerl::sha512($data) },
    ripemd_160   => sub {
        my $c = Crypt::RIPEMD160->new; $c->add($data); $c->digest;
    },
    sha1_sha_1   => sub { Digest::SHA1::sha1($data) },
    sha_sha_1    => sub { Digest::SHA::sha1($data) },
    sha_224      => sub { Digest::SHA::sha224($data) },
    sha_256      => sub { Digest::SHA::sha384($data) },
    sha_384      => sub { Digest::SHA::sha256($data) },
    sha_512      => sub { Digest::SHA::sha512($data) },
    shabal_224   => sub { Digest::Shabal::shabal_224($data) },
    shabal_256   => sub { Digest::Shabal::shabal_256($data) },
    shabal_384   => sub { Digest::Shabal::shabal_384($data) },
    shabal_512   => sub { Digest::Shabal::shabal_512($data) },
    shavite3_224 => sub { Digest::SHAvite3::shavite3_224($data) },
    shavite3_256 => sub { Digest::SHAvite3::shavite3_256($data) },
    shavite3_384 => sub { Digest::SHAvite3::shavite3_384($data) },
    shavite3_512 => sub { Digest::SHAvite3::shavite3_512($data) },
    simd_224     => sub { Digest::SIMD::simd_224($data) },
    simd_256     => sub { Digest::SIMD::simd_256($data) },
    simd_384     => sub { Digest::SIMD::simd_384($data) },
    simd_512     => sub { Digest::SIMD::simd_512($data) },
    skein_256    => sub { Digest::Skein::skein_256($data) },
    skein_512    => sub { Digest::Skein::skein_512($data) },
    skein_1024   => sub { Digest::Skein::skein_1024($data) },
    whirlpool    => sub { Digest::Whirlpool->new->add($data)->digest },
);

my $times = timethese -1, \%digests, 'none';

my @info;
my ($max_name_len, $max_rate_len, $max_bw_len) = (0, 0, 0);

while (my ($name, $info) = each %$times) {
    my ($duration, $cycles) = @{$info}[ 1, 5 ];
    my $rate = sprintf '%.0f', $cycles / $duration;
    my $bw = $rate * $opts{size} / 1024;
    $bw = sprintf int $bw ? '%.0f' : '%.2f', $bw;

    push @info, [$name, $rate, $bw];

    $max_name_len = max $max_name_len, length($name);
    $max_rate_len = max $max_rate_len, length($rate);
    $max_bw_len   = max $max_bw_len,   length($bw);
}

for my $rec (sort { $b->[1] <=> $a->[1] } @info) {
    my ($name, $rate, $bw) = @$rec;

    my $name_padding = $max_name_len - length($name);

    printf "%s%s %${max_rate_len}s/s  %${max_bw_len}s MB/s\n",
        $name, ' 'x$name_padding, $rate, $bw;
}
