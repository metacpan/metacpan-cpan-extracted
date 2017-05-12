use strict;
use warnings;
use Test::More tests => 31;
use Test::Exception;
use Getopt::Flex;

my $foo;
my $bar;
my @arr;
my %has;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'default' => 'FooBarBaz',
    }
};

my $op = Getopt::Flex->new({spec => $sp});
my @args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 'FooBarBaz', 'foo set with default FooBarBaz');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo hello);
$op->set_args(\@args);
$op->getopts();
is($foo, 'hello', 'foo set with hello');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Bool',
        'default' => 1,
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
$op->getopts();
ok($foo, '--foo set with default 1');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Num',
        'default' => 12.3,
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 12.3, '-f set with default 12.3');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 3.14);
$op->set_args(\@args);
$op->getopts();
is($foo, 3.14, '-f set with 3.14');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
        'default' => 12,
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 3.14);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 3);
$op->set_args(\@args);
$op->getopts();
is($foo, 3, '-f set with 3');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
        'default' => sub { 2**2 },
    },
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 3);
$op->set_args(\@args);
$op->getopts();
is($foo, 3, '-f set with 3');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 2**2, '-f set with default 4');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
        'default' => 12.3,
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with supplied default fails type constraint';


$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
        'default' => sub { 2+2+2 },
        'validator' => sub { $_[0] < 6 },
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with supplied default fails supplied validation check';

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Int]',
        'default' => sub{ [1, 2, 3] },
    }
};

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 4);
$op->set_args(\@args);
$op->getopts();
is($#arr, 3, 'arr contains 3 default values plus one supplied value');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');
is($arr[2], 3, 'arr has 2nd elem 3');
is($arr[3], 4, 'arr has 3rd elem 4');

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Int]',
        'default' => sub{ [1, 2, 3.3] },
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with default value fails type constraint';

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Int]',
        'default' => sub{ [1, 2, 3] },
        'validator' => sub { $_[0] < 1 },
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with default value fails supplied validation check';

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Int]',
        'default' => sub { { 'foo' => 1 } },
    }
};

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f bar=2);
$op->set_args(\@args);
$op->getopts();
my @keys = sort keys %has;
is($#keys, 1, 'keys has 2 values');
is($keys[0], 'bar', 'keys has 0th elem bar');
is($keys[1], 'foo', 'keys has 1st elem foo');
is($has{'bar'}, 2, 'bar set with value 2');
is($has{'foo'}, 1, 'foo set with default 1');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f bar=2 -f foo=3);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 1, 'keys has 2 values');
is($keys[0], 'bar', 'keys has 0th elem bar');
is($keys[1], 'foo', 'keys has 1st elem foo');
is($has{'bar'}, 2, 'bar set with value 2');
is($has{'foo'}, 3, 'foo set with value 3');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Int]',
        'default' => sub { 'foo' => 'bar' },
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with supplied default fails type constraint';

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Int]',
        'default' => sub { 'foo' => 10 },
        'validator' => sub { $_[0] < 10 },
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with supplied default fails supplied validation check';
