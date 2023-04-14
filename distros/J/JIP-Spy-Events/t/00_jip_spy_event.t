#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

plan tests => 4;

BEGIN {
    use_ok 'JIP::Spy::Event', 'v0.0.2';
}

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

    my $sut = JIP::Spy::Event->new();
    ok $sut, 'got instance of JIP::Spy::Event';

    isa_ok $sut, 'JIP::Spy::Event';

    can_ok $sut, qw(new method arguments want_array times);

    is $sut->method(),     undef;
    is $sut->arguments(),  undef;
    is $sut->want_array(), undef;
    is $sut->times(),      undef;
};

subtest 'new() with arguments' => sub {
    plan tests => 4;

    my $sut = JIP::Spy::Event->new(
        method     => 'tratata',
        arguments  => [],
        want_array => 1,
        times      => 1,
    );

    is $sut->method(),     'tratata';
    is $sut->want_array(), 1;
    is $sut->times(),      1;

    is_deeply $sut->arguments(), [];
};
