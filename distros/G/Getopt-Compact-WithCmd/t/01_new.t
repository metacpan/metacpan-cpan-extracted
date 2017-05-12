use strict;
use warnings;
use Test::More;

use File::Basename qw/basename/;
use Getopt::Compact::WithCmd;

sub default_expects {
    return {
        cmd         => basename($0),
        name        => undef,
        version     => $::VERSION,
        modes       => undef,
        opt         => { help => undef },
        usage       => 1,
        args        => '',
        struct      => [
            [ [qw/h help/], 'this help message' ],
        ],
        summary     => {},
        requires    => {},
        ret         => 1,
        error       => undef,
        other_usage => undef,
        _struct     => {},
    };
}

sub test_new {
    my %specs = @_;
    my ($args, $argv, $expects, $expects_argv, $desc, $extra_test)
        = @specs{qw/args argv expects expects_argv desc extra_test/};

    $expects = {
        %{default_expects()},
        %$expects,
    };

    local $Test::Builder::Level = $Test::Builder::Level + 1;
    subtest $desc => sub {
        @::ARGV = @$argv;
        my $go = new_ok 'Getopt::Compact::WithCmd', [%$args];

        for my $key (qw{
            cmd name version modes opt usage args struct summary
            requires ret error other_usage _struct
        }) {
            is_deeply +$go->{$key}, $expects->{$key}, $key;
        }

        is_deeply \@ARGV, $expects_argv, 'ARGV';

        if ($extra_test) {
            $extra_test->($go);
        }

        done_testing;
    };
}

test_new(
    args         => {},
    expects      => {},
    argv         => [],
    expects_argv => [],
    desc         => 'empty args',
);

test_new(
    args => {
        cmd => 'foo',
    },
    expects => {
        cmd => 'foo',
    },
    argv => [],
    expects_argv => [],
    desc => 'with cmd',
);

test_new(
    args => {
        name => 'bar',
    },
    expects => {
        name => 'bar',
    },
    argv => [],
    expects_argv => [],
    desc => 'with name',
);

test_new(
    args => {
        version => '0.01',
    },
    expects => {
        version => '0.01',
    },
    argv => [],
    expects_argv => [],
    desc => 'with version',
);

test_new(
    args => {
        modes => [qw/test foo/],
    },
    expects => {
        modes => [qw/test foo/],
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/t test/], 'test mode' ],
            [ [qw/f foo/], 'foo mode' ],
        ],
        opt => {
            help => undef,
            test => undef,
            foo  => undef,
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with modes',
);

test_new(
    args => {
        usage => 0,
    },
    expects => {
        usage  => 0,
        opt    => {},
        struct => [],
    },
    argv => [],
    expects_argv => [],
    desc => 'with usage',
);

test_new(
    args => {
        args => 'FOO',
    },
    expects => {
        args => 'FOO',
    },
    argv => [],
    expects_argv => [],
    desc => 'with args',
);

test_new(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            help => undef,
            foo  => undef,
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            foo => undef,
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct (usage: 0)',
);

test_new(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            help => 1,
            foo => undef,
        },
    },
    argv => [qw/--help/],
    expects_argv => [],
    desc => 'with global_struct / show usage',
);

test_new(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
    },
    expects => {
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
        opt => {
            help => 1,
            foo => undef,
        },
        requires => {
            foo => 'f|foo!',
        },
    },
    argv => [qw/--help/],
    expects_argv => [],
    desc => 'with global_struct / show usage (required)',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            foo => undef,
        },
        error => 'Unknown option: hoge',
        ret => 0,
    },
    argv => [qw/--hoge/],
    expects_argv => [],
    desc => 'with global_struct / Unknown option',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s' ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s' ],
        ],
        opt => {
            foo => undef,
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct / spec',
);

{
    my $foo;
    test_new(
        args => {
            usage => 0,
            global_struct => [
                [ [qw/f foo/], 'foo', '=s', \$foo ],
            ],
        },
        expects => {
            usage => 0,
            struct => [
                [ [qw/f foo/], 'foo', '=s', \$foo ],
            ],
            opt => {},
        },
        argv => [],
        expects_argv => [],
        desc => 'with global_struct / spec, dest',
    );
};

