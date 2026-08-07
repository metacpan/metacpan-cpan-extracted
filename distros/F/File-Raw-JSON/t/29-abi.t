#!perl
use strict;
use warnings;
use Test::More;
use File::Raw::JSON;

# The public C ABI (include/frj_abi.h): the versioned function-pointer table
# reached through File::Raw::JSON::_abi_ptr, and the EU::Depends provider config
# that lets a consumer (e.g. Hyperman) find the header without copying it.

# _abi_ptr returns the address of the process-wide table. It is an IV carrying
# a raw pointer, so it may legitimately be negative - Solaris x86-64 maps shared
# objects around 0xFFFFFC7F..., which sets the sign bit and made the old
# '$ptr > 0' assertion fail there on a table that was perfectly fine. What
# matters is that it is non-zero and stable; that the bits survive the round
# trip through INT2PTR is what _abi_selftest below actually proves.
my $ptr = File::Raw::JSON::_abi_ptr();
ok(defined $ptr && $ptr != 0, "_abi_ptr returns a table address ($ptr)");
is(File::Raw::JSON::_abi_ptr(), $ptr, 'the table is static - same address');

# _abi_selftest resolves the table in C and round-trips a document through the
# opts_init/decode/encode function pointers - proving the whole table wires up.
is(File::Raw::JSON::_abi_selftest(), 1,
   '_abi_selftest: decode+encode round-trip through the ABI table');

# Provider config: ExtUtils::Depends wrote File::Raw::JSON::Install::Files with
# an include path, so a dependent's ExtUtils::Depends->new(..., 'File::Raw::JSON')
# picks up frj_abi.h with no vendoring.
SKIP: {
    eval { require File::Raw::JSON::Install::Files; 1 }
        or skip 'Install::Files not built (run make first)', 2;
    no warnings 'once';
    my $inc = $File::Raw::JSON::Install::Files::inc;
    ok(defined $inc && length $inc, 'Install::Files records an include path');
    like($inc, qr/-I/, 'include path carries -I dirs for dependents');
}

done_testing;
