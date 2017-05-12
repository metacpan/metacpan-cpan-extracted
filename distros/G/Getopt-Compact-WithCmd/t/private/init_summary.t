use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_init_summary {
    my %specs = @_;

    my ($input, $expects, $opts, $desc) = @specs{qw/input expects opts desc/};

    subtest $desc => sub {
        my $go = bless $opts ? $opts : {}, 'Getopt::Compact::WithCmd';
        $go->_init_summary($input);

        is_deeply $go->{summary}, $expects, 'summary';

        done_testing;
    };
}

test_init_summary(
    input   => undef,
    expects => {},
    desc    => 'missing',
);

test_init_summary(
    input   => {
        foo => {
            desc => 'bar',
        }
    },
    expects => {
        foo => 'bar',
    },
    desc    => 'minimal outs',
);

done_testing;
