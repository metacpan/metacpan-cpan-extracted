#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Raw::Hash;

# implementation() names the code computing each algorithm; FRH_PORTABLE in
# the environment (read when the module loads) keeps the portable C; and the
# two paths give the same digests.

my $impl = File::Raw::Hash::implementation();
is ref $impl, 'HASH', 'implementation() is a hashref';
is_deeply [ sort keys %$impl ], [qw(blake3 crc32 md5 sha1 sha256 sha512 xxh64)], 'one entry per algorithm';
like $impl->{$_}, qr/\A(?:portable|armv8)\z/, "$_: $impl->{$_}" for qw(sha1 sha256);
is $impl->{$_}, 'portable', "$_ is portable" for qw(md5 sha512 crc32 xxh64 blake3);

my $other = do {
    local $ENV{FRH_PORTABLE} = $ENV{FRH_PORTABLE} ? 0 : 1;
    my $code = 'use File::Raw::Hash; my $i = File::Raw::Hash::implementation();'
             . ' srand 7; for my $len (0, 1, 55, 56, 63, 64, 65, 1000, 70000) {'
             . ' my $d = join "", map { chr int rand 256 } 1 .. $len;'
             . ' print "$len $i->{sha256} $i->{sha1} ", File::Raw::Hash::_test_feed("sha256", $d, 3, 17, 64),'
             . ' " ", File::Raw::Hash::_test_feed("sha1", $d, 5, 64, 1), "\n" }';
    my @inc = map { "-I$_" } @INC;
    [ `$^X @inc -e '$code'` ];
};
is scalar @$other, 9, 'the other path ran in a child';
srand 7;
for my $line (@$other) {
    my ($len, $sha256_impl, $sha1_impl, $d256, $d1) = split ' ', $line;
    my $d = join '', map { chr int rand 256 } 1 .. $len;
    is $d256, File::Raw::Hash::_test_feed('sha256', $d, 0), "sha256 of $len bytes: $sha256_impl and $impl->{sha256} agree";
    is $d1,   File::Raw::Hash::_test_feed('sha1',   $d, 0), "sha1 of $len bytes: $sha1_impl and $impl->{sha1} agree";
}
if ($ENV{FRH_PORTABLE}) {
    is $impl->{sha256}, 'portable', 'FRH_PORTABLE=1: sha256 is portable';
}
my ($child_impl) = map { (split ' ')[1] } $other->[0];
ok $ENV{FRH_PORTABLE} ? 1 : $child_impl eq 'portable', 'the child with FRH_PORTABLE=1 reports portable';

done_testing;