{
    my $foo;
    test_new(
        args => {
            usage => 0,
            global_struct => [
                [ [qw/f foo/], 'foo', '=s', \$foo, { default => 'bar' } ],
            ],
        },
        expects => {
            usage => 0,
            struct => [
                [ [qw/f foo/], 'foo', '=s', \$foo, { default => 'bar' } ],
            ],
            opt => {},
        },
        argv => [],
        expects_argv => [],
        extra_test => sub {
            is $foo, 'bar', 'default value';
        },
        desc => 'with global_struct / spec, dest, default',
    );
};

{
    my $foo;
    my $coderef = sub { $foo = $_[1] };
    test_new(
        args => {
            usage => 0,
            global_struct => [
                [ [qw/f foo/], 'foo', '=s', $coderef, { default => 'bar' } ],
            ],
        },
        expects => {
            usage => 0,
            struct => [
                [ [qw/f foo/], 'foo', '=s', $coderef, { default => 'bar' } ],
            ],
            opt => {},
        },
        argv => [],
        expects_argv => [],
        extra_test => sub {
            is $foo, 'bar', 'default value';
        },
        desc => 'with global_struct / spec, dest, default',
    );
};

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=i' ],
            [ [qw/b bar/], 'bar' ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=i' ],
            [ [qw/b bar/], 'bar' ],
        ],
        requires => {},
        opt => {
            foo => 100,
            bar => 1,
        },
        error => undef,
        ret => 1,
    },
    argv => [qw/-bf100/],
    expects_argv => [],
    desc => 'with global_struct / allow argv -bf100 (enabled bundling)',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/i index/], 'index', '=i' ],
            [ [qw/I interval/], 'interval', '=i' ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/i index/], 'index', '=i' ],
            [ [qw/I interval/], 'interval', '=i' ],
        ],
        requires => {},
        opt => {
            index    => 100,
            interval => undef,
        },
        error => undef,
        ret => 1,
    },
    argv => [qw/-i 100/],
    expects_argv => [],
    desc => 'with global_struct / default case sensitive',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        requires => {
            foo => 'f|foo=s',
        },
        opt => {
            foo => undef,
        },
        error => '`--foo` option must be specified',
        ret => 0,
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct / must be specified --foo',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        requires => {
            foo => 'f|foo=s',
        },
        opt => {
            foo => 'bar',
        },
    },
    argv => [qw/--foo=bar/],
    expects_argv => [],
    desc => 'with global_struct / --foo=bar',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        requires => {
            foo => 'f|foo=s',
        },
        opt => {
            foo => 'bar',
        },
    },
    argv => [qw/--foo bar baz/],
    expects_argv => [qw/baz/],
    desc => 'with global_struct / --foo bar (not registered command_struct',
);

{
    my $coderef = sub { };
    test_new(
        args => {
            usage => 0,
            global_struct => [
                [ [qw/f foo/], 'foo', '=s', undef, { default => $coderef } ],
            ],
        },
        expects => {
            usage => 0,
            struct => [
                [ [qw/f foo/], 'foo', '=s', undef, { default => $coderef } ],
            ],
            opt => {
                foo => undef,
            },
            error => 'Invalid default option for foo',
            ret => 0,
        },
        argv => [],
        expects_argv => [],
        desc => 'with global_struct / invalid default option',
    );
}

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s%', undef, { default => { bar => 'baz' } } ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s%', undef, { default => { bar => 'baz' } } ],
        ],
        opt => {
            foo => { bar => 'baz' },
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct / default hashref',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '=s%', undef ],
        ],
    },
    expects => {
        usage => 0,
        struct => [
            [ [qw/f foo/], 'foo', '=s%', undef ],
        ],
        opt => {
            foo => { bar => 'baz', hoge => 'fuga' },
        },
    },
    argv => [qw/--foo bar=baz --foo=hoge=fuga piyo/],
    expects_argv => [qw/piyo/],
    desc => 'with global_struct / --foo bar=baz --foo=hoge=fuga',
);

