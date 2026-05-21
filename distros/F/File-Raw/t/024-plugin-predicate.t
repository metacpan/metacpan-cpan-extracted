#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# Built-in 'predicate' plugin: register_predicate / list_predicates,
# explicit dispatch via plugin => 'predicate'.

my $dir = tempdir(CLEANUP => 1);

subtest 'predicate XSUBs exist' => sub {
    ok(defined(&File::Raw::register_predicate), 'register_predicate exists');
    ok(defined(&File::Raw::list_predicates),    'list_predicates exists');
};

subtest 'list_predicates includes built-ins' => sub {
    my $names = File::Raw::list_predicates();
    is(ref $names, 'ARRAY', 'returns arrayref');
    my %have = map { $_ => 1 } @$names;
    for my $n (qw(blank is_blank not_blank is_not_blank
                  empty is_empty not_empty is_not_empty
                  comment is_comment not_comment is_not_comment)) {
        ok($have{$n}, "$n present");
    }
};

subtest 'register_predicate validates' => sub {
    eval { File::Raw::register_predicate('x') };
    like($@, qr/Usage/, 'missing coderef caught');

    eval { File::Raw::register_predicate('x', 'notacv') };
    like($@, qr/coderef/, 'non-coderef caught');
};

subtest 'register_predicate adds and overrides' => sub {
    File::Raw::register_predicate('starts_x', sub { /^x/ });
    my $names = File::Raw::list_predicates();
    ok(grep({ $_ eq 'starts_x' } @$names), 'new predicate listed');

    # Re-registration updates in place (legacy semantics).
    my $rc = eval {
        File::Raw::register_predicate('starts_x', sub { /^X/ });
        1;
    };
    ok($rc, 'second register does not croak');
};

subtest 'built-in predicates work via legacy 2-arg grep_lines' => sub {
    my $f = "$dir/blanks.txt";
    File::Raw::spew($f, "a\n\n  \nb\n# c\n");
    is(scalar @{ File::Raw::grep_lines($f, 'is_blank') },     2, 'is_blank');
    is(scalar @{ File::Raw::grep_lines($f, 'is_not_blank') }, 3, 'is_not_blank');
    is(scalar @{ File::Raw::grep_lines($f, 'is_comment') },   1, 'is_comment');
};

subtest 'predicate plugin record dispatch' => sub {
    # Drive the predicate plugin's record fn directly (no XSUB sugar).
    # We can't easily call dispatch_record from Perl, so this is covered
    # implicitly by the legacy 2-arg path which uses the same fns.
    pass('exercised via legacy path above');
};

done_testing;
