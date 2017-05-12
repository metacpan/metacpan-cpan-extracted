use strict;
use warnings;
use Test::More;

use File::Basename qw/basename/;
use Getopt::Compact::WithCmd;

sub test_usage {
    my %specs = @_;
    my ($args, $expects, $command, $desc, $extra_test, $argv)
        = @specs{qw/args expects command desc extra_test argv/};

    $expects =~ s/%FILE%/basename($0)/gmse;

    $command ||= [];
    $command = [ $command ] unless ref $command eq 'ARRAY';

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    subtest $desc => sub {
        local @::ARGV = @$argv if $argv;
        my $go = new_ok 'Getopt::Compact::WithCmd', [%$args];

        my @got     = split "\n", +$go->usage(@$command);
        my @expects = split "\n", $expects;
        is_deeply \@got, \@expects, 'usage';

        if ($extra_test) {
            $extra_test->($go);
        }

        done_testing;
    };
}

test_usage(
    args => {},
    desc => 'empty params',
    expects => << 'USAGE');
usage: %FILE% [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        args => 'ARGS',
    },
    desc => 'with args',
    expects => << 'USAGE');
usage: %FILE% [options] ARGS

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        cmd => 'foo',
    },
    desc => 'with cmd',
    expects => << 'USAGE');
usage: foo [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        name => 'foo',
    },
    desc => 'with name',
    expects => << 'USAGE');
foo
usage: %FILE% [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        name => 'foo',
        version => '1.0',
    },
    desc => 'with name, version',
    expects => << 'USAGE');
foo v1.0
usage: %FILE% [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    desc => 'with global_struct',
    expects => << 'USAGE');
usage: %FILE% [options]

options:
   -h, --help      This help message
   -f, --foo       Foo              

USAGE

test_usage(
    args => {
        usage => 0,
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
    },
    desc => 'with global_struct (usage: 0)',
    expects => << 'USAGE');
usage: %FILE% [options]

options:
   -f, --foo      Foo

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
    },
    desc => 'with global_struct (foo is required)',
    expects => << 'USAGE');
`--foo` option must be specified
usage: %FILE% [options]

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
    },
    desc => 'with global_struct (foo is required) / set help',
    argv => [qw/--help/],
    expects => << 'USAGE');
usage: %FILE% [options]

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

USAGE

{
    test_usage(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \my $foo, { required => 1 } ],
            ],
        },
        desc => 'with global_struct (foo is required and dest)',
        expects => << 'USAGE');
`--foo` option must be specified
usage: %FILE% [options]

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

USAGE
}

{
    test_usage(
        args => {
            global_struct => [
                [ [qw/f foo/], 'foo', '!', \my $foo, { required => 1 } ],
            ],
        },
        desc => 'with global_struct (foo is required and set dest)',
        argv => [qw/--foo/],
        expects => << 'USAGE');
usage: %FILE% [options]

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

USAGE
}

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    desc => 'with global_struct / command_struct (impl hoge)',
    expects => << 'USAGE');
usage: %FILE% [options] COMMAND

options:
   -h, --help      This help message
   -f, --foo       Foo              

Implemented commands are:
   hoge   

See '%FILE% help COMMAND' for more information on a specific command.

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/help/],
    desc => 'with global_struct / command_struct (impl hoge) / help command',
    expects => << 'USAGE');
usage: %FILE% [options] COMMAND

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

Implemented commands are:
   hoge   

See '%FILE% help COMMAND' for more information on a specific command.

USAGE
test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', '!', undef, { required => 1 } ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/help/],
    desc => 'with global_struct / command_struct (impl hoge) / help command',
    expects => << 'USAGE');
usage: %FILE% [options] COMMAND

options:
   -h, --help                     This help message
   -f, --foo    Bool (required)   Foo              

Implemented commands are:
   hoge   

See '%FILE% help COMMAND' for more information on a specific command.

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge'
            },
        },
    },
    desc => 'with global_struct / command_struct (impl hoge (desc))',
    argv => [qw/help hoge/],
    expects => << 'USAGE');
usage: %FILE% hoge [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge) / command mode',
    expects => << 'USAGE');
usage: %FILE% hoge [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args    => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {},
        },
    },
    argv    => [],
    command => 'hoge',
    desc    => 'with global_struct / command_struct (impl hoge) / args hoge',
    expects => << 'USAGE');
usage: %FILE% hoge [options]

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args)) / command mode',
    expects => << 'USAGE');
