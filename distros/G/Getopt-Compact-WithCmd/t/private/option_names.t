use strict;
use warnings;
use Test::More;
use Getopt::Compact::WithCmd;

sub test_option_names {
    my %specs = @_;
    my ($input, $expects, $desc) = @specs{qw/input expects desc/};
    
    subtest $desc => sub {
        my $got = [ Getopt::Compact::WithCmd->_option_names($input) ];
        is_deeply $got, $expects, 'option_names';
        done_testing;
    };
}

test_option_names(
    input   => 'a',
    expects => [qw/a/],
    desc    => 'scalar',
);

test_option_names(
    input   => ['a'],
    expects => [qw/a/],
    desc    => 'array ref',
);

test_option_names(
    input   => [qw/a and/],
    expects => [qw/a and/],
    desc    => 'array ref with multi',
);

test_option_names(
    input   => [qw/and a/],
    expects => [qw/a and/],
    desc    => 'array ref with multi / rand',
);

done_testing;
