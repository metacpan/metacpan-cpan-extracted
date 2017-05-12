#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 15;
use Devel::StackTrace::WithLexicals;

my $stack = Devel::StackTrace::WithLexicals->new(no_refs => 1);
is($stack->frame_count, 1);

my $frame = $stack->frame(0);
is_deeply($frame->lexicals, {});

my @array = (1, 2);
my %hash = (key => 'value');
my $aref = [1, 2];
my $href = {key => 'value'};

my $stack2 = Devel::StackTrace::WithLexicals->new(no_refs => 1);
is($stack2->frame_count, 1);

my $frame2 = $stack2->frame(0);
is(ref($frame2->lexicals->{'$stack'}), '');
is(ref($frame2->lexicals->{'$frame'}), '');
is(ref($frame2->lexicals->{'@array'}), '');
is(ref($frame2->lexicals->{'%hash'}), '');
is(ref($frame2->lexicals->{'$aref'}), '');
is(ref($frame2->lexicals->{'$href'}), '');

like($frame2->lexicals->{'$stack'}, qr/^Devel::StackTrace::WithLexicals=HASH\(0x\w+\)$/);
like($frame2->lexicals->{'$frame'}, qr/^Devel::StackTrace::WithLexicals::Frame=HASH\(0x\w+\)$/);
like($frame2->lexicals->{'@array'}, qr/^ARRAY\(0x\w+\)$/);
like($frame2->lexicals->{'%hash'}, qr/^HASH\(0x\w+\)$/);
like($frame2->lexicals->{'$aref'}, qr/^ARRAY\(0x\w+\)$/);
like($frame2->lexicals->{'$href'}, qr/^HASH\(0x\w+\)$/);

