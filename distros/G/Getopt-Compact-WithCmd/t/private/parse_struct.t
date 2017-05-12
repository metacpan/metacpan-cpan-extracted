use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_parse_struct {
    my %specs = @_;

    my ($struct, $expects, $opts, $extra_test, $has_error, $desc) =
        @specs{qw/struct expects opts extra_test has_error desc/};

    subtest $desc => sub {
        my $go = bless $opts ? $opts : {}, 'Getopt::Compact::WithCmd';
        $go->{struct}   = $struct;
        $go->{opt}      = {};
        $go->{requires} = {};

        my $got = $go->_parse_struct();

        if ($has_error) {
            ok !$got, 'not ok';
            is $go->{ret}, 0, 'ret value';
            is $go->{error}, $expects->{error}, 'error message';
            return;
        }

        my $opt_map = { map { $_ => 1 } keys %$got };

        is_deeply $opt_map, $expects->{opt_map}, 'opt map';
        is_deeply $go->{opt}, $expects->{opt}, 'opt';
        is_deeply $go->{requires}, $expects->{requires}, 'requires';
        
        $extra_test->($go) if $extra_test;

        done_testing;
    };
}

test_parse_struct(
    struct  => [],
    expects => {
        opt_map  => {},
        opt      => {},
        requires => {},
    },
    desc => 'missing',
);

test_parse_struct(
    struct  => [
        [ [qw/f foo/], 'foo' ],
    ],
    expects => {
        opt_map => {
            'f|foo' => 1,
        },
        opt => {
            foo => undef,
        },
        requires => {},
    },
    desc => 'minimal',
);

test_parse_struct(
    struct  => [
        [ [qw/f foo/], 'foo', '=s' ],
        [ [qw/b bar/], 'bar', '!' ],
        [ [qw/baz/], 'baz', ':i' ],
    ],
    expects => {
        opt_map => {
            'f|foo=s' => 1,
            'b|bar!'  => 1,
            'baz:i'   => 1,
        },
        opt => {
            foo => undef,
            bar => undef,
            baz => undef,
        },
        requires => {},
    },
    desc => 'with type',
);

{
    my $foo;
    test_parse_struct(
        struct  => [
            [ [qw/f foo/], 'foo', '=s', \$foo ],
        ],
        expects => {
            opt_map => {
                'f|foo=s' => 1,
            },
            opt => {},
            requires => {},
        },
        extra_test => sub {
            is $foo, undef, 'foo is ok';
        },
        desc => 'with bind',
    );
}

{
    my $foo;
    test_parse_struct(
        struct  => [
            [ [qw/f foo/], 'foo', '=s', \$foo, { default => 'hoge' } ],
            [ [qw/b bar/], 'bar', '!', undef, { default => 1 } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s' => 1,
                'b|bar!'  => 1,
            },
            opt => {
                bar => 1,
            },
            requires => {},
        },
        extra_test => sub {
            is $foo, 'hoge', 'foo is ok';
        },
        desc => 'with default',
    );
}

test_parse_struct(
    struct => [
        [ [qw/f foo/], 'foo', '=s@' ],
    ],
    expects => {
        opt_map => {
            'f|foo=s@' => 1,
        },
        opt => {
            foo => undef,
        },
        requires => {},
    },
    desc => 'with array',
);

test_parse_struct(
    struct => [
        [ [qw/f foo/], 'foo', '=s@', undef, { default => [qw/bar baz/] } ],
    ],
    expects => {
        opt_map => {
            'f|foo=s@' => 1,
        },
        opt => {
            foo => [qw/bar baz/],
        },
        requires => {},
    },
    desc => 'with array / default',
);

{
    my @foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s@', \@foo ],
        ],
        expects => {
            opt_map => {
                'f|foo=s@' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply \@foo, [], 'foo is ok',
        },
        desc => 'with bind array',
    );
}

{
    my @foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s', \@foo, { default => [qw/bar/] } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply \@foo, [qw/bar/], 'foo is ok',
        },
        desc => 'with bind array / default',
    );
}

{
    my $foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s@', \$foo, { default => [qw/bar/] } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s@' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply $foo, [qw/bar/], 'foo is ok',
        },
        desc => 'with bind arrayref / default',
    );
}

test_parse_struct(
    struct => [
        [ [qw/f foo/], 'foo', '=s%', undef, { default => { bar => 'baz' } } ],
    ],
    expects => {
        opt_map => {
            'f|foo=s%' => 1,
        },
        opt => {
            foo => { bar => 'baz' },
        },
        requires => {},
    },
    desc => 'with hash / default',
);

{
    my %foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s', \%foo, { default => { bar => 'baz' } } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply \%foo, { bar => 'baz' }, 'foo is_deeply';
        },
        desc => 'with hash / default',
    );
}

{
    my $foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s%', \$foo, { default => { bar => 'baz' } } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s%' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply $foo, { bar => 'baz' }, 'foo is_deeply';
        },
        desc => 'with hashref / default',
    );
}

{
    my %foo;
    test_parse_struct(
        struct => [
            [ [qw/f foo/], 'foo', '=s%', sub { (my $opt, %foo) = @_ }, {
                default => { bar => 'baz' }
            } ],
        ],
        expects => {
            opt_map => {
                'f|foo=s%' => 1,
            },
            opt => {
            },
            requires => {},
        },
        extra_test => sub {
            is_deeply \%foo, { bar => 'baz' }, 'foo is_deeply';
        },
        desc => 'with coderef / default',
    );
}

test_parse_struct(
    struct  => [
        [ [qw/f foo/], 'foo', '=s', undef, { default => 'hoge', required => 1 } ],
        [ [qw/b bar/], 'bar', '!', undef, { default => 1, required => 0 } ],
    ],
    expects => {
        opt_map => {
            'f|foo=s' => 1,
            'b|bar!'  => 1,
        },
        opt => {
            foo => 'hoge',
            bar => 1,
        },
        requires => {
            foo => 'f|foo=s',
        },
    },
    desc => 'with required',
);

test_parse_struct(
    struct => [
        [ [qw/f foo/], 'foo', '=i', undef, { default => 'hoge' } ],
    ],
    has_error => 1,
    expects => {
        error => 'Value "hoge" invalid for option foo (number expected)',
    },
    desc => 'invalid type / must be integer',
);

test_parse_struct(
    struct => [
        [ [qw/f foo/], 'foo', '=i', undef, { default => sub { } } ],
    ],
    has_error => 1,
    expects => {
        error => 'Invalid default option for foo',
    },
    desc => 'invalid type / invalid default option',
);

done_testing;
