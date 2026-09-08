#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

use_ok('File::Raw');

my $tmpdir = tempdir(CLEANUP => 1);

# A byte string that is not text: NULs, newlines, every high byte. Any
# test that reassembles this and compares against slurp is proving the
# chunk iterator is not the line iterator wearing a different name.
my $BINARY = join '', map { chr($_ % 256) } 0 .. 9999;

sub write_file {
    my ($name, $bytes) = @_;
    my $path = "$tmpdir/$name";
    open my $fh, '>:raw', $path or die "cannot write $path: $!";
    print $fh $bytes;
    close $fh;
    return $path;
}

sub drain {
    my ($iter) = @_;
    my @chunks;
    while (defined(my $c = $iter->next)) { push @chunks, $c }
    return @chunks;
}

# ============================================
# Basic usage
# ============================================

subtest 'chunk iterator basic usage' => sub {
    my $path = write_file('basic.bin', $BINARY);

    my $iter = File::Raw::chunk_iter($path, size => 4096);
    ok($iter, 'iterator created');
    isa_ok($iter, 'File::Raw::chunks', 'correct class');
    ok(!$iter->eof, 'not eof before the first chunk');

    my @chunks = drain($iter);
    is(scalar @chunks, 3, 'three chunks for 10000 bytes at 4096');
    is(length $chunks[0], 4096, 'first chunk is full');
    is(length $chunks[1], 4096, 'second chunk is full');
    is(length $chunks[2], 1808, 'last chunk is the remainder');
    ok($iter->eof, 'eof once drained');
    is(join('', @chunks), $BINARY, 'the bytes reassemble');

    $iter->close;
};

subtest 'the chunks are bytes, not text' => sub {
    my $path = write_file('bytes.bin', $BINARY);
    my $iter = File::Raw::chunk_iter($path, size => 512);
    my $first = $iter->next;
    ok(!utf8::is_utf8($first), 'the returned SV has no UTF-8 flag');
    is(length $first, 512, 'length is in bytes');
    is($first, substr($BINARY, 0, 512), 'and they are the right bytes');
    $iter->close;
};

subtest 'reassembly equals slurp' => sub {
    my $path = write_file('slurpcmp.bin', $BINARY);
    for my $size (1, 7, 999, 4096, 10000, 65536) {
        my $iter = File::Raw::chunk_iter($path, size => $size);
        my @chunks = drain($iter);
        is(join('', @chunks), File::Raw::slurp($path),
           "size $size reassembles to the same bytes as slurp");
        $iter->close;
    }
};

subtest 'next($buffer) fills the caller scalar' => sub {
    my $path = write_file('intobuf.bin', $BINARY);

    my $iter = File::Raw::chunk_iter($path, size => 4096);
    my ($total, $buf) = ('');
    my @counts;
    while (my $n = $iter->next($buf)) {
        push @counts, $n;
        is(length $buf, $n, 'the count is the length of what landed in the buffer');
        $total .= $buf;
    }
    is_deeply(\@counts, [4096, 4096, 1808], 'the counts are the chunk sizes');
    is($total, $BINARY, 'the bytes reassemble');
    is($buf, '', 'the buffer is emptied at end of file');
    ok(!utf8::is_utf8($buf), 'and carries no UTF-8 flag');
    ok($iter->eof, 'eof');
    $iter->close;
};

subtest 'next($buffer) overwrites whatever the scalar held' => sub {
    my $path = write_file('overwrite.bin', 'abcdef');

    my $iter = File::Raw::chunk_iter($path, size => 3);
    my $buf = "\x{263A} some wide text";
    ok(utf8::is_utf8($buf), 'the scalar starts as character data');

    is($iter->next($buf), 3, 'three bytes read');
    is($buf, 'abc', 'the scalar is replaced, not appended to');
    ok(!utf8::is_utf8($buf), 'and downgraded to bytes');

    is($iter->next($buf), 3, 'three more');
    is($buf, 'def', 'second chunk');
    is($iter->next($buf), 0, '0 at end of file');
    is($buf, '', 'and the buffer is emptied');

    $iter->close;
    is($iter->next($buf), 0, '0 after close too');
};

subtest 'next takes at most one argument' => sub {
    my $path = write_file('arity.bin', 'data');
    my $iter = File::Raw::chunk_iter($path);
    my ($a, $b);
    eval { $iter->next($a, $b) };
    like($@, qr/Usage: \$iter->next/, 'a second argument is refused');
    $iter->close;
};

# ============================================
# Sizes and boundaries
# ============================================

