#!perl
use v5.10.1;
use strict;
use warnings;
use Test::LongString lcss => 0;
use Test::More;

plan tests => 9;

use FTN::Crypt;

my $msg_file = 't/data/msg.txt';
open my $fin, $msg_file or BAIL_OUT("Cannot open message file `$msg_file': $!");
binmode $fin;
my $msg = <$fin>;
close $fin;

# Test #1
my $obj = new_ok('FTN::Crypt', [
    Nodelist => 't/data/nodelist.*',
    Pointlist => [
        't/data/pointlist.*',
        't/data/pointlist_zone66',
    ],
    Pubring  => 't/data/pubring.gpg',
    Secring  => 't/data/secring.gpg',
], 'Create FTN::Crypt object') or BAIL_OUT(FTN::Crypt->error);

# Test #2
can_ok($obj, qw/encrypt_message decrypt_message/) or BAIL_OUT('Required methods are unsupported by FTN::Crypt');

# Test #3
my $encrypted = $obj->encrypt_message(
    Address => '99:8877/2',
    Message => $msg,
);
ok($encrypted, 'Encryption') or diag('Encryption error: ', $obj->error);

# Test #4
contains_string($encrypted, 'ENC: PGP5', 'Has ENC kludge');

# Test #5
contains_string($encrypted, '-----BEGIN PGP MESSAGE-----', 'Has PGP message');

# Test #6
my $decrypted = $obj->decrypt_message(
    Address => '99:8877/2',
    Message => $encrypted,
    Passphrase => 'test passphrase',
);
ok($decrypted, 'Decryption') or diag('Decryption error: ', $obj->error);

# Test #7
lacks_string($decrypted, 'ENC: PGP5', 'Has no ENC kludge');

# Test #8
lacks_string($decrypted, '-----BEGIN PGP MESSAGE-----', 'Has no PGP message');

# Test #9
is_string($decrypted, $msg, 'Decrypted is the same as original');
