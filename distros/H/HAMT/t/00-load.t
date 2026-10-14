#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# The modules load, share one version, and the provider config that
# ExtUtils::Depends writes for consumers is in the built tree.

use_ok('HAMT') or BAIL_OUT('HAMT does not load');

ok(defined $HAMT::VERSION, 'HAMT has a version');
like($HAMT::VERSION, qr/^\d+\.\d+$/, 'and it is a plain number');

for my $class (qw(HAMT::Map HAMT::Set HAMT::Vector
                  HAMT::Map::Transient HAMT::Set::Transient
                  HAMT::Vector::Transient)) {
    use_ok($class) or next;
    no strict 'refs';
    is(${"${class}::VERSION"}, $HAMT::VERSION, "$class carries the dist's version");
}

# The XS bundle is loaded, which a pure-Perl stub would pass without.
can_ok('HAMT', '_abi_ptr');

my $p = HAMT::_abi_ptr();
ok($p, '_abi_ptr returns a non-zero address');
is($p, HAMT::_abi_ptr(), 'and the same one every call');
like($p, qr/^\d+$/, 'and an unsigned integer');
is(HAMT::_abi_version(), 1, 'the table is version 1');
is((HAMT::_abi_selftest())[0], 0, 'and its selftest passes')
    or diag('the number is the check that failed in include/hamt/hamt_abi_selftest.h');

ok(eval { require HAMT::Install::Files; 1 },
   'HAMT::Install::Files exists (the provider config)')
    or diag $@;
{
    no warnings 'once';

    # Assert what a CONSUMER needs. A provider must record inc => '', because
    # its own build-tree paths are meaningless once installed: '-I.' handed to
    # a consumer means the CONSUMER's directory. What a consumer needs is
    # $CORE, which is where install() put the header.
    is($HAMT::Install::Files::inc, '',
       'it records no include path of its own, so nothing leaks to a consumer');

    my $core = $HAMT::Install::Files::CORE;
    ok(defined $core && length $core, 'it records a CORE directory');
    ok(defined $core && -f "$core/hamt_abi.h",
       'and hamt_abi.h is in it, so a consumer resolving HAMT finds the header')
        or diag "CORE: " . (defined $core ? $core : 'undef');
}

diag("Testing HAMT $HAMT::VERSION, Perl $], $^X");

done_testing;
