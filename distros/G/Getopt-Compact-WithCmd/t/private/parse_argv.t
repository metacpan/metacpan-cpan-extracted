use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

my $go = Getopt::Compact::WithCmd->new;

sub test_parse_argv {
    my %specs = @_;

    my ($input, $expects, $sub_command, $desc) =
        @specs{qw/input expects sub_command desc/};

    subtest $desc => sub {
        local @ARGV = @$input;
        $go->{_struct} = $sub_command || {};
        my @opts = $go->_parse_argv;

        is_deeply \@opts, $expects, 'parse argv';

        done_testing;
    };
};

test_parse_argv(
    input   => [],
    expects => [],
    desc    => 'empty',
);

test_parse_argv(
    input   => [qw/--foo/],
    expects => [qw/--foo/],
    desc    => 'simple',
);

test_parse_argv(
    input       => [qw/--foo bar baz/],
    expects     => [qw/--foo bar/],
    sub_command => { bar => 1 },
    desc        => 'with cmd',
);

test_parse_argv(
    input       => [qw/--foo=bar/],
    expects     => [qw/--foo=bar/],
    sub_command => { bar => 1 },
    desc        => 'string argv',
);

test_parse_argv(
    input       => [qw/--foo=bar baz hoge/],
    expects     => [qw/--foo=bar baz/],
    sub_command => { baz => 1 },
    desc        => 'string argv with cmd',
);

done_testing;
