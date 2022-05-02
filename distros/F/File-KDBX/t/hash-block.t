#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon qw(:no_warnings_test);

use File::KDBX::Util qw(can_fork);
use IO::Handle;
use File::KDBX::IO::HashBlock;
use Test::More;

{
    my $expected_plaintext = 'Tiny food from Spain!';

    pipe(my $read, my $write) or die "pipe failed: $!\n";

    $write = File::KDBX::IO::HashBlock->new($write, block_size => 3);
    print $write $expected_plaintext;
    close($write) or die "close failed: $!";

    $read = File::KDBX::IO::HashBlock->new($read);
    my $plaintext = do { local $/; <$read> };
    close($read);

    is $plaintext, $expected_plaintext, 'Hash-block just a little bit';
}

SKIP: {
    skip 'fork required to test long data streams' if !can_fork;

    my $expected_plaintext = "\x64" x (1024*1024*12 - 57);

    local $SIG{CHLD} = 'IGNORE';
    pipe(my $read, my $write) or die "pipe failed: $!\n";

    defined(my $pid = fork) or die "fork failed: $!\n";
    if ($pid == 0) {
        $write = File::KDBX::IO::HashBlock->new($write);
        print $write $expected_plaintext;
        close($write) or die "close failed: $!";
        exit;
        # require POSIX;
        # POSIX::_exit(0);
    }

    $read = File::KDBX::IO::HashBlock->new($read);
    my $plaintext = do { local $/; <$read> };
    close($read);

    is $plaintext, $expected_plaintext, 'Hash-block a lot';
}

subtest 'Error handling' => sub {
    pipe(my $read, my $write) or die "pipe failed: $!\n";

    $read = File::KDBX::IO::HashBlock->new($read);

    print $write 'blah blah blah';
    close($write) or die "close failed: $!";

    is $read->error, '', 'Read handle starts out fine';
    my $data = do { local $/; <$read> };
    is $read->error, 1, 'Read handle can enter an error state';

    like $File::KDBX::IO::HashBlock::ERROR, qr/invalid block index/i, 'Error object is available';
};

done_testing;