usage: %FILE% hoge [options] FILE

options:
   -h, --help      This help message

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
                options => [
                    [ [qw/o output/] , 'output' ],
                ],
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args, options)) / command mode',
    expects => << 'USAGE');
usage: %FILE% hoge [options] FILE

options:
   -h, --help        This help message
   -o, --output      Output           

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                args => 'FILE',
                options => [
                    [ [qw/o output/] , 'output' ],
                ],
                other_usage => 'blah blah blah',
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge (args, options other_usage)) / command mode',
    expects => << 'USAGE');
usage: %FILE% hoge [options] FILE

options:
   -h, --help        This help message
   -o, --output      Output           

blah blah blah

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
            },
        },
    },
    argv => [qw/fuga/],
    desc => 'with global_struct / command_struct (impl hoge (desc)) / Unknown command',
    expects => << 'USAGE');
Unknown command: fuga
usage: %FILE% [options] COMMAND

options:
   -h, --help      This help message
   -f, --foo       Foo              

Implemented commands are:
   hoge   Hoge

See '%FILE% help COMMAND' for more information on a specific command.

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
            },
        },
    },
    argv => [qw/--hoge hoge/],
    desc => 'with global_struct / command_struct (impl hoge (desc)) / Unknown option',
    expects => << 'USAGE');
Unknown option: hoge
usage: %FILE% [options] COMMAND

options:
   -h, --help      This help message
   -f, --foo       Foo              

Implemented commands are:
   hoge   Hoge

See '%FILE% help COMMAND' for more information on a specific command.

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                options => [
                    [ [qw/b bar/], 'bar' ],
                ],
            },
        },
    },
    argv => [qw/hoge --hoge/],
    desc => 'with global_struct / command_struct (impl hoge (desc options)) / Unknown option',
    expects => << 'USAGE');
Unknown option: hoge
usage: %FILE% hoge [options]

options:
   -h, --help      This help message
   -b, --bar       Bar              

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo', undef, undef, { default => sub {} } ],
        ],
    },
    argv => [qw/hoge --hoge/],
    desc => 'with global_struct / Invalid default option',
    expects => << 'USAGE');
Invalid default option for foo
usage: %FILE% [options]

options:
   -h, --help                                This help message
   -f, --foo    (default: sub { "DUMMY" })   Foo              

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                other_usage => 'blah blah blah',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                    },
                },
            },
        },
    },
    argv => [qw/hoge/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = hoge',
    expects => << 'USAGE');
usage: %FILE% hoge [options]

options:
   -h, --help      This help message

blah blah blah

Implemented commands are:
   fuga   Fuga

See '%FILE% hoge COMMAND --help' for more information on a specific command.

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_usage => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/hoge fuga/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = hoge, fuga',
    expects => << 'USAGE');
usage: %FILE% hoge fuga [options] piyo

options:
   -h, --help      This help message
   -b, --bar       Bar              

blah blah blah

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_usage => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/help hoge/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = help, hoge, fuga',
    expects => << 'USAGE');
usage: %FILE% hoge [options]

options:
   -h, --help      This help message

Implemented commands are:
   fuga   Fuga

See '%FILE% hoge COMMAND --help' for more information on a specific command.


USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_usage => 'blah blah blah',
                    },
                },
            },
        },
    },
    argv => [qw/help hoge fuga/],
    desc => 'with global_struct / command_struct (impl hoge -> fuga) / @ARGV = help, hoge, fuga',
    expects => << 'USAGE');
usage: %FILE% hoge fuga [options] piyo

options:
   -h, --help      This help message
   -b, --bar       Bar              

blah blah blah

USAGE

test_usage(
    args => {
        global_struct => [
            [ [qw/f foo/], 'foo' ],
        ],
        command_struct => {
            hoge => {
                desc => 'hoge',
                command_struct => {
                    fuga => {
                        options => [
                            [ [qw/b bar/], 'bar' ],
                        ],
                        desc => 'fuga',
                        args => 'piyo',
                        other_usage => 'blah blah blah',
                    },
                },
            },
        },
    },
    run_ok  => 1,
    command => [qw/hoge fuga/],
    desc    => 'with global_struct / command_struct (impl hoge -> fuga) / command = hoge, fuga',
    expects => << 'USAGE');
usage: %FILE% hoge fuga [options] piyo

options:
   -h, --help      This help message
   -b, --bar       Bar              

blah blah blah

USAGE

done_testing;
