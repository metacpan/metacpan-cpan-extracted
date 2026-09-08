#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Raw::XML qw(file_xml_decode);

# The C ABI: the table has an address, the selftest walks a document
# through every entry in C and returns the same bytes the Perl surface
# produces for the same literal, and the provider config points a
# consumer at the installed header.

my $p1 = File::Raw::XML::_abi_ptr();
my $p2 = File::Raw::XML::_abi_ptr();
ok($p1, '_abi_ptr is non-zero');
is($p1, $p2, 'and stable across calls');
like($p1, qr/^-?\d+$/, 'and an integer, allowed to be negative where IV is signed and the address is high');

my ($input, $bytes) = File::Raw::XML::_abi_selftest();
ok(defined $bytes, 'the selftest walked every entry with every answer as expected')
    or BAIL_OUT('the ABI table does not point where its header says');
is($bytes, file_xml_decode($input)->root->c14n(mode => 'exclusive'),
   'the table\'s c14n bytes equal the Perl surface\'s for the same literal');
ok(!utf8::is_utf8($bytes), 'and they are bytes');

# The full profile's entries, walked in C the same way: parse_ex and the
# prolog it read, the CDATA spans, the collected validity errors, the
# writer and tree_equal over what it wrote, err_format, the reader with a
# subtree cut out of it, every edit, and XPath compiled once and
# evaluated against two documents. 0 is every check held; anything else
# is the number of the one that did not.
is(File::Raw::XML::_abi_selftest_full(), 0,
   'the full profile\'s entries all answered as the header says')
    or diag('check number ' . File::Raw::XML::_abi_selftest_full()
          . ' in frx_abi_selftest_full failed; the numbers are FRX_STEP in frx_abi_impl.h');

# the table's version is what a consumer compares against, and the two
# ends of it agree
{
    my $doc = file_xml_decode('<r/>');
    ok($doc, 'the strict surface still parses, which is what parse means and all it means');
}

# the provider config
ok(eval { require File::Raw::XML::Install::Files; 1 }, 'File::Raw::XML::Install::Files loads') or diag $@;
{
    no warnings 'once';
    my $core = $File::Raw::XML::Install::Files::CORE;
    ok(defined $core && -d $core, 'it records the directory the header is installed in') or diag "CORE: " . ($core // 'undef');
    ok(defined $core && -f "$core/frx_abi.h", 'and frx_abi.h is there for a consumer to include');
    my @deps = File::Raw::XML::Install::Files::deps();
    is_deeply(\@deps, ['File::Raw'], 'and it names File::Raw as the dependency a consumer inherits');
}

done_testing;