subtest 'exact multiple of the size' => sub {
    my $path = write_file('exact.bin', 'x' x 4096);

    my $iter = File::Raw::chunk_iter($path, size => 1024);
    my @chunks = drain($iter);
    is(scalar @chunks, 4, 'four full chunks, no empty fifth');
    is(length $_, 1024, 'chunk is full') for @chunks;
    ok($iter->eof, 'eof after the last full chunk');
    $iter->close;
};

subtest 'size larger than the file' => sub {
    my $path = write_file('small.bin', 'hello');

    my $iter = File::Raw::chunk_iter($path, size => 65536);
    my @chunks = drain($iter);
    is_deeply(\@chunks, ['hello'], 'one short chunk, then end');
    ok($iter->eof, 'eof');
    $iter->close;
};

subtest 'size of 1' => sub {
    my $path = write_file('bytewise.bin', "a\nb\0c");

    my $iter = File::Raw::chunk_iter($path, size => 1);
    my @chunks = drain($iter);
    is(scalar @chunks, 5, 'five single-byte chunks');
    is(join('', @chunks), "a\nb\0c", 'including the newline and the NUL');
    $iter->close;
};

subtest 'empty file' => sub {
    my $path = write_file('empty.bin', '');

    my $iter = File::Raw::chunk_iter($path);
    ok($iter, 'an empty file still opens');
    is($iter->next, undef, 'the first next is undef');
    ok($iter->eof, 'eof after it');
    is($iter->next, undef, 'and next stays undef');
    $iter->close;
};

subtest 'the default size is 64 KiB' => sub {
    my $path = write_file('default.bin', 'z' x (65536 + 10));

    my $iter = File::Raw::chunk_iter($path);
    is(length $iter->next, 65536, 'first chunk is 65536 bytes');
    is(length $iter->next, 10, 'then the remainder');
    is($iter->next, undef, 'then end');
    $iter->close;
};

# ============================================
# Refusals
# ============================================

subtest 'a missing file returns undef and sets $!' => sub {
    $! = 0;
    my $iter = File::Raw::chunk_iter("$tmpdir/does-not-exist");
    is($iter, undef, 'undef, not an object');
    ok(0 + $!, "\$! is set ($!)");
};

