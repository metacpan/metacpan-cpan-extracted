use strict;
use warnings;
use Test::More;

use HTTP::SecureHeaders;

my $secure_headers = HTTP::SecureHeaders->new;

subtest 'unblessed object' => sub {
    local $@;
    eval {
        $secure_headers->apply({});
    };
    like $@, qr/headers must be/;
};

subtest 'object not having exists, get and set methods' => sub {
    {
        package SomeHeaders;
        sub new { bless {}, $_[0] }
    }

    my $headers = SomeHeaders->new;

    local $@;
    eval {
        $secure_headers->apply($headers);
    };
    like $@, qr/unknown headers/;
};

subtest 'object not having get and set methods' => sub {
    {
        package SomeHeaders2;
        sub new { bless {}, $_[0] }
        sub exists { }
    }
    my $headers = SomeHeaders2->new;

    local $@;
    eval {
        $secure_headers->apply($headers);
    };
    like $@, qr/unknown headers/;
};

subtest 'object not having set methods' => sub {
    {
        package SomeHeaders3;
        sub new { bless {}, $_[0] }
        sub exists { }
        sub get { }
    }
    my $headers = SomeHeaders3->new;

    local $@;
    eval {
        $secure_headers->apply($headers);
    };
    like $@, qr/unknown headers/;
};

done_testing;
