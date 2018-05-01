#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

plan tests => 9;

subtest 'Require some module' => sub {
    plan tests => 2;

    use_ok 'JIP::DataPath', '0.01';
    require_ok 'JIP::DataPath';

    diag(
        sprintf 'Testing JIP::DataPath %s, Perl %s, %s',
            $JIP::DataPath::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
    );
};

subtest 'new(). exceptions' => sub {
    plan tests => 1;

    eval { JIP::DataPath->new; } or do {
        like $EVAL_ERROR, qr{^Mandatory \s argument \s "document" \s is \s missing}x;
    };
};

subtest 'new()' => sub {
    plan tests => 4;

    my $o = JIP::DataPath->new(document => 42);
    ok $o, 'got instance if JIP::DataPath';

    isa_ok $o, 'JIP::DataPath';

    can_ok $o, qw(new get contains set perform path);

    is $o->document, 42;
};

subtest 'get()' => sub {
    plan tests => 2;

    subtest 'when document is not defined' => sub {
        plan tests => 3;

        my $o = JIP::DataPath->new(document => undef);

        is $o->get([qw()]),    undef;
        is $o->get([qw(foo)]), undef;
        is $o->get([qw(0)]),   undef;
    };

    subtest 'when document is defined' => sub {
        plan tests => 6;

        my $document = {
            foo => {
                bar => [
                    {wtf => 42},
                ],
            },
        };

        my $o = JIP::DataPath->new(document => $document);

        is_deeply $o->get([qw()]),          $document;
        is_deeply $o->get([qw(foo)]),       $document->{'foo'};
        is_deeply $o->get([qw(foo bar)]),   $document->{'foo'}->{'bar'};
        is_deeply $o->get([qw(foo bar 0)]), $document->{'foo'}->{'bar'}->[0];

        is $o->get([qw(foo bar 0 wtf)]), $document->{'foo'}->{'bar'}->[0]->{'wtf'};

        # side effects
        is_deeply $document, {
            foo => {
                bar => [
                    {wtf => 42},
                ],
            },
        };
    };
};

subtest 'contains()' => sub {
    plan tests => 2;

    subtest 'when document is not defined' => sub {
        plan tests => 3;

        my $document = undef;

        my $o = JIP::DataPath->new(document => $document);

        is $o->contains([qw()]),    1;
        is $o->contains([qw(foo)]), 0;
        is $o->contains([qw(0)]),   0;
    };

    subtest 'when document is defined' => sub {
        plan tests => 6;

        my $document = {
            foo => {
                bar => [
                    {wtf => 42},
                ],
            },
        };

        my $o = JIP::DataPath->new(document => $document);

        is $o->contains([qw()]),              1;
        is $o->contains([qw(foo)]),           1;
        is $o->contains([qw(foo bar)]),       1;
        is $o->contains([qw(foo bar 0)]),     1;
        is $o->contains([qw(foo bar 0 wtf)]), 1;

        # side effects
        is_deeply $document, {
            foo => {
                bar => [
                    {wtf => 42},
                ],
            },
        };
    };
};

subtest 'set()' => sub {
    plan tests => 2;

    subtest 'when document is not defined' => sub {
        plan tests => 6;

        my $o = JIP::DataPath->new(document => undef);

        is $o->set([]),  1;
        is $o->document, undef;

        is $o->set([], undef), 1;
        is $o->document,       undef;

        is $o->set([], 42), 1;
        is $o->document,    42;
    };

    subtest 'when document is a HASH' => sub {
        plan tests => 10;

        my $o = JIP::DataPath->new(document => undef);

        {
            my $result = $o->set([], {foo => undef});
            is $result, 1;

            is_deeply $o->document, {foo => undef};
        }
        {
            my $result = $o->set([qw(foo)], {bar => undef});
            is $result, 1;

            is_deeply $o->document, {
                foo => {
                    bar => undef,
                },
            };
        }
        {
            my $result = $o->set([qw(foo bar)], []);
            is $result, 1;

            is_deeply $o->document, {
                foo => {
                    bar => [],
                },
            };
        }
        {
            my $result = $o->set([qw(foo bar)], [{wtf => undef}]);
            is $result, 1;

            is_deeply $o->document, {
                foo => {
                    bar => [
                        {wtf => undef},
                    ],
                },
            };
        }
        {
            my $result = $o->set([qw(foo bar 0)], {wtf => 42});
            is $result, 1;

            is_deeply $o->document, {
                foo => {
                    bar => [
                        {wtf => 42},
                    ],
                },
            };
        }
    };
};

subtest 'perform()' => sub {
    plan tests => 4;

    my $o = JIP::DataPath->new(document => {
        foo => {
            bar => [
                {wtf => 42},
            ],
        },
    });

    subtest 'perform get()' => sub {
        plan tests => 1;

        my $result = $o->perform('get', [qw(foo bar 0 wtf)]);
        is $result, 42;
    };

    subtest 'perform set()' => sub {
        plan tests => 1;

        my $result = $o->perform('set', [qw(foo bar 0 wtf)], 100500);
        is $result, 1;
    };

    subtest 'perform contains()' => sub {
        plan tests => 1;

        my $result = $o->perform('contains', [qw(foo bar 0 wtf)]);
        is $result, 1;
    };

    is_deeply $o->document, {
        foo => {
            bar => [
                {wtf => 100500},
            ],
        },
    };
};

subtest 'path()' => sub {
    plan tests => 2;

    my $o = JIP::DataPath::path(42);

    isa_ok $o, 'JIP::DataPath';

    is $o->document, 42;
};

subtest '_accessor()' => sub {
    plan tests => 19;

    my $document = {
        foo => {
            wtf => 42,
        },
        bar => [
            [11, 22],
        ],
    };

    my $o = JIP::DataPath->new(document => $document);

    {
        my ($contains, $context) = $o->_accessor([]);
        is $contains,       1;
        is_deeply $context, $document;
    }
    {
        my ($contains, $context) = $o->_accessor([qw(foo)]);
        is $contains,       1;
        is_deeply $context, $document;
    }
    {
        my ($contains, $context) = $o->_accessor([qw(foo wtf)]);
        is $contains,       1;
        is_deeply $context, $document->{'foo'};
    }

    {
        my ($contains, $context) = $o->_accessor([qw(bar)]);
        is $contains,       1;
        is_deeply $context, $document;
    }
    {
        my ($contains, $context) = $o->_accessor([qw(bar 0)]);
        is $contains,       1;
        is_deeply $context, $document->{'bar'};
    }
    {
        my ($contains, $context) = $o->_accessor([qw(bar 0 0)]);
        is $contains,       1;
        is_deeply $context, $document->{'bar'}->[0];
    }
    {
        my ($contains, $context) = $o->_accessor([qw(bar 0 1)]);
        is $contains,       1;
        is_deeply $context, $document->{'bar'}->[0];
    }
    {
        my ($contains, $context) = $o->_accessor([qw(1 wtf 1 wtf)]);
        is $contains, 0;
        is $context,  undef;
    }
    {
        my ($contains, $context) = $o->_accessor([qw(wtf 1 wtf 1)]);
        is $contains, 0;
        is $context,  undef;
    }

    is_deeply $o->document, {
        foo => {
            wtf => 42,
        },
        bar => [
            [11, 22],
        ],
    };
};

