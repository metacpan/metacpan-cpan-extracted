#!/usr/bin/env perl

use warnings;
use strict;

use lib 't/lib';
use TestCommon;

use Crypt::Digest qw(digest_data);
use Crypt::PRNG qw(random_bytes);
use Crypt::Misc qw(decode_b64);
use File::KDBX::Key;
use File::KDBX::Util qw(:erase :load);
use File::KDBX;
use IO::Handle;
use List::Util qw(max);
use POSIX ();
use Scalar::Util qw(looks_like_number);
use Scope::Guard;
use Test::More 1.001004_001;

BEGIN {
    if (!$ENV{AUTHOR_TESTING}) {
        plan skip_all => 'AUTHOR_TESTING required to test memory protection';
        exit;
    }
    if (!can_fork || !try_load_optional('POSIX::1003')) {
        plan skip_all => 'fork and POSIX::1003 required to test memory protection';
        exit;
    }
    POSIX::1003->import(':rlimit');
}

my $BLOCK_SIZE = 8196;

-e 'core' && die "Remove or move the core dump!\n";
my $cleanup = Scope::Guard->new(sub { unlink('core') });

my ($cur, $max, $success) = getrlimit('RLIMIT_CORE');
$success or die "getrlimit failed: $!\n";
if ($cur < 1<<16) {
    setrlimit('RLIMIT_CORE', RLIM_INFINITY, RLIM_INFINITY) or die "setrlimit failed: $!\n";
}

my $SECRET = 'c3VwZXJjYWxpZnJhZ2lsaXN0aWM=';
my $SECRET_SHA256 = 'y1cOWidI80n5EZQx24NrOiP9tlca/uNMBDLYciDyQxs=';

for my $test (
    {
        test    => 'secret in scope',
        run     => sub {
            my $secret = decode_b64($SECRET);
            dump_core();
        },
        strings => [
            $SECRET => 1,
        ],
    },
    {
        test    => 'erased secret',
        run     => sub {
            my $secret = decode_b64($SECRET);
            erase $secret;
            dump_core();
        },
        strings => [
            $SECRET => 0,
        ],
    },
    {
        test    => 'Key password',
        run     => sub {
            my $password = decode_b64($SECRET);
            my $key = File::KDBX::Key->new($password);
            erase $password;
            dump_core();
        },
        strings => [
            $SECRET => 0,
        ],
    },
    {
        test    => 'Key password, raw key shown',
        run     => sub {
            my $password = decode_b64($SECRET);
            my $key = File::KDBX::Key->new($password);
            erase $password;
            $key->show;
            dump_core();
        },
        strings => [
            $SECRET         => 0,
            $SECRET_SHA256  => 1,
        ],
    },
    {
        test    => 'Key password, raw key hidden',
        run     => sub {
            my $password = decode_b64($SECRET);
            my $key = File::KDBX::Key->new($password);
            erase $password;
            $key->show->hide for 0..500;
            dump_core();
        },
        strings => [
            $SECRET         => 0,
            $SECRET_SHA256  => 0,
        ],
    },
    {
        test    => 'protected strings and keys',
        run     => sub {
            my $kdbx = File::KDBX->load(testfile('MemoryProtection.kdbx'), 'masterpw');
            dump_core();
        },
        strings => [
            'TXkgcGFzc3dvcmQgaXMgYSBzZWNyZXQgdG8gZXZlcnlvbmUu' => 0, # Password
            'QSB0cmVhc3VyZSBtYXAgaXMgb24gdGhlIGJhY2sgb2YgdGhlIERlY2xhcmF0aW9uIG9mIEluZGVwZW5kZW5jZS4=' => 0,
            # Secret A:
            'SmVmZnJleSBFcHN0ZWluIGRpZG4ndCBraWxsIGhpbXNlbGYu' => 0, # Secret B
            'c3VwZXJjYWxpZnJhZ2lsaXN0aWNleHBpYWxpZG9jaW91cw==' => 1, # Nonsecret
            'SlHA3Eyhomr/UQ6vznWMRZtxlrqIm/tM3qVZv7G31DU=' => 0, # Final key
            'LuVqNfGluvLPcg2W699/Q6WGxIztX7Jvw0ONwQEi/Jc=' => 0, # Transformed key
            # HMAC key:
            'kDEMVEcGR32UXTwG8j3SxsfdF+l124Ni6iHeogCWGd2z0KSG5PosDTloxC0zg7Ucn2CNR6f2wpgzcVGKmDNFCA==' => 0,
            # Inner random stream key:
            'SwJSukmQdZKpHm8PywqLu1EHfUzS/gyJsg61Cm74YeRJeOpDlFblbVd5d4p+lU2/7Q28Vk4j/E2RRMC81DXdUw==' => 1,
            'RREzJd4fKHtFkjRIi+xucGPW2q+mov+LRWL4RkPql7Y=' => 1, # Random stream key (actual)
        ],
    },
    {
        test    => 'inner random stream key replaced',
        run     => sub {
            my $kdbx = File::KDBX->load(testfile('MemoryProtection.kdbx'), 'masterpw');
            $kdbx->inner_random_stream_key("\1" x 64);
            dump_core();
        },
        strings => [
            # Inner random stream key:
            # FIXME - there is second copy of this key somewhere... in another SvPV?
            'SwJSukmQdZKpHm8PywqLu1EHfUzS/gyJsg61Cm74YeRJeOpDlFblbVd5d4p+lU2/7Q28Vk4j/E2RRMC81DXdUw==' => undef,
        ],
    },
    {
        test    => 'protected strings revealed',
        run     => sub {
            my $kdbx = File::KDBX->load(testfile('MemoryProtection.kdbx'), 'masterpw');
            $kdbx->unlock;
            dump_core();
        },
        strings => [
            'TXkgcGFzc3dvcmQgaXMgYSBzZWNyZXQgdG8gZXZlcnlvbmUu' => 1, # Password
            # Secret A:
            'QSB0cmVhc3VyZSBtYXAgaXMgb24gdGhlIGJhY2sgb2YgdGhlIERlY2xhcmF0aW9uIG9mIEluZGVwZW5kZW5jZS4=' => 1,
            'SmVmZnJleSBFcHN0ZWluIGRpZG4ndCBraWxsIGhpbXNlbGYu' => 1, # Secret B
            'c3VwZXJjYWxpZnJhZ2lsaXN0aWNleHBpYWxpZG9jaW91cw==' => 1, # Nonsecret
            'RREzJd4fKHtFkjRIi+xucGPW2q+mov+LRWL4RkPql7Y=' => 0, # Random stream key (actual)
        ],
    },
    {
        test    => 'protected strings previously-revealed',
        run     => sub {
            my $kdbx = File::KDBX->load(testfile('MemoryProtection.kdbx'), 'masterpw');
            $kdbx->unlock;
            $kdbx->lock;
            dump_core();
        },
        strings => [
            'TXkgcGFzc3dvcmQgaXMgYSBzZWNyZXQgdG8gZXZlcnlvbmUu' => 0, # Password
            # Secret A:
            'QSB0cmVhc3VyZSBtYXAgaXMgb24gdGhlIGJhY2sgb2YgdGhlIERlY2xhcmF0aW9uIG9mIEluZGVwZW5kZW5jZS4=' => 0,
            'SmVmZnJleSBFcHN0ZWluIGRpZG4ndCBraWxsIGhpbXNlbGYu' => 0, # Secret B
            'c3VwZXJjYWxpZnJhZ2lsaXN0aWNleHBpYWxpZG9jaW91cw==' => 1, # Nonsecret
            'RREzJd4fKHtFkjRIi+xucGPW2q+mov+LRWL4RkPql7Y=' => 0, # Random stream key (actual)
        ],
    },
) {
    my ($description, $run, $strings) = @$test{qw(test run strings)};

    subtest "Dump core with $description" => sub {
        my @strings = @_;
        my $num_strings = @strings / 2;
        plan tests => 2 + $num_strings * 2;

        my (@encoded_strings, @expected);
        while (@strings) {
            my ($string, $expected) = splice @strings, 0, 2;
            push @encoded_strings, $string;
            push @expected, $expected;
        }

        my ($dumped, $has_core, @matches) = run_test($run, @encoded_strings);

        ok $dumped, 'Test process signaled that it core-dumped';
        ok $has_core, 'Found core dump' or return;

        note sprintf('core dump is %.1f MiB', (-s 'core')/1048576);

        for (my $i = 1; $i <= $num_strings; ++$i) {
            my $count    = $matches[$i - 1];
            my $string   = $encoded_strings[$i - 1];
            my $expected = $expected[$i - 1];

            ok defined $count, "[#$i] Got result from test environment";

            TODO: {
                local $TODO = 'Unprotected memory!' if !defined $expected;
                if ($expected) {
                    ok 0 < $count, "[#$i] String FOUND"
                        or diag "Found $count copies of string #$i\nString: $string";
                }
                else {
                    is $count, 0, "[#$i] String MISSING"
                        or diag "Found $count copies of string #$i\nString: $string";
                }
            }
        }
    }, @$strings;
}

