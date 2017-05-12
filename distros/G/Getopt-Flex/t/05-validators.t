use strict;
use warnings;
use Test::More tests => 21;
use Getopt::Flex;

my $foo;
my $bar;
my @arr;
my %has;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
        'validator' => sub { $_[0] =~ /ar/ },
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Num',
        'validator' => sub { $_[0] < 10 },
    }
};

my $op = Getopt::Flex->new({spec => $sp});
my @args = qw(-f bar -b 1.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bar', '-f set to bar');
is($bar, 1.2, '-b set to 1.2');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f bar -b 12);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/supplied validation/, 'Failed to parse because value fails supplied validation check');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f baz -b 1.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/supplied validation/, 'Failed to parse because value fails supplied validation check');

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Num]',
        'validator' => sub { $_[0] > 10 },
    },
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 12 -f 13 -f 11);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '-f set with three values');
is($arr[0], 12, 'arr has 0th elem 12');
is($arr[1], 13, 'arr has 1st elem 12');
is($arr[2], 11, 'arr has 2nd elem 12');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 11 -f 9);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/supplied validation/, 'Failed to parse because value fails supplied validation check');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Num]',
        'validator' => sub { $_[0] > 10 },
    },
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f aa=12 -f bb=13 -f cc=11);
$op->set_args(\@args);
$op->getopts();
my @keys = sort keys %has;
is($#keys, 2, 'keys has 3 values');
is($keys[0], 'aa', 'keys has 0th elem aa');
is($keys[1], 'bb', 'keys has 1st elem bb');
is($keys[2], 'cc', 'keys has 2nd elem cc');
is($has{'aa'}, 12, 'key aa has value 12');
is($has{'bb'}, 13, 'key aa has value 13');
is($has{'cc'}, 11, 'key aa has value 11');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f aa=11 -f bb=9);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/supplied validation/, 'Failed to parse because value fails supplied validation check');
