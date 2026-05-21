#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;

# Plugin registration lifecycle, listing, errors.

subtest 'plugin XSUBs exist' => sub {
    ok(defined(&File::Raw::register_plugin),   'register_plugin exists');
    ok(defined(&File::Raw::unregister_plugin), 'unregister_plugin exists');
    ok(defined(&File::Raw::list_plugins),      'list_plugins exists');
};

subtest 'predicate plugin registered at boot' => sub {
    my $names = File::Raw::list_plugins();
    is(ref $names, 'ARRAY', 'list_plugins returns arrayref');
    ok(grep({ $_ eq 'predicate' } @$names), "'predicate' plugin present");
};

subtest 'register / list / unregister round trip' => sub {
    File::Raw::register_plugin('rt_test', { read => sub { $_[1] } });
    my $names = File::Raw::list_plugins();
    ok(grep({ $_ eq 'rt_test' } @$names), 'plugin appears in list after register');
    File::Raw::unregister_plugin('rt_test');
    $names = File::Raw::list_plugins();
    ok(!grep({ $_ eq 'rt_test' } @$names), 'plugin gone from list after unregister');
};

subtest 'duplicate registration croaks' => sub {
    File::Raw::register_plugin('dup', { read => sub { $_[1] } });
    eval { File::Raw::register_plugin('dup', { read => sub { $_[1] } }) };
    like($@, qr/already registered/, 'second register croaks');
    File::Raw::unregister_plugin('dup');
};

subtest 'override flag re-registers' => sub {
    File::Raw::register_plugin('ovr', { read => sub { 'first' } });
    my $rc = eval {
        File::Raw::register_plugin('ovr', { read => sub { 'second' } }, 1);
        1;
    };
    ok($rc, 'override succeeds without croak');
    File::Raw::unregister_plugin('ovr');
};

subtest 'register validation' => sub {
    eval { File::Raw::register_plugin('') };
    like($@, qr/Usage|non-empty/, 'empty name rejected');

    eval { File::Raw::register_plugin('bad_spec', 'notahashref') };
    like($@, qr/hashref/, 'non-hashref spec rejected');

    eval { File::Raw::register_plugin('no_phases', {}) };
    like($@, qr/at least one of/, 'empty hash rejected');

    eval { File::Raw::register_plugin('not_cv', { read => 'string' }) };
    like($@, qr/at least one of/, 'non-coderef phase ignored, then no phases left');

    eval { File::Raw::register_plugin('strm', { stream => sub { 1 } }) };
    like($@, qr/stream.*not supported from Perl/, 'stream phase from Perl rejected');
};

subtest 'unregister missing is a no-op' => sub {
    my $rc = eval {
        File::Raw::unregister_plugin('nonexistent_plugin_name');
        1;
    };
    ok($rc, 'unregister of unknown name does not croak');
};

done_testing;
