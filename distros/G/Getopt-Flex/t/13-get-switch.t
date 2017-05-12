use strict;
use warnings;
use Test::More tests => 102;
use Getopt::Flex;

my $sp = {
    'foo|bar|baz|bot|box|bat' => {
        'type' => 'Str',
    }
};

my $op = Getopt::Flex->new({spec => $sp});
my @args = qw(--foo=BAR);
$op->set_args(\@args);
$op->getopts();
is($op->get_switch('foo'), 'BAR', 'Switch --foo set with BAR');
is($op->get_switch('bar'), 'BAR', 'Switch --foo set with BAR');
is($op->get_switch('baz'), 'BAR', 'Switch --foo set with BAR');
is($op->get_switch('bot'), 'BAR', 'Switch --foo set with BAR');
is($op->get_switch('box'), 'BAR', 'Switch --foo set with BAR');
is($op->get_switch('bat'), 'BAR', 'Switch --foo set with BAR');

$sp = {
   'foo|bar|baz|bot|box|bat' => {
        'type' => 'Int',
    } 
};

$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 10);
$op->set_args(\@args);
$op->getopts();
is($op->get_switch('foo'), 10, 'Switch --foo set with 10');
is($op->get_switch('bar'), 10, 'Switch --foo set with 10');
is($op->get_switch('baz'), 10, 'Switch --foo set with 10');
is($op->get_switch('bot'), 10, 'Switch --foo set with 10');
is($op->get_switch('box'), 10, 'Switch --foo set with 10');
is($op->get_switch('bat'), 10, 'Switch --foo set with 10');

$sp = {
   'foo|bar|baz|bot|box|bat' => {
        'type' => 'ArrayRef[Int]',
    }  
};

$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 10 --foo 11 --foo 12);
$op->set_args(\@args);
$op->getopts();
my @arr = @{$op->get_switch('foo')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');
@arr = @{$op->get_switch('bar')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');
@arr = @{$op->get_switch('baz')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');
@arr = @{$op->get_switch('bot')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');
@arr = @{$op->get_switch('box')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');
@arr = @{$op->get_switch('bat')};
is($#arr, 2, 'arr set with 2 values');
is($arr[0], 10, 'arr has 0th elem 10');
is($arr[1], 11, 'arr has 1st elem 11');
is($arr[2], 12, 'arr has 2nd elem 12');

$sp = {
    'foo|bar|baz|bot|box|bat' => {
        'type' => 'HashRef[Str]',
    }
};

$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=aa --foo bb=bb --foo cc=cc);
$op->set_args(\@args);
$op->getopts();
my %has = %{$op->get_switch('foo')};
my @keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');
%has = %{$op->get_switch('bar')};
@keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');
%has = %{$op->get_switch('baz')};
@keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');
%has = %{$op->get_switch('bot')};
@keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');
%has = %{$op->get_switch('box')};
@keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');
%has = %{$op->get_switch('bat')};
@keys = sort keys %has;
is($#keys, 2, 'keys has 3 elems');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 'aa', 'key aa has value aa');
is($has{'bb'}, 'bb', 'key bb has value bb');
is($has{'cc'}, 'cc', 'key cc has value cc');

$sp = {
    'foo|bar|baz|bot|box|bat' => {
        'type' => 'Inc',
    }
};

$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo --foo);
$op->set_args(\@args);
$op->getopts();
is($op->get_switch('foo'), 2, 'switch --foo encountered 2 times');
is($op->get_switch('bar'), 2, 'switch --foo encountered 2 times');
is($op->get_switch('baz'), 2, 'switch --foo encountered 2 times');
is($op->get_switch('bot'), 2, 'switch --foo encountered 2 times');
is($op->get_switch('box'), 2, 'switch --foo encountered 2 times');
is($op->get_switch('bat'), 2, 'switch --foo encountered 2 times');

#case insensitive
my $cfg = {
    'case_mode' => 'INSENSITIVE',
};

$sp = {
    'foo|bar|baz|bot|box|bat' => {
        'type' => 'Str',
    }
};

$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--Foo BAR);
$op->set_args(\@args);
$op->getopts();
is($op->get_switch('foo'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bar'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('baz'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bot'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('box'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bat'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Foo'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Bar'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Baz'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Bot'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Box'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('Bat'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('fOO'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bAR'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bAZ'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bOT'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bOX'), 'BAR', 'Switch --Foo set with BAR');
is($op->get_switch('bAT'), 'BAR', 'Switch --Foo set with BAR');
