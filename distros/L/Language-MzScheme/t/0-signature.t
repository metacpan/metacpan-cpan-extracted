#!/usr/bin/perl -w
use strict;
if (!eval { require Module::Signature; 1 }) {
    print "1..0 # Skip ",
	  "Next time around, consider installing Module::Signature, ",
	  "so you can verify the integrity of this distribution.\n";
} elsif ( !-e 'SIGNATURE' ) {
    print "1..0 # Skip SIGNATURE not found\n";
} elsif ( !-s 'SIGNATURE' ) {
    print "1..0 # Skip SIGNATURE file empty\n";
} elsif (!eval { require Socket; Socket::inet_aton('pgp.mit.edu') }) {
    print "1..0 # Skip ",
          "Cannot connect to the keyserver to check module signature\n";
} else {
    print "1..1\n";
    my $ret = Module::Signature::verify();
    if ($ret eq Module::Signature::CANNOT_VERIFY()) {
        print "ok 1 # skip Module::Signature cannot verify\n";
    } else {
        ($ret == Module::Signature::SIGNATURE_OK()) or print "not ";
        print "ok 1 # Valid signature\n";
    }
}
