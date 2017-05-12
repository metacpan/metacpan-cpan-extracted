#!/usr/bin/perl

use strict;

use Mac::FSEvents;

use Test::More;

subtest 'Path must be given' => sub {
    eval {
        my $ev = Mac::FSEvents->new({});
    };
    ok $@, 'path must be given';
    like $@, qr{\Qpath argument to new() must be supplied};
};

subtest 'path must be string' => sub {
    {
        package
            stringified;
        use overload '""' => sub { return $_[0]->{path} };
    }

    eval {
        my $ev = Mac::FSEvents->new({
            path => bless( { path => 'tmp' }, 'stringified' ),
        });
    };
    ok $@, 'path must be string';
    like $@, qr{\Qpath argument to new() must be plain string};
};

done_testing;
