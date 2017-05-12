use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_parse_command_struct {
    my %specs = @_;

    my ($struct, $expects, $args, $opts, $extra_test, $has_error, $desc) =
        @specs{qw/struct expects args opts extra_test has_error desc/};

    subtest $desc => sub {
        local @ARGV = @$args if $args;
        my $go = bless {
            $opts ? %$opts : (),
            _struct => $struct,
        }, 'Getopt::Compact::WithCmd';

        my $got = $go->_parse_command_struct($struct);

        is +$got->{ret}, $expects->{ret}, 'ret value';
        is +$got->{command}, $expects->{command}, 'command';
        is_deeply +$got->{commands}, $expects->{commands}, 'commands';
        is_deeply +$got->{opt}, $expects->{opt}, 'opt';
        is_deeply +$got->{summary}, $expects->{summary}, 'summary';
        is +$got->{error}, $expects->{error}, 'error message';
        
        $extra_test->($got) if $extra_test;

        done_testing;
    };
}

test_parse_command_struct(
    struct  => {},
    expects => {
        ret      => 1,
        command  => undef,
        commands => undef,
        opt      => undef,
        summary  => undef,
    },
    desc => 'missing',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
        },
    },
    expects => {
        ret      => 1,
        command  => undef,
        commands => undef,
        opt      => undef,
        summary  => undef,
    },
    desc => 'impl foo / @ARGV = ()',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
        },
    },
    expects => {
        ret      => 1,
        command  => 'foo',
        commands => ['foo'],
        opt      => {
            hoge => undef,
        },
        summary  => undef,
    },
    args => [qw/foo/],
    desc => 'impl foo / @ARGV = foo',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
        },
    },
    expects => {
        ret      => 0,
        command  => 'help',
        commands => undef,
        opt      => undef,
        summary  => undef,
    },
    args => [qw/help/],
    desc => 'impl foo / @ARGV = help',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
            command_struct => {
                bar => {
                    options => [ [qw/fuga/], 'fuga' ],
                    desc => 'bar',
                },
            },
        },
    },
    expects => {
        ret      => 0,
        command  => 'help',
        commands => undef,
        opt      => undef,
        summary  => {
            bar => 'bar',   
        },
    },
    args => [qw/help foo/],
    desc => 'impl foo -> bar / @ARGV = help foo',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
            command_struct => {
                bar => {
                    options => [ [qw/fuga/], 'fuga' ],
                    desc => 'bar',
                },
            },
        },
    },
    opts => { usage => 1 },
    expects => {
        ret      => 0,
        command  => 'foo',
        commands => [qw/foo/],
        opt      => {
            hoge => undef, 
            help => 1,
        },
        summary  => {
            bar => 'bar',
        },
    },
    args => [qw/foo --help/],
    desc => 'impl foo -> bar / @ARGV = foo --help',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
            command_struct => {
                bar => {
                    options => [
                        [ [qw/fuga/], 'fuga' ],
                    ],
                    desc => 'bar',
                },
            },
        },
    },
    opts => { usage => 1 },
    expects => {
        ret      => 1,
        command  => 'foo',
        commands => [qw/foo bar/],
        opt      => {
            hoge => undef,
            fuga => undef,
            help => undef,
        },
        summary  => {
            bar => 'bar',
        },
    },
    args => [qw/foo bar/],
    desc => 'impl foo -> bar / @ARGV = foo bar',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
            command_struct => {
                bar => {
                    options => [
                        [ [qw/fuga/], 'fuga' ],
                    ],
                    desc => 'bar',
                },
            },
        },
    },
    opts => { usage => 1 },
    expects => {
        ret      => 1,
        command  => 'foo',
        commands => [qw/foo bar/],
        opt      => {
            hoge => 1,
            fuga => 1,
            help => undef,
        },
        summary  => {
            bar => 'bar',
        },
    },
    args => [qw/foo --hoge bar --fuga/],
    desc => 'impl foo -> bar / @ARGV = foo --hoge bar --fuga',
);

test_parse_command_struct(
    struct  => {
        foo => {
            options => [
                [ [qw/hoge/], 'hoge' ],
            ],
            desc => 'foo',
            command_struct => {
                bar => {
                    options => [
                        [ [qw/fuga/], 'fuga' ],
                    ],
                    desc => 'bar',
                },
            },
        },
    },
    opts => { usage => 1 },
    expects => {
        ret      => 0,
        command  => 'foo',
        commands => [qw/foo bar/],
        opt      => {
            hoge => undef,
            fuga => undef,
            help => 1,
        },
        summary  => {
            bar => 'bar',
        },
    },
    args => [qw/foo bar --help/],
    desc => 'impl foo -> bar / @ARGV = foo bar --help',
);

done_testing;
