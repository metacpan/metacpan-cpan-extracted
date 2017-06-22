use strict;
use warnings;
use utf8;

use List::Haystack;

use Module::Spy qw/spy_on/;
use Test::More;

subtest 'Not lazy' => sub {
    subtest 'With list that has any contents' => sub {
        my $spy = spy_on('List::Haystack', '_construct_haystack')->and_call_through;
        my $haystack = List::Haystack->new([qw/foo bar foo/]);

        ok defined $haystack->{haystack};

        is $haystack->cnt('foo'), 2;
        is $haystack->cnt('bar'), 1;
        is $haystack->cnt('buz'), 0;

        is $spy->calls_count, 1;
    };

    subtest 'With empty list' => sub {
        my $spy = spy_on('List::Haystack', '_construct_haystack')->and_call_through;
        my $haystack = List::Haystack->new([]);

        ok defined $haystack->{haystack};

        is $haystack->cnt('foo'), 0;

        is $spy->calls_count, 1;
    };
};

subtest 'Lazy' => sub {
    subtest 'With list that has any contents' => sub {
        my $spy = spy_on('List::Haystack', '_construct_haystack')->and_call_through;
        my $haystack = List::Haystack->new([qw/foo bar foo/], {lazy => 1});

        ok not defined $haystack->{haystack};

        is $haystack->cnt('foo'), 2;

        ok defined $haystack->{haystack};

        is $haystack->cnt('bar'), 1;
        is $haystack->cnt('buz'), 0;

        is $spy->calls_count, 1;
    };

    subtest 'With empty list' => sub {
        my $spy = spy_on('List::Haystack', '_construct_haystack')->and_call_through;
        my $haystack = List::Haystack->new([], {lazy => 1});

        ok not defined $haystack->{haystack};

        is $haystack->cnt('foo'), 0;

        ok defined $haystack->{haystack};

        is $spy->calls_count, 1;
    };
};

done_testing;

