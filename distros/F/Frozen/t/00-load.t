#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The module loads, has one version, and the provider config that
# ExtUtils::Depends writes for consumers is in the built tree.

use_ok('Frozen') or BAIL_OUT('Frozen does not load');

ok(defined $Frozen::VERSION, 'Frozen has a version');
like($Frozen::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

# The XS bundle is loaded, which a pure-Perl stub would pass without.
can_ok('Frozen', '_abi_ptr');

ok(eval { require Frozen::Install::Files; 1 },
   'Frozen::Install::Files exists (the provider config)')
    or diag $@;
{
    no warnings 'once';

    # Assert what a CONSUMER needs, not what set_inc happened to record.
    #
    # The obvious test - that $inc matches -I\S*include - asserts a bug. A
    # provider must record inc => '', because its own build-tree paths are
    # meaningless once installed: '-I.' handed to a consumer means the
    # CONSUMER's directory. What a consumer actually needs is $CORE, which
    # ExtUtils::Depends derives by itself and which is where install() put the
    # header.
    is($Frozen::Install::Files::inc, '',
       'it records no include path of its own, so nothing leaks to a consumer');

    my $core = $Frozen::Install::Files::CORE;
    ok(defined $core && length $core, 'it records a CORE directory');
    ok(defined $core && -f "$core/fz_abi.h",
       'and fz_abi.h is in it, so a consumer resolving Frozen finds the header')
        or diag "CORE: " . (defined $core ? $core : 'undef');
}

diag("Testing Frozen $Frozen::VERSION, Perl $], $^X");

done_testing;