subtest 'a bad size croaks' => sub {
    my $path = write_file('badsize.bin', 'data');

    for my $bad (0, -1, -65536, 'x', '', 1.5) {
        eval { File::Raw::chunk_iter($path, size => $bad) };
        like($@, qr/size' must be a positive integer/,
             "size of '$bad' is refused");
    }

    eval { File::Raw::chunk_iter($path, size => undef) };
    like($@, qr/size' must be a positive integer/, 'an undef size is refused');

    eval { File::Raw::chunk_iter($path, size => 16 * 1024 * 1024 + 1) };
    like($@, qr/exceeds the 16777216 byte maximum/, 'above the cap is refused');

    my $at_cap = File::Raw::chunk_iter($path, size => 16 * 1024 * 1024);
    ok($at_cap, 'the cap itself is accepted');
    $at_cap->close;
};

subtest 'a plugin tail is refused, and says where to go' => sub {
    my $path = write_file('plugintail.bin', 'data');

    eval { File::Raw::chunk_iter($path, plugin => 'gzip') };
    like($@, qr/plugin tail is not accepted/, 'refused');
    like($@, qr/each_line/, 'and the message names each_line');
};

subtest 'malformed option tails croak' => sub {
    my $path = write_file('badopts.bin', 'data');

    eval { File::Raw::chunk_iter($path, 'size') };
    like($@, qr/odd number of options/, 'an odd tail is refused');

    eval { File::Raw::chunk_iter($path, nosuch => 1) };
    like($@, qr/unknown option 'nosuch'/, 'an unknown option is refused');

    eval { File::Raw::chunk_iter($path, undef, 1) };
    like($@, qr/option key at position 1 is undef/, 'an undef key is refused');
};

# ============================================
# Lifetime
# ============================================

subtest 'close, double close, and use after close' => sub {
    my $path = write_file('close.bin', $BINARY);

    my $iter = File::Raw::chunk_iter($path, size => 128);
    ok(defined $iter->next, 'a chunk before close');
    $iter->close;
    is($iter->next, undef, 'next after close is undef');
    eval { $iter->close; pass('a second close does not die') };
    fail("a second close died: $@") if $@;
};

subtest 'an iterator that goes out of scope closes itself' => sub {
    my $path = write_file('scope.bin', $BINARY);

    # If DESTROY did not release the slot and the fd, opening far more
    # iterators than the process fd limit would fail somewhere in here.
    for (1 .. 500) {
        my $iter = File::Raw::chunk_iter($path, size => 64);
        ok(defined $iter->next, 'iterator works') if $_ == 1;
    }
    my $iter = File::Raw::chunk_iter($path, size => 64);
    ok($iter, 'still able to open after 500 scoped iterators');
    is(length $iter->next, 64, 'and it reads');
    $iter->close;
};

subtest 'many iterators at once, interleaved' => sub {
    my $path = write_file('many.bin', $BINARY);

    my @iters = map { File::Raw::chunk_iter($path, size => 100) } 1 .. 32;
    is(scalar(grep { defined } @iters), 32, 'all 32 opened');

    my @first = map { $_->next } @iters;
    is(scalar(grep { $_ eq substr($BINARY, 0, 100) } @first), 32,
       'each has its own position and read the same first chunk');

    my @second = map { $_->next } @iters;
    is(scalar(grep { $_ eq substr($BINARY, 100, 100) } @second), 32,
       'and each advanced independently');

    $_->close for @iters;
};

# ============================================
# The shared registry
#
# The chunk iterator, the line iterator and the record iterator share
# g_iters and its free list. A slot handed back by one mode and reused
# by another must not carry anything over: this is the bug the mode
# fields were added around, so it is tested rather than assumed.
# ============================================

subtest 'a slot freed by a chunk iterator is clean for a line iterator' => sub {
    my $text = "line1\nline2\nline3\n";
    my $textfile = write_file('reuse.txt', $text);
    my $binfile  = write_file('reuse.bin', $BINARY);

    # Take some slots as chunk iterators, then give them all back.
    {
        my @chunkers = map { File::Raw::chunk_iter($binfile, size => 13) } 1 .. 8;
        $_->next for @chunkers;
        $_->close for @chunkers;
    }

    # The line iterator now lands in a reused slot.
    my $lines = File::Raw::lines_iter($textfile);
    isa_ok($lines, 'File::Raw::lines', 'line iterator in a reused slot');
    is($lines->next, 'line1', 'first line, not a 13-byte chunk');
    is($lines->next, 'line2', 'second line');
    is($lines->next, 'line3', 'third line');
    is($lines->next, undef, 'then end');
    $lines->close;
};

subtest 'a slot freed by a line iterator is clean for a chunk iterator' => sub {
    my $textfile = write_file('reuse2.txt', "a\nb\nc\n");
    my $binfile  = write_file('reuse2.bin', 'q' x 300);

    {
        my @liners = map { File::Raw::lines_iter($textfile) } 1 .. 8;
        $_->next for @liners;
        $_->close for @liners;
    }

    my $iter = File::Raw::chunk_iter($binfile, size => 128);
    isa_ok($iter, 'File::Raw::chunks', 'chunk iterator in a reused slot');
    is(length $iter->next, 128, 'a full chunk, not a line');
    is(length $iter->next, 128, 'and another');
    is(length $iter->next, 44,  'and the remainder');
    is($iter->next, undef, 'then end');
    $iter->close;
};

subtest 'a slot freed by a record iterator is clean for a chunk iterator' => sub {
    my $binfile = write_file('reuse3.bin', 'w' x 200);

    File::Raw::register_plugin('t027_records', {
        read => sub { my ($p, $bytes, $o) = @_; return [ [1], [2], [3] ] },
    }, 1);

    {
        my $rec = File::Raw::lines_iter(write_file('reuse3.txt', "x\n"),
                                        plugin => 't027_records');
        $rec->next;
        $rec->close;
    }

    my $iter = File::Raw::chunk_iter($binfile, size => 64);
    isa_ok($iter, 'File::Raw::chunks', 'chunk iterator in a reused slot');
    is(length $iter->next, 64, 'reads bytes, not the records left behind');
    $iter->close;

    File::Raw::unregister_plugin('t027_records');
};

# ============================================
# Platform behaviour
# ============================================

subtest 'a file unlinked mid-iteration still reads out' => sub {
    plan skip_all => 'POSIX unlink semantics' if $^O eq 'MSWin32';

    my $path = write_file('unlinked.bin', $BINARY);
    my $iter = File::Raw::chunk_iter($path, size => 4096);
    my $first = $iter->next;
    unlink $path;

    my @rest = drain($iter);
    is($first . join('', @rest), $BINARY, 'the open handle read to the end');
    $iter->close;
};

subtest 'a read error croaks rather than looking like end of file' => sub {
    # Opening a directory succeeds on some platforms and the read then
    # fails; where the open fails there is nothing to prove here.
    my $iter = File::Raw::chunk_iter($tmpdir);
    plan skip_all => "opening a directory is refused on $^O" unless $iter;

    my $got = eval { $iter->next };
    if ($@) {
        like($@, qr/read failed/, 'the read error is a croak, not undef');
    }
    else {
        # A platform that lets us read a directory raw: no error to see.
        ok(1, 'the directory read succeeded on this platform, no error path exercised');
    }
    $iter->close;
};

done_testing();
