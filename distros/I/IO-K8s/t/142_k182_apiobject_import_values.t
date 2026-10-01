#!/usr/bin/env perl
# k182: two more ways a `use IO::K8s::APIObject` line went wrong without a
# word, after k174 closed the unknown-parameter one:
#   * an odd number of import arguments (`use IO::K8s::APIObject
#     'api_version';`, a value lost to an edit) gave only Perl's "Odd number
#     of elements in hash assignment" warning, naming lib/IO/K8s/APIObject.pm,
#     and built the class as if the parameter had not been written;
#   * an empty or undef api_version or resource_plural was skipped by a
#     plain truth test, so the class silently fell back to the api_version
#     derived from its package name, or to no resource_plural at all.
#
# Approved contract, in the style of k174:
#   * an odd number of import arguments croaks, naming the class and
#     IO::K8s::APIObject, at the caller's `use` line -- and warns nothing;
#   * api_version and resource_plural must be non-empty strings: undef, the
#     empty string and a reference croak naming the class, the parameter
#     and what it got, at the caller's `use` line;
#   * both are checked before anything is set up: the package does not
#     become a class;
#   * well-formed parameters still work.
#
# Pure local fixtures -- no network, no cluster.
use strict;
use warnings;
use Test::More;

use IO::K8s::APIObject ();

my $n = 0;
# Compile a class with the given import parameter source, the `use` on line
# 42 of k182.pm; returns the class, the error (undef when it compiled) and
# the warnings raised while compiling.
sub declare {
    my ($params) = @_;
    my $class = 'TestK182::Class' . ++$n;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    # -w on: IO::K8s::APIObject has no lexical warnings of its own, so its
    # "Odd number of elements" warning showed under perl -w (k182).
    local $^W = 1;
    my $ok = eval qq{#line 41 "k182.pm"\npackage $class;\nuse IO::K8s::APIObject $params;\n1};
    return ($class, $ok ? undef : $@, \@warnings);
}

sub nothing_set_up {
    my ($label, $class) = @_;
    ok(!$class->can('new'), $label.': the package did not become a class');
    ok(!$class->can('k8s'), $label.': and got no k8s function');
}

subtest 'an odd number of import arguments croaks, and warns nothing' => sub {
    my ($class, $err, $warnings) = declare(q{'api_version'});
    like($err, qr/\A\Q$class\E: odd number of import arguments for IO::K8s::APIObject \(1\); expected name => value pairs at k182\.pm line 42\.$/m,
        'a lone name: class, module and count, at the use line');
    is_deeply($warnings, [], 'no "Odd number of elements" warning');
    nothing_set_up('a lone name', $class);

    ($class, $err, $warnings) = declare(q{api_version => 'k182.example.com/v1', 'resource_plural'});
    like($err, qr/\A\Q$class\E: odd number of import arguments for IO::K8s::APIObject \(3\); /,
        'a trailing name after a pair');
    is_deeply($warnings, [], 'no warning');
};

subtest 'api_version and resource_plural must be non-empty strings' => sub {
    my @cases = (
        [ q{api_version => ''},                                      'api_version',     'an empty string' ],
        [ q{api_version => undef},                                   'api_version',     'undef' ],
        [ q{api_version => ['k182.example.com/v1']},                 'api_version',     'a reference of type ARRAY' ],
        [ q{api_version => 'k182.example.com/v1', resource_plural => ''},    'resource_plural', 'an empty string' ],
        [ q{api_version => 'k182.example.com/v1', resource_plural => undef}, 'resource_plural', 'undef' ],
        [ q{api_version => 'k182.example.com/v1', resource_plural => {}},    'resource_plural', 'a reference of type HASH' ],
    );
    for my $case (@cases) {
        my ($params, $param, $got) = @$case;
        my ($class, $err, $warnings) = declare($params);
        like($err, qr/\A\Q$class\E: import parameter '$param' for IO::K8s::APIObject must be a non-empty string, got \Q$got\E at k182\.pm line 42\.$/m,
            "$param => $got: class, parameter and value, at the use line");
        is_deeply($warnings, [], "$param => $got: no warning");
        nothing_set_up("$param => $got", $class);
    }
};

subtest 'well-formed parameters still work' => sub {
    my ($class, $err) = declare(q{api_version => 'k182.example.com/v1', resource_plural => 'things'});
    is($err, undef, 'compiles');
    is($class->api_version, 'k182.example.com/v1', 'api_version installed');
    is($class->resource_plural, 'things', 'resource_plural installed');

    my ($only, $only_err) = declare(q{api_version => 'k182.example.com/v1'});
    is($only_err, undef, 'api_version alone compiles');
    is($only->api_version, 'k182.example.com/v1', 'and is installed');
};

done_testing;
