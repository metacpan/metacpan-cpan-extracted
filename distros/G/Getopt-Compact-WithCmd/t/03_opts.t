use strict;
use warnings;
use Test::More;
use Test::Output qw/stdout_from/;

BEGIN {
    *CORE::GLOBAL::exit = sub { 'noop' };
}

use Getopt::Compact::WithCmd;

sub test_opts {
    my %specs = @_;
    my ($args, $expects, $desc, $argv, $is_alive, $extra_test)
        = @specs{qw/args expects desc argv is_alive extra_test/};

    subtest $desc => sub {
        @::ARGV = @$argv if $argv;
        my $go = new_ok 'Getopt::Compact::WithCmd', [%$args];

        if ($is_alive) {
            is_deeply +$go->opts, $expects, 'opts';
        }
        else {
            ok stdout_from(sub{ $go->opts }), 'show usage';
        }

        if ($extra_test) {
            $extra_test->($go);
        }

        done_testing;
    };
}

test_opts(
    args => {},
    expects => {
        help => undef,
    },
    is_alive => 1,
    desc => 'empty params',
);

test_opts(
    args => {
        global_struct => [],
    },
    expects => {
        help => undef,
    },
    is_alive => 1,
    desc => 'with empty global_struct',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        foo  => undef,
        help => undef,
    },
    is_alive => 1,
    desc => 'with global_struct (foo)',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        foo  => 1,
        help => undef,
    },
    is_alive => 1,
    argv => [qw/--foo/],
    desc => 'with global_struct (foo) / ARGV=--foo',
);

{
    my $foo;
    test_opts(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \$foo ],
            ],
        },
        expects => {
            help => undef,
        },
        is_alive => 1,
        argv => [qw/--foo/],
        desc => 'with global_struct (dest foo)',
    );
}

{
    my $foo;
    test_opts(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \$foo ],
            ],
        },
        expects => {
            help => undef,
        },
        is_alive => 1,
        argv => [qw/--foo/],
        extra_test => sub {
            is $foo, 1, 'dest foo';
        },
        desc => 'with global_struct (dest foo)',
    );
}

{
    my $foo;
    test_opts(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \$foo ],
            ],
        },
        expects => {
            help => undef,
        },
        is_alive => 1,
        argv => [qw/--foo/],
        extra_test => sub {
            is $foo, 1, 'dest foo';
        },
        desc => 'with global_struct (dest foo)',
    );
}

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
    },
    is_alive => 0,
    argv => [qw/--hoge/],
    desc => 'with global_struct (foo) / Unknown option',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
    },
    is_alive => 0,
    argv => [qw/--help/],
    desc => 'with global_struct (foo) / ARGV=--help',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ],
            },
        }
    },
    expects => {
        foo  => undef,
        help => undef,
    },
    is_alive => 1,
    desc => 'with global_struct (foo) / command_struct (bar) / empty ARGV',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    expects => {
        foo  => undef,
        bar  => undef,
        help => undef,
    },
    argv => [qw/hoge/],
    is_alive => 1,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=hoge',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    expects => {
        foo  => undef,
        bar  => 1,
        help => undef,
    },
    argv => [qw/hoge --bar/],
    is_alive => 1,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=hoge --bar',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    expects => {
        foo  => 1,
        bar  => 1,
        help => undef,
    },
    argv => [qw/--foo hoge --bar/],
    is_alive => 1,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=--foo hoge --bar',
);

{
    my $bar;
    test_opts(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!' ],
            ],
            command_struct => {
                hoge => {
                    options => [
                        [ [qw/b bar/], 'bar', '!', \$bar ],
                    ]
                },
            }
        },
        expects => {
            foo  => 1,
            help => undef,
        },
        argv => [qw/--foo hoge --bar/],
        is_alive => 1,
        extra_test => sub {
            is $bar, 1, 'dest bar';
        },
        desc => 'with global_struct (foo) / command_struct (dest bar) / ARGV=--foo hoge --bar',
    );
}

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    argv => [qw/hoge --help/],
    is_alive => 0,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=hoge --help',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    argv => [qw/help/],
    is_alive => 0,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=help',
);

test_opts(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!' ],
        ],
        command_struct => {
            hoge => {
                options => [
                    [ [qw/b bar/], 'bar' ],
                ]
            },
        }
    },
    argv => [qw/help hoge/],
    is_alive => 0,
    desc => 'with global_struct (foo) / command_struct (bar) / ARGV=help hoge',
);

test_opts(
    args => {
        global_struct => {
            foo => {
                alias => [qw/f/],
                type  => '!',
            },
        },
    },
    argv => [],
    is_alive => 1,
    expects => {
        help => undef,
        foo  => undef,
    },
    desc => 'HASH element',
);

test_opts(
    args => {
        global_struct => {
            foo => {
                alias => 'f',
                type  => '!',
            },
        },
    },
    argv => [qw/-f/],
    is_alive => 1,
    expects => {
        help => undef,
        foo  => 1,
    },
    desc => 'alias of SCALAR',
);

test_opts(
    args => {
        global_struct => {
            foo => {
                alias => [qw/f/],
                type  => '!',
            },
        },
        command_struct => {
            hoge => {
                options => {
                    bar => {
                        alias => [qw/b/],
                        type  => '!',
                    },
                },
            },
        },
    },
    argv => [qw/hoge --bar/],
    is_alive => 1,
    expects => {
        help => undef,
        foo  => undef,
        bar  => 1,
    },
    desc => 'HASH element / with command_struct',
);

done_testing;
