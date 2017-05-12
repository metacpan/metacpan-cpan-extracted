use strict;
use warnings;
use Test::More tests => 2;
use Escape::Houdini qw(escape_html);

my $can_dump;

subtest 'refcount' => sub {
    BEGIN { $can_dump = eval 'use Devel::Peek qw(SvREFCNT Dump); 1' }
    $can_dump
        or plan skip_all => 'test requires Devel::Peek';

    plan tests => 1;
    my $sv = escape_html('test');
    is SvREFCNT( $sv ), 1, 'Correct refcount means this should be garbage-collected properly'
        or diag Dump( $sv );
};

subtest 'leaktrace' => sub {
    eval 'use Test::LeakTrace';
    plan $@ =~ m{\QTest/LeakTrace.pm}
        ? (skip_all => "Test requires Test::LeakTrace")
        : (tests => 1);
    no_leaks_ok(sub {
        my $shouldnt_be_leaked = escape_html('<script src="http://evil.com/steal_banking_details.js"></script>');
    });
};
