# Copyright (c) 2012-2019 Martin Becker, Blaubeuren.
# This package is free software; you can distribute it and/or modify it
# under the terms of the Artistic License 2.0 (see LICENSE file).

# Gather platform information to help analyzing test reports.

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl t/07_platform.t'

#########################

use strict;
use warnings;
use Test;
use Config;

plan(tests => 1);

#########################

print "# perl version is ", $], "\n";
print "# OS name is ", $^O, "\n";

foreach my $module (qw(
    Math::ModInt
    Math::ModInt::BigInt
    Math::ModInt::ChineseRemainder
    Math::ModInt::Event
    Math::ModInt::Event::Trap
    Math::ModInt::GF2
    Math::ModInt::GF3
    Math::ModInt::Perl
    Math::ModInt::Trivial
    overload
    Carp
    Math::BigInt
    Math::BigInt::FastCalc
    Math::BigInt::GMP
    Math::BigInt::Pari
)) {
    if (eval "require $module") {
        my $version = eval { $module->VERSION };
        if (defined $version) {
            print "# module $module has version $version\n";
            if ('Math::Pari' eq $module) {
                my $pve =
                    eval { Math::Pari::pari_version_exp() } || '(unknown)';
                print "# pari library has version $pve\n";
            }
        }
        else {
            print "# module $module has no version number\n";
        }
    }
    else {
        print "# module $module not available\n";
    }
}

my ($ivsize, $nvsize) = @Config{'ivsize', 'nvsize'};
print "# ivsize is $ivsize, nvsize is $nvsize\n";

my $max_modulus = Math::ModInt::_MAX_MODULUS_PERL();
print "# _MAX_MODULUS_PERL is $max_modulus\n";

ok(1);

__END__
