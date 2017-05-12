#!/usr/bin/env perl

use strict;
use Test::More tests => 40;

{
    package Dummy;

    use Method::Cached;
    use Method::Cached::KeyRule::Serialize;

    # Every time, this method invents another value
    sub echo { join ':', @_, time, rand }

    sub method0   :Cached                             { echo @_ }
    sub method1   :Cached(0)                          { echo @_ }
    sub method1_1 :Cached(1)                          { echo @_ }
    sub method2   :Cached(0, LIST)                    { echo @_ }
    sub method2_1 :Cached(1, LIST)                    { echo @_ }
    sub method3   :Cached(0, SERIALIZE)               { echo @_ }
    sub method3_1 :Cached(1, SERIALIZE)               { echo @_ }
    sub method4   :Cached('any-domain', 0)            { echo @_ }
    sub method4_1 :Cached('any-domain', 1)            { echo @_ }
    sub method5   :Cached('any-domain', 0, LIST)      { echo @_ }
    sub method5_1 :Cached('any-domain', 1, LIST)      { echo @_ }
    sub method6   :Cached('any-domain', 0, SERIALIZE) { echo @_ }
    sub method6_1 :Cached('any-domain', 1, SERIALIZE) { echo @_ }
    sub method7   :Cached(undef, 0)                   { echo @_ }
    sub method7_1 :Cached(undef, 1)                   { echo @_ }
    sub method8   :Cached(undef, 0, LIST)             { echo @_ }
    sub method8_1 :Cached(undef, 1, LIST)             { echo @_ }
    sub method9   :Cached(undef, 0, SERIALIZE)        { echo @_ }
    sub method9_1 :Cached(undef, 1, SERIALIZE)        { echo @_ }
}

# use Dummy;
Dummy->import;

# Test for test
isnt(
    Dummy::echo(qw/1 .. 3/),
    Dummy::echo(qw/1 .. 3/),
);

# Does Cache function correctly?
{
    no strict 'refs';

    # The easiest test:
    is(Dummy::method0, Dummy::method0);

    for my $n (1 .. 9) {

        my $method  = "Dummy::method$n";
        my $call1   = &{$method};
        my $call1_1 = &{"$method\_1"};
        sleep 2;
        my $call2   = &{$method};
        my $call2_1 = &{"$method\_1"};

        # Cache remains:
        is $call1, $call2, "is $method";

        # Cache is expired:
        isnt $call1_1, $call2_1, "isnt $method\_1";

    }
}

# Test that uses parameters
{
    no strict 'refs';

    use Storable qw/dclone/;

    my @origin1 = (1, 'hello', { xxx => 0.1, yyy => 0xFF, zzz => undef });
    my @dclone1 = @{ dclone(\@origin1) };

    # The rule of the key is 'LIST' :
    # When the reference is the same address, the same value is returned.
    is(
        Dummy::method0(@origin1),
        Dummy::method0(@origin1),
    );

    # When the address of reference is different, it is interpreted as another value.
    isnt(
        Dummy::method0(@origin1),
        Dummy::method0(@dclone1),
    );

    my @is_serialize = (3, 6, 9);

    for my $n (1 .. 9) {

        my $method  = "Dummy::method$n";

        my $call1   = &{$method}(@origin1[0 .. 1]);
        my $call1_1 = &{$method}(@origin1);
        my $call2   = &{$method}(@dclone1[0 .. 1]);
        my $call2_1 = &{$method}(@dclone1);

        is $call1, $call2;

        # The rule of the key is 'SERIALIZE' :
        # Not the address but the value is traced and the key is produced.
        if (grep { $_ == $n } @is_serialize) {
            is $call1_1, $call2_1;
        }
        else {
            isnt $call1_1, $call2_1;
        }

    }
}
