#!/usr/bin/env perl -w
use strict;
use warnings;
use Log::LTSV::Instance::Flatten;
use Test::More;
use Test::Deep;

my $flatten = Log::LTSV::Instance::Flatten->new;
my $method = sub { $flatten->flatten(@_) };

subtest 'simple' => sub {
    subtest 'scalar' => sub {
        my %ret = $flatten->flatten('p', 'a');
        cmp_deeply \%ret, { p => 'a' } or note explain \%ret;
    };

    subtest 'arrayref' => sub {
        my %ret = $method->('p', ['a', 'b']);
        cmp_deeply \%ret, {
            'p.0' => 'a',
            'p.1' => 'b'
        } or note explain \%ret;
    };

    subtest 'hashref' => sub {
        my %ret =$method->('p', {'a' => '1', 'b' => '2'});
        cmp_deeply \%ret, {
            'p.a' => '1',
            'p.b' => '2'
        } or note explain \%ret;
    };

    subtest 'objectref [scalar]' => sub {
        my $scalar = 'a';
        my $obj = bless \$scalar, 'Object';
        my %ret = $method->('p', $obj);
        cmp_deeply \%ret, {
        #'p._class_' => 'Object',
            'p'         => 'a',
        } or note explain \%ret;
    };
    subtest 'objectref [code]' => sub {
        my $code = sub { print $_ };
        my $obj = bless \$code, 'Object';
        my %ret = $method->('p', $obj);
        cmp_deeply \%ret, {
        #'p._class_' => 'Object',
            'p'         => ignore,
        } or note explain \%ret;
    };
    subtest 'objectref [arrayref]' => sub {
        my $obj = bless [ 'a', 'b' ], 'Object';
        my %ret = $method->('p', $obj);
        cmp_deeply \%ret, {
        #'p._class_' => 'Object',
            'p.0'     => 'a',
            'p.1'     => 'b',
        } or note explain \%ret;
    };
    subtest 'objectref [hashref]' => sub {
        my $obj = bless { a => 'b' }, 'Object';
        my %ret = $method->('p', $obj);
        cmp_deeply \%ret, {
        #'p._class_' => 'Object',
            'p.a'     => 'b',
        } or note explain \%ret;
    };
};

subtest 'nested' => sub {
    subtest 'arrayref [arrayref]' => sub {
        my %ret = $method->('p', [ [ 'a', 'b' ] ]);
        cmp_deeply \%ret, {
            'p.0.0' => 'a',
            'p.0.1' => 'b'
        } or note explain \%ret;
    };
    subtest 'arrayref [hashref]' => sub {
        my %ret = $method->('p', [ { 'a' => 'b' } ]);
        cmp_deeply \%ret, {
            'p.0.a' => 'b',
        } or note explain \%ret;
    };
    subtest 'arrayref [obj(arrayref)]' => sub {
        my %ret = $method->('p', [ bless [ 'a', 'b' ], 'TEST' ]);
        cmp_deeply \%ret, {
        #'p.0._class_' => 'TEST',
            'p.0.0'     => 'a',
            'p.0.1'     => 'b',
        } or note explain \%ret;
    };
    subtest 'arrayref [obj(hashref)]' => sub {
        my %ret = $method->('p', [ bless { 'a' => 'b' }, 'TEST' ]);
        cmp_deeply \%ret, {
        #'p.0._class_' => 'TEST',
            'p.0.a'     => 'b',
        } or note explain \%ret;
    };

    subtest 'hashref [arrayref]' => sub {
        my %ret = $method->('p', { 'a' => [ 1, 2 ] });
        cmp_deeply \%ret, {
            'p.a.0' => '1',
            'p.a.1' => '2',
        } or note explain \%ret;
    };
    subtest 'hashref [hashref]' => sub {
        my %ret = $method->('p', { 'a' => { b => 'c' } });
        cmp_deeply \%ret, {
            'p.a.b' => 'c',
        } or note explain \%ret;
    };
    subtest 'hashref [obj(arrayref)]' => sub {
        my %ret = $method->('p', { 'a' => bless [ 'b' , 'c' ], 'TEST' });
        cmp_deeply \%ret, {
        #'p.a._class_' => 'TEST',
            'p.a.0'     => 'b',
            'p.a.1'     => 'c',
        } or note explain \%ret;
    };
    subtest 'hashref [obj(hashref)]' => sub {
        my %ret = $method->('p', { 'a' => bless { b => 'c' }, 'TEST' });
        cmp_deeply \%ret, {
        #'p.a._class_' => 'TEST',
            'p.a.b'     => 'c',
        } or note explain \%ret;
    };

    subtest 'obj(arrayref) [arrayref]' => sub {
        my %ret = $method->('p', bless [ ['a'] ], 'TEST');
        cmp_deeply \%ret, {
        #'p._class_' => 'TEST',
            'p.0.0'   => 'a',
        } or note explain \%ret;
    };
    subtest 'obj(arrayref) [hashref]' => sub {
        my %ret = $method->('p', bless { 'a' => { 'b' => 'c' } }, 'TEST');
        cmp_deeply \%ret, {
        #'p._class_' => 'TEST',
            'p.a.b'   => 'c',
        } or note explain \%ret;
    };

    #TODO add test
};



done_testing;