test_new(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo', '', '', { required => 1 } ],
        ],
        command_struct => {
            foo => {},
        },
    },
    expects => {
        summary => {
            foo => '',
        },
        struct => [
            [ [qw/f foo/], 'foo', '', '', { required => 1 } ],
        ],
        opt => {
            foo => undef,
        },
        requires => {
            foo => 'f|foo',
        },
        _struct => {
            foo => {},
        },
        error => '`--foo` option must be specified',
        ret => 0,
        usage => 0,
    },
    argv => [],
    expects_argv => [],
    desc => 'with global_struct (implemented: foo) / empty params',
);

test_new(
    args => {
        command_struct => {
            foo => {},
        },
    },
    expects => {
        summary => {
            foo => '',
        },
        _struct => {
            foo => {},
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / empty params',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc => 'bar',
            },
        },
    },
    expects => {
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc => 'bar',
            },
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
        },
    },
    expects => {
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec, args (no ARGV)',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
        },
    },
    expects => {
        args => 'baz',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        opt => {
            help => undef,
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
        ],
    },
    argv => [qw/foo/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec, args (ARGV=foo)',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
        },
    },
    expects => {
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        ret => 0,
        error => 'Unknown command: bar',
    },
    argv => [qw/bar/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / Unknown command',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
        },
    },
    expects => {
        args => 'baz',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc => 'bar',
                args => 'baz',
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        opt => {
            help => undef,
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
        ],
        ret => 0,
        error => 'Unknown option: bar',
    },
    argv => [qw/foo --bar/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / Unknown option',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
            },
        },
    },
    expects => {
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
            },
        },
    },
    argv => [],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec, args, other_usage (no ARGV)',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
            },
        },
    },
    expects => {
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
        ],
        opt => {
            help => undef,
        },
    },
    argv => [qw/foo/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec, args, other_usage (ARGV=foo)',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo' ],
                ],
            },
        },
    },
    expects => {
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/h help/], 'this help message' ],
                    [ [qw/f foo/], 'foo' ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            foo  => undef,
            help => undef,
        },
    },
    argv => [qw/foo/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / dsec, args, other_usage options (ARGV=foo)',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo' ],
                ],
            },
        },
    },
    expects => {
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/h help/], 'this help message' ],
                    [ [qw/f foo/], 'foo' ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo' ],
        ],
        opt => {
            foo  => undef,
            help => undef,
        },
        ret => 0,
        error => 'Unknown option: bar',
    },
    argv => [qw/foo --bar/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / Unknown option: bar',
);

{
    my $foo;
    test_new(
        args => {
            command_struct => {
                foo => {
                    desc        => 'bar',
                    args        => 'baz',
                    other_usage => 'free',
                    options     => [
                        [ [qw/f foo/], 'foo', '=s',  \$foo ],
                    ],
                },
            },
        },
        expects => {
            args => 'baz',,
            other_usage => 'free',
            summary => {
                foo => 'bar',
            },
            _struct => {
                foo => {
                    desc        => 'bar',
                    args        => 'baz',
                    other_usage => 'free',
                    options     => [
                        [ [qw/h help/], 'this help message' ],
                        [ [qw/f foo/], 'foo', '=s', \$foo ],
                    ],
                },
                help => {
                    desc => 'show help message',
                    args => '[COMMAND]',
                },
            },
            struct => [
                [ [qw/h help/], 'this help message' ],
                [ [qw/f foo/], 'foo', '=s', \$foo ],
            ],
            opt => {
                help => undef,
            },
        },
        argv => [qw/foo --foo bar/],
        expects_argv => [],
        extra_test => sub {
            is $foo, 'bar', 'desc value';
        },
        desc => 'with command_struct (implemented: foo) / destination',
    );
}

