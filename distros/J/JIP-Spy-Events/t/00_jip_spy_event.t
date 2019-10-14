#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

plan tests => 4;

use_ok 'JIP::Spy::Event', 'v0.0.1';

subtest 'Require some module' => sub {
    plan tests => 1;

    require_ok 'JIP::Spy::Event';

    diag(
        sprintf(
            'Testing JIP::Spy::Event %s, Perl %s, %s',
            $JIP::Spy::Event::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new()' => sub {
    plan tests => 7;

    my $o = JIP::Spy::Event->new;
    ok $o, 'got instance of JIP::Spy::Event';

    isa_ok $o, 'JIP::Spy::Event';

    can_ok $o, qw(new method arguments want_array times);

    is $o->method,     undef;
    is $o->arguments,  undef;
    is $o->want_array, undef;
    is $o->times,      undef;
};

subtest 'new() with arguments' => sub {
    plan tests => 4;

    my $o = JIP::Spy::Event->new(
        method     => 'tratata',
        arguments  => [],
        want_array => 1,
        times      => 1,
    );

    is $o->method,     'tratata';
    is $o->want_array, 1;
    is $o->times,      1;

    is_deeply $o->arguments,  [];
};
