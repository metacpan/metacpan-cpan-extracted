use Test::More;
use Git::Crypt;
use Crypt::CBC;
use Digest::SHA1 qw|sha1_hex|;
use IO::All;

my $files = [
    {
        file => './t/file1',
        is_encrypted => 0,
    },
    {
        file => './t/file2',
        is_encrypted => 0,
    },
];

my $digest = {};
for ( @{ $files } ) {
    $digest->{ $_->{ file } } = sha1_hex( io( $_->{file} )->getlines );
}

my $gitcrypt = Git::Crypt->new(
    files => $files,
    cipher => Crypt::CBC->new(
        -key      => 'a very very very veeeeery very long key',
        -cipher   => 'Blowfish',
        -salt     => pack("H16", "very very very very loooong salt")
    )
);

$gitcrypt->encrypt;
$gitcrypt->decrypt;

for ( keys %$digest ) {
    ok( sha1_hex(io($_)->getlines) eq $digest->{ $_ }, 'same digest as the original' );
}

done_testing;
