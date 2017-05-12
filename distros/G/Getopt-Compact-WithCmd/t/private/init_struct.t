use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_init_struct {
    my %specs = @_;

    my ($input, $expects, $opts, $desc) = @specs{qw/input expects opts desc/};

    subtest $desc => sub {
        my $go = bless $opts ? $opts : {}, 'Getopt::Compact::WithCmd';
        $go->_init_struct($input);

        is_deeply $go->{struct}, $expects, 'struct';

        done_testing;
    };
}

test_init_struct(
    input   => [],
    expects => [],
    desc    => 'missing',
);

test_init_struct(
    input   => [
        [ [qw/t test/], 'this is test' ],
    ],
    expects => [
        [ [qw/t test/], 'this is test' ],
    ],
    desc    => 'minimal outs',
);

test_init_struct(
    input   => [],
    expects => [
        [ [qw/h help/], 'this help message' ],
    ],
    opts    => { usage => 1 },
    desc    => 'enable usage',
);

test_init_struct(
    input   => [
        [ [qw/t test/], 'this is test' ],
    ],
    expects => [
        [ [qw/h help/], 'this help message' ],
        [ [qw/t test/], 'this is test' ],
    ],
    opts    => { usage => 1 },
    desc    => 'minimal outs / enable usage',
);

test_init_struct(
    input   => [
        [ [qw/h help/], 'custom help' ],
        [ [qw/t test/], 'this is test' ],
    ],
    expects => [
        [ [qw/h help/], 'custom help' ],
        [ [qw/t test/], 'this is test' ],
    ],
    opts    => { usage => 1 },
    desc    => 'embed help  / enable usage',
);

test_init_struct(
    input   => [
        [ [qw/v verbose/], 'verbose mode' ],
    ],
    expects => [
        [ [qw/t test/], 'test mode' ],
        [ [qw/f foo/], 'foo mode' ],
        [ [qw/b bar/], 'bar mode' ],
        [ [qw/v verbose/], 'verbose mode' ],
    ],
    opts    => {
        modes => [qw/test foo bar/],
    },
    desc    => 'prepended modes',
);

test_init_struct(
    input   => [],
    expects => [
        [ [qw/h help/], 'this help message' ],
        [ [qw/v verbose/], 'verbose mode' ],
    ],
    opts    => {
        modes => [qw/verbose/],
        usage => 1,
    },
    desc    => 'prepended modes with help',
);

done_testing;