{
    my $foo;
    test_new(
        args => {
            command_struct => {
                foo => {
                    desc        => 'bar',
                    args        => 'baz',
                    other_usage => 'free',
                    options     => [
                        [ [qw/f foo/], 'foo', '=s',  \$foo, { default => 'hoge' } ],
                    ],
                },
            },
        },
        expects => {
            args => 'baz',,
            other_usage => 'free',
            summary => {
                foo => 'bar',
            },
            _struct => {
                foo => {
                    desc        => 'bar',
                    args        => 'baz',
                    other_usage => 'free',
                    options     => [
                        [ [qw/h help/], 'this help message' ],
                        [ [qw/f foo/], 'foo', '=s', \$foo, { default => 'hoge' } ],
                    ],
                },
                help => {
                    desc => 'show help message',
                    args => '[COMMAND]',
                },
            },
            struct => [
                [ [qw/h help/], 'this help message' ],
                [ [qw/f foo/], 'foo', '=s', \$foo, { default => 'hoge' } ],
            ],
            opt => {
                help => undef,
            },
        },
        argv => [qw/foo/],
        expects_argv => [],
        extra_test => sub {
            is $foo, 'hoge', 'default value';
        },
        desc => 'with command_struct (implemented: foo) / default',
    );
}

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s',  undef, { required => 1 } ],
                ],
            },
        },
    },
    expects => {
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/h help/], 'this help message' ],
                    [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        opt => {
            foo  => undef,
            help => undef,
        },
        requires => {
            foo => 'f|foo=s',
        },
        ret => 0,
        error => '`--foo` option must be specified',
    },
    argv => [qw/foo/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / must be specified',
);

test_new(
    args => {
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s',  undef, { required => 1 } ],
                ],
            },
        },
    },
    expects => {
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/h help/], 'this help message' ],
                    [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/h help/], 'this help message' ],
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        opt => {
            foo  => 'bar',
            help => undef,
        },
        requires => {
            foo => 'f|foo=s',
        },
    },
    argv => [qw/foo --foo bar/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / --foo=bar',
);

test_new(
    args => {
        usage => 0,
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s',  undef, { required => 1 } ],
                ],
            },
        },
    },
    expects => {
        usage => 0,
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        opt => {
            foo  => 'bar',
        },
        requires => {
            foo => 'f|foo=s',
        },
    },
    argv => [qw/foo --foo bar/],
    expects_argv => [],
    desc => 'with command_struct (implemented: foo) / usage 0',
);

test_new(
    args => {
        usage => 0,
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s',  undef, { required => 1 } ],
                ],
            },
        },
    },
    expects => {
        usage => 0,
        args => 'baz',,
        other_usage => 'free',
        summary => {
            foo => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
                ],
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
        ],
        opt => {
            foo  => 'bar',
        },
        requires => {
            foo => 'f|foo=s',
        },
    },
    argv => [qw/foo --foo bar baz/],
    expects_argv => [qw/baz/],
    desc => 'with command_struct (implemented: foo) / ex augv',
);

test_new(
    args => {
        usage => 0,
        command_struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s',  undef, { required => 1 } ],
                ],
                command_struct => {
                    bar => {
                        desc        => 'bar',
                        args        => 'piyo',
                        other_usage => 'hoge hoge',
                        options     => [
                            [ [qw/f fuga/], 'fuga' ],
                        ],
                    }
                },
            },
        },
    },
    expects => {
        usage => 0,
        args => 'piyo',
        other_usage => 'hoge hoge',
        summary => {
            bar => 'bar',
        },
        _struct => {
            foo => {
                desc        => 'bar',
                args        => 'baz',
                other_usage => 'free',
                options     => [
                    [ [qw/f foo/], 'foo', '=s', undef, { required => 1 } ],
                ],
                command_struct => {
                    bar => {
                        desc        => 'bar',
                        args        => 'piyo',
                        other_usage => 'hoge hoge',
                        options     => [
                            [ [qw/f fuga/], 'fuga' ],
                        ],
                    },
                    help => {
                        desc => 'show help message',
                        args => '[COMMAND]',
                    },
                },
            },
            help => {
                desc => 'show help message',
                args => '[COMMAND]',
            },
        },
        struct => [
            [ [qw/f fuga/], 'fuga' ],
        ],
        opt => {
            foo  => 'foo',
            fuga => 1,
        },
        requires => {
            foo => 'f|foo=s',
        },
    },
    argv => [qw/foo --foo=foo bar baz --fuga/],
    expects_argv => [qw/baz/],
    desc => 'with command_struct (implemented: foo -> bar) / ex augv',
);

done_testing;
