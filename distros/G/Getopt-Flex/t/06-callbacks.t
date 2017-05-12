use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;
use Getopt::Flex;

my $foo;
my @arr;
my %has;
my $cbv;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'callback' => sub { $cbv .= $_[0] },
    }
};

$cbv = '';
my $op = Getopt::Flex->new({spec => $sp});
my @args = qw(-f race -f car);
$op->set_args(\@args);
$op->getopts();
is($foo, 'car', '-f set to car');
is($cbv, 'racecar', 'cbv is racecar');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
        'callback' => sub { $cbv += $_[0] },
    }
};

$cbv = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 10 -f 20);
$op->set_args(\@args);
$op->getopts();
is($foo, 20, '-f set to 20');
is($cbv, 30, 'cbv is 30');

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
        'callback' => sub { $cbv .= $_[0] },
    }
};

@arr = ();
$cbv = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f a -f b -f c);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '-f set with 3 values');
is($arr[0], 'a', 'arr has 0th elem a');
is($arr[1], 'b', 'arr has 1st elem b');
is($arr[2], 'c', 'arr has 2nd elem c');
is($cbv, 'abc', 'cbv is abc');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Str]',
        'callback' => sub { $cbv .= $_[0] . 'c' },
    }
};

%has = ();
$cbv = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f aa=ar -f bb=ti);
$op->set_args(\@args);
$op->getopts();
my @keys = sort keys %has;
is($#keys, 1, 'keys has 2 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($has{'aa'}, 'ar', 'aa set with ar');
is($has{'bb'}, 'ti', 'bb set with ti');
is($cbv, 'arctic', 'cbv is arctic');