done_testing;
exit;

##############################################################################

sub dump_core { kill 'QUIT', $$ }

sub file_grep {
    my $filepath = shift;
    my @strings = @_;

    my $counter = 0;
    my %counts = map { $_ => $counter++ } @strings;
    my @counts = map { 0 } @strings;

    my $pattern = join('|', map { quotemeta($_) } @strings);

    my $overlap = (max map { length } @strings) - 1;

    open(my $fh, '<:raw', $filepath) or die "open failed: $!\n";

    my $previous;
    while (read $fh, my $block, $BLOCK_SIZE) {
        substr($block, 0, 0, substr($previous, -$overlap)) if defined $previous;

        while ($block =~ /($pattern)/gs) {
            ++$counts[$counts{$1}];
        }
        $previous = substr($block, $overlap);
    }
    die "read error: $!" if $fh->error;

    return @counts;
}

sub run_test {
    my $code = shift;
    my @strings = @_;

    my $seed = random_bytes(32);

    pipe(my $read, my $write) or die "pipe failed: $!\n";

    defined(my $pid = fork) or die "fork failed: $!\n";
    if (!$pid) { # child
        close($read);

        my $exit_status = run_doomed_child($code, $seed);
        my $dumped = $exit_status & 127 && $exit_status & 128;

        my @decoded_strings = map { decode_b64($_) } @strings;

        my @matches = file_grep('core', @decoded_strings);
        print $write join('|', $dumped, -f 'core' ? 1 : 0, @matches);
        close($write);

        POSIX::_exit(0);
    }

    close($write);
    my $results = do { local $/; <$read> };

    waitpid($pid, 0);
    my $exit_status = $? >> 8;
    $exit_status == 0 or die "test environment exited non-zero: $exit_status\n";

    return split(/\|/, $results);
}

sub run_doomed_child {
    my $code = shift;
    my $seed = shift;

    unlink('core') or die "unlink failed: $!\n" if -f 'core';

    defined(my $pid = fork) or die "fork failed: $!\n";
    if (!$pid) { # child
        $code->();
        dump_core();        # doomed
        POSIX::_exit(1);    # paranoid
    }

    waitpid($pid, 0);
    return $?;
}
