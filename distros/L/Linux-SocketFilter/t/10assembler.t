#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 24;

use Linux::SocketFilter::Assembler qw( assemble );
use Linux::SocketFilter qw( :bpf unpack_sock_filter SKF_NET_OFF );

sub u32($) { unpack "I", pack "i", shift() }

sub is_instr
{
   my ( $instr, @fields ) = @_;

   is_deeply( [ unpack_sock_filter( assemble( $instr ) ) ],
              [ @fields ],
              $instr );
}

# Various forms of literals
is_instr "LD 16",   BPF_LD|BPF_IMM, 0, 0, 16;
is_instr "LD 0x10", BPF_LD|BPF_IMM, 0, 0, 16;
is_instr "LD 020",  BPF_LD|BPF_IMM, 0, 0, 16;

# Whitespace agnostic
is_instr "LD    10", BPF_LD|BPF_IMM, 0, 0, 10;
is_instr "LD\t20",   BPF_LD|BPF_IMM, 0, 0, 20;
is_instr "   LD 30", BPF_LD|BPF_IMM, 0, 0, 30;

# Addressing forms
is_instr "LD BYTE[0]",       BPF_LD|BPF_ABS|BPF_B, 0, 0, 0;
is_instr "LD HALF[0]",       BPF_LD|BPF_ABS|BPF_H, 0, 0, 0;
is_instr "LD WORD[0]",       BPF_LD|BPF_ABS|BPF_W, 0, 0, 0;
is_instr "LD WORD[5]",       BPF_LD|BPF_ABS|BPF_W, 0, 0, 5;
is_instr "LD WORD[X+2]",     BPF_LD|BPF_IND|BPF_W, 0, 0, 2;
is_instr "LD WORD[NET+4]",   BPF_LD|BPF_ABS|BPF_W, 0, 0, u32 SKF_NET_OFF+4;
is_instr "LD WORD[NET+X+3]", BPF_LD|BPF_IND|BPF_W, 0, 0, u32 SKF_NET_OFF+3;

# Jump offsets
is_instr "JA 1",          BPF_JMP|BPF_JA,        0, 0, 1;
is_instr "JGT 100, 2, 3", BPF_JMP|BPF_JGT|BPF_K, 2, 3, 100;
is_instr "JGT X, 4, 5",   BPF_JMP|BPF_JGT|BPF_X, 4, 5, 0;

# Both forms of reg->reg
is_instr "TAX",   BPF_MISC|BPF_TAX, 0, 0, 0;
is_instr "LDX A", BPF_MISC|BPF_TAX, 0, 0, 0;
is_instr "TXA",   BPF_MISC|BPF_TXA, 0, 0, 0;
is_instr "LD X",  BPF_MISC|BPF_TXA, 0, 0, 0;

sub is_instrs
{
   my ( $name, $text, @instrs ) = @_;

   is_deeply( [ map { [ unpack_sock_filter $_ ] } unpack "(a8)*", assemble( $text ) ],
              [ @instrs ],
              $name );
}

is_instrs "Empty", "", ();

is_instrs "Comment", "; here is a comment", ();

is_instrs "One instruction", "LD 100",
   [ BPF_LD|BPF_IMM, 0, 0, 100 ];

is_instrs "Two instructions", "LDX 10\nLD BYTE[X+0]",
   [ BPF_LDX|BPF_IMM, 0, 0, 10 ],
   [ BPF_LD|BPF_IND|BPF_B, 0, 0, 0 ];
