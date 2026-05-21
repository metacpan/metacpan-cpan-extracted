#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# Two byte-transform plugins composed in a chain — the canonical
# "encoding stack" pattern. We use a pair of involutive transforms
# (rot13 + reverse) so the WRITE chain undoes itself when run as the
# READ chain on the same file. That gives us a real round-trip
# property without depending on Compress::Raw::Zlib or MIME::Base64.

my $dir = tempdir(CLEANUP => 1);

# Both plugins are pure-byte transforms (input bytes -> output bytes),
# so they're chain-friendly in any position.

File::Raw::register_plugin('rot13', {
    read  => sub { my ($p, $b, $o) = @_; my $x = $b; $x =~ tr/A-Za-z/N-ZA-Mn-za-m/; $x },
    write => sub { my ($p, $b, $o) = @_; my $x = $b; $x =~ tr/A-Za-z/N-ZA-Mn-za-m/; $x },
});

File::Raw::register_plugin('reverse_bytes', {
    read  => sub { my ($p, $b, $o) = @_; scalar reverse $b },
    write => sub { my ($p, $b, $o) = @_; scalar reverse $b },
});

my $payload = 'Hello, World!';
my $f = "$dir/round.bin";

# WRITE side:
#   chain = [rot13, reverse_bytes]
#   reverse first  (innermost)  -> "!dlroW ,olleH"
#   then  rot13 on the result   -> "!qyebJ ,byyrU"
# What lands on disk is the rot13 of the reverse.

File::Raw::spew($f, $payload, plugin => ['rot13', 'reverse_bytes']);

is(File::Raw::slurp($f),
   do { my $x = scalar reverse $payload; $x =~ tr/A-Za-z/N-ZA-Mn-za-m/; $x },
   'WRITE chain composes inner-first');

# READ side:
#   chain = [rot13, reverse_bytes]
#   rot13 first              -> reverses the rot13 we did on disk
#   then reverse the result  -> reverses the reverse we did first
# Net: original payload restored.

is(File::Raw::slurp($f, plugin => ['rot13', 'reverse_bytes']),
   $payload,
   'symmetric chain round-trips: same array, opposite directions');

# Sanity: single-element pass-through with one byte plugin should be
# semantically identical to applying that plugin once.
my $g = "$dir/single.bin";
File::Raw::spew($g, 'abc', plugin => ['rot13']);
is(File::Raw::slurp($g), 'nop',
   'single-element [rot13] applies rot13 to written bytes');
is(File::Raw::slurp($g, plugin => ['rot13']), 'abc',
   'and reading via [rot13] reverses it');

done_testing;
