#!perl
use 5.010;
use strict;
use warnings;
use Test::More;

# Exercises the XS-level `import` (JSON.xs) - mirrors File::Raw's
# selective-import recipe.  Each subtest uses a fresh package so
# previously-installed CVs from earlier subtests don't bleed in.

my $pkg_counter = 0;
sub fresh_pkg { return sprintf 'T17::P%04d', $pkg_counter++; }

subtest 'no list -> no-op import (functions absent in caller)' => sub {
    my $p = fresh_pkg();
    eval qq{ package $p; use File::Raw::JSON; 1 } or fail("eval: $@");
    ok(!$p->can('file_json_decode'),
       'plain `use File::Raw::JSON` does not install file_json_decode');
    ok(!$p->can('file_json_encode'),
       'plain `use File::Raw::JSON` does not install file_json_encode');
};

subtest ':codec installs both' => sub {
    my $p = fresh_pkg();
    eval qq{ package $p; use File::Raw::JSON qw(:codec); 1 } or fail($@);
    can_ok($p, 'file_json_decode');
    can_ok($p, 'file_json_encode');
};

subtest ':all is an alias for :codec' => sub {
    my $p = fresh_pkg();
    eval qq{ package $p; use File::Raw::JSON qw(:all); 1 } or fail($@);
    can_ok($p, 'file_json_decode');
    can_ok($p, 'file_json_encode');
};

subtest 'individual function installs only that name' => sub {
    my $p1 = fresh_pkg();
    eval qq{ package $p1; use File::Raw::JSON qw(file_json_decode); 1 } or fail($@);
    can_ok($p1, 'file_json_decode');
    ok(!$p1->can('file_json_encode'),
       'encode not installed when only decode requested');

    my $p2 = fresh_pkg();
    eval qq{ package $p2; use File::Raw::JSON qw(file_json_encode); 1 } or fail($@);
    can_ok($p2, 'file_json_encode');
    ok(!$p2->can('file_json_decode'),
       'decode not installed when only encode requested');
};

subtest 'unknown name warns but does not die' => sub {
    my $p = fresh_pkg();
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ok = eval qq{ package $p; use File::Raw::JSON qw(NOPE); 1 };
    ok($ok, 'use did not die on unknown name');
    ok(scalar(grep { /not exported/i } @warns),
       'warned with `not exported` message')
        or diag explain \@warns;
    ok(!$p->can('NOPE'), 'unknown name did not install anything');
};

subtest 'mixed list: known + unknown' => sub {
    my $p = fresh_pkg();
    my @warns;
    local $SIG{__WARN__} = sub { push @warns, $_[0] };
    my $ok = eval qq{
        package $p;
        use File::Raw::JSON qw(file_json_decode NOPE file_json_encode);
        1
    };
    ok($ok, 'use survived mixed list');
    can_ok($p, 'file_json_decode');
    can_ok($p, 'file_json_encode');
    ok(scalar(grep { /not exported/i } @warns),
       'warned about NOPE in middle of list');
};

subtest 'imported functions actually work' => sub {
    my $p = fresh_pkg();
    eval qq{ package $p; use File::Raw::JSON qw(:codec); 1 } or fail($@);

    my $decode = $p->can('file_json_decode');
    my $encode = $p->can('file_json_encode');

    my $val = $decode->(q|{"a":1,"b":[2,3]}|);
    is($val->{a},      1,         'imported decode returns parsed value');
    is_deeply($val->{b}, [2, 3],  'imported decode handles nested array');

    my $bytes = $encode->({x => 9}, sort_keys => 1);
    is($bytes, q|{"x":9}|, 'imported encode emits expected JSON');
};

subtest 'aliased CV shares XSUB with the source' => sub {
    # Both the source and the aliased CV should ultimately invoke the
    # same XSUB body.  Verify by checking they produce identical
    # output for a non-trivial input.
    my $p = fresh_pkg();
    eval qq{ package $p; use File::Raw::JSON qw(file_json_encode); 1 } or fail($@);
    my $alias = $p->can('file_json_encode');
    my $source = \&File::Raw::JSON::file_json_encode;
    my $val = { greeting => "hi", n => [1, 2, 3] };
    is($alias->($val,  sort_keys => 1),
       $source->($val, sort_keys => 1),
       'alias and source produce byte-identical output');
};

done_testing;
