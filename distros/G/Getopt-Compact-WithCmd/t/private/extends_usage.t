use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_extends_usage {
    my %specs = @_;
    my ($input, $expects, $desc) = @specs{qw/input expects desc/};

    subtest $desc => sub {
        my $go = bless {}, 'Getopt::Compact::WithCmd';
        $go->_extends_usage($input);

        is $go->{args}, $expects->{args}, 'args';
        is $go->{other_usage}, $expects->{other_usage}, 'other_usage';

        done_testing;
    };
}

test_extends_usage(
    input => {},
    expects => {},
    desc => 'missing',
);

test_extends_usage(
    input => {
        args        => 'ARGS',
        other_usage => 'blah blah blah',
    },
    expects => {
        args        => 'ARGS',
        other_usage => 'blah blah blah',
    },
    desc => 'all params',
);

done_testing;
