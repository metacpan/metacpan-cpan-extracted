#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use File::Raw;
use File::Temp qw(tempdir);

# Per-plugin sub-hash routing. The dispatcher must:
#   - extract `plugin_name => { ... }` keys from the top-level options
#     hash and route them only to the matching plugin in the chain
#   - leave other top-level keys in a "shared" bag that every plugin
#     in the chain sees
#   - layer per-plugin keys on top of shared ones (per-plugin wins on
#     conflict)
#   - never let a plugin see a foreign plugin's sub-hash (prevents
#     spurious "unknown option" croaks from strict plugins)

my $dir = tempdir(CLEANUP => 1);

# Capture every options HV each plugin sees, by name.
my %seen;
my $reset = sub { %seen = (); };

File::Raw::register_plugin('alpha', {
    read => sub {
        my ($p, $bytes, $opts) = @_;
        $seen{alpha} = { %$opts };  # shallow copy
        return $bytes . '|alpha';
    },
});

File::Raw::register_plugin('beta', {
    read => sub {
        my ($p, $bytes, $opts) = @_;
        $seen{beta} = { %$opts };
        return $bytes . '|beta';
    },
});

my $f = "$dir/o.txt";
File::Raw::spew($f, 'X');

subtest 'per-plugin sub-hash reaches only its plugin' => sub {
    $reset->();
    File::Raw::slurp($f,
        plugin => ['alpha', 'beta'],
        alpha  => { mode => 'A', strict => 1 },
        beta   => { mode => 'B' },
    );

    is($seen{alpha}{mode}, 'A', 'alpha sees its own mode=A');
    is($seen{beta}{mode},  'B', 'beta sees its own mode=B');
    is($seen{alpha}{strict}, 1, 'alpha sees its own strict=1');
    ok(!exists $seen{beta}{strict}, 'beta does NOT see alpha strict');
    ok(!exists $seen{alpha}{beta},  'alpha does NOT see the beta sub-hash');
    ok(!exists $seen{beta}{alpha},  'beta does NOT see the alpha sub-hash');
};

subtest 'shared top-level keys reach every plugin' => sub {
    $reset->();
    File::Raw::slurp($f,
        plugin => ['alpha', 'beta'],
        shared_flag => 'on',
    );

    is($seen{alpha}{shared_flag}, 'on', 'alpha sees the shared key');
    is($seen{beta}{shared_flag},  'on', 'beta sees the shared key');
};

subtest 'per-plugin wins over shared on key conflict' => sub {
    $reset->();
    File::Raw::slurp($f,
        plugin => ['alpha', 'beta'],
        mode   => 'shared-default',
        alpha  => { mode => 'alpha-override' },
    );

    is($seen{alpha}{mode}, 'alpha-override',
        'alpha overrides shared with its sub-hash');
    is($seen{beta}{mode},  'shared-default',
        'beta still sees the shared default');
};

subtest 'plugin key in iter opts is the plugin name (not the arrayref)' => sub {
    $reset->();
    File::Raw::slurp($f, plugin => ['alpha', 'beta']);

    is($seen{alpha}{plugin}, 'alpha', 'alpha sees plugin=alpha');
    is($seen{beta}{plugin},  'beta',  'beta sees plugin=beta');
};

subtest 'scalar single-plugin path is untouched (opts go straight through)' => sub {
    $reset->();
    File::Raw::slurp($f, plugin => 'alpha', mode => 'flat');
    is($seen{alpha}{mode}, 'flat',
        'scalar-plugin call still uses the original opts HV verbatim');
    is($seen{alpha}{plugin}, 'alpha',
        'scalar path leaves plugin key untouched');
};

done_testing;
