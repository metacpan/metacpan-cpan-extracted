use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_has_option {
    my %specs = @_;
    my ($input, $expects, $struct, $desc) = @specs{qw/input expects struct desc/};

    subtest $desc => sub {
        my $go = bless {}, 'Getopt::Compact::WithCmd';
        $go->{struct} = $struct || [];
        ok $expects ? $go->_has_option($input) : !$go->_has_option($input), '_has_option';
        done_testing;
    };
}

test_has_option(
    input   => 'help',
    struct  => [],
    expects => 0,
    desc    => 'help is not found',
);

test_has_option(
    input   => 'help',
    struct  => [
        [ [qw/h help/] ],
    ],
    expects => 1,
    desc    => 'help is registerd',
);

done_testing;
