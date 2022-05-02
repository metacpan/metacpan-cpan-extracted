#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon qw(:no_warnings_test);

use File::KDBX::IO::HmacBlock;
use File::KDBX::Util qw(can_fork);
use IO::Handle;
use Test::More;

my $KEY = "\x01" x 64;

{
    my $expected_plaintext = 'Tiny food from Spain!';

    pipe(my $read, my $write) or die "pipe failed: $!\n";

    $write = File::KDBX::IO::HmacBlock->new($write, block_size => 3, key => $KEY);
    print $write $expected_plaintext;
    close($write) or die "close failed: $!";

    $read = File::KDBX::IO::HmacBlock->new($read, key => $KEY);
    my $plaintext = do { local $/; <$read> };
    close($read);

    is $plaintext, $expected_plaintext, 'HMAC-block just a little bit';

    is $File::KDBX::IO::HmacBlock::ERROR, undef, 'No error when successful';
}

SKIP: {
    skip 'fork required to test long data streams' if !can_fork;

    my $expected_plaintext = "\x64" x (1024*1024*12 - 57);

    local $SIG{CHLD} = 'IGNORE';
    pipe(my $read, my $write) or die "pipe failed: $!\n";

    defined(my $pid = fork) or die "fork failed: $!\n";
    if ($pid == 0) {
        $write = File::KDBX::IO::HmacBlock->new($write, key => $KEY);
        print $write $expected_plaintext;
        close($write) or die "close failed: $!";
        exit;
        # require POSIX;
        # POSIX::_exit(0);
    }

    $read = File::KDBX::IO::HmacBlock->new($read, key => $KEY);
    my $plaintext = do { local $/; <$read> };
    close($read);

    is $plaintext, $expected_plaintext, 'HMAC-block a lot';
}

subtest 'Error handling' => sub {
    pipe(my $read, my $write) or die "pipe failed: $!\n";

    $read = File::KDBX::IO::HmacBlock->new($read, key => $KEY);

    print $write 'blah blah blah';
    close($write) or die "close failed: $!";

    is $read->error, '', 'Read handle starts out fine';
    my $data = do { local $/; <$read> };
    is $read->error, 1, 'Read handle can enter an error state';

    like $File::KDBX::IO::HmacBlock::ERROR, qr/failed to read HMAC/i, 'Error object is available';
};

done_testing;
