#!/usr/bin/perl

use ExtUtils::testlib;
use Keystone ':all';

use strict;
use warnings;

my @asm = ("push ebp",
           "mov rdx, rdi",
           "int 0x80",
           "inc rdx",
           "mov eax, 0x12345678",
           "mov bx, 5");

# Print Keystone version
printf "Keystone version %d.%d\n\n", Keystone::version();

# Open a Keystone object
my $ks = Keystone->new(KS_ARCH_X86, KS_MODE_64) ||
    die "[-] Can't open Keystone\n";


for my $ins(@asm) {

    # Assemble...
    my @opcodes = $ks->asm($ins);

    if(!scalar(@opcodes)) {
        printf "Assembly failed (\"$ins\") : %s\n", $ks->strerror();
    } else {
        # Print opcodes
        printf "%-20s %s\n", join(' ', map {sprintf "%.2x", $_} @opcodes), $ins;
    }
}
