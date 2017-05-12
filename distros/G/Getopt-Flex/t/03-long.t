use strict;
use warnings;
use Test::More tests => 106;
use Getopt::Flex;

my $foo;
my $bar;
my @arr;
my %has;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

$foo = '';
my $op = Getopt::Flex->new({spec => $sp});
my @args = qw(--foo bar);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bar', '--foo set with bar');

$foo = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=baz);
$op->set_args(\@args);
$op->getopts();
is($foo, 'baz', '--foo set with baz');

$foo = 'cats';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foobag);
$op->set_args(\@args);
$op->getopts();
my @va = $op->get_valid_args();
my @ia = $op->get_invalid_args();
my @ea = $op->get_extra_args();
is($foo, 'cats', '--foo left unset with cats');
is($#va, -1, 'va contains 0 values');
is($#ia, 0, 'ia contains 1 values');
is($#ea, -1, 'ea contains 0 values');

$foo = 'bats';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo-boo);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bats', '--foo left unset with bats');

#add more switch specs
$sp = {
  'foo|f' => {
      'var' => \$foo,
      'type' => 'Str',
  },
  'bar|b' => {
      'var' => \$bar,
      'type' => 'Str',
  },
};

$foo = '';
$bar = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aaa --bar bbb);
$op->set_args(\@args);
$op->getopts();
is($foo, 'aaa', '--foo set with aaa');
is($bar, 'bbb', '--bar set with bbb');

#try out required
$sp = {
  'foo|f' => {
      'var' => \$foo,
      'type' => 'Str',
      'required' => 1,
  },
};

$foo = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo box);
$op->set_args(\@args);
$op->getopts();
is($foo, 'box', '--foo set with box');

$foo = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/requires value/, 'Failed to parse because --foo missing required value');

$foo = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/required switch/, 'Failed to parse because missing required argument --foo');

#checking int values
$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--foo set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--foo set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 2.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=2.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

#test out bool
$sp = {
  'foo|f' => {
      'var' => \$foo,
      'type' => 'Bool',
  }  
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo);
$op->set_args(\@args);
$op->getopts();
ok($foo, '--foo set to true');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 0);
$op->set_args(\@args);
$op->getopts();
ok($foo, '--foo set to true');
my @extra_args = $op->get_extra_args();
is($#extra_args, 0, 'Extra args has one element');
is($extra_args[0], 0, 'Extra args contains 0');

#test out num
$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Num',
    }
};

$foo = 1;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '--foo set to 0');

$foo = 1;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '---foo set to 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--foo set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--foo set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '--foo set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '--foo set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aaa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=aaa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

#try incremental
$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Inc',
    }  
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--foo should be 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f -f);
$op->set_args(\@args);
$op->getopts();
is($foo, 2, '--foo should be 2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '--foo should be 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo --foo --foo --foo --foo);
$op->set_args(\@args);
$op->getopts();
is($foo, 5, '--foo should be 5');

#try out arrays
$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($#arr, -1, '--foo set with no values');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa --foo bb --foo cc);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '--foo set with 3 values');
is($arr[0], 'aa', 'arr has 0th elem aa');
is($arr[1], 'bb', 'arr has 1st elem bb');
is($arr[2], 'cc', 'arr has 2nd elem cc');

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Int]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1 --foo 2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--foo set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1 --foo bar);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Num]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1 --foo 2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--foo set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1 --foo 2.2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--foo set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2.2, 'arr has 1st elem 2.2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo 1 --foo bar);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

#try out hashes
$sp = {
  'foo|f' => {
      'var' => \%has,
      'type' => 'HashRef[Str]',
  }  
};

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=foo --foo bb=bar --foo cc=baz);
$op->set_args(\@args);
$op->getopts();
my @keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, 'foo', 'key aa has val foo');
is($has{'bb'}, 'bar', 'key bb has val bar');
is($has{'cc'}, 'baz', 'key cc has val baz');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo=aa=foo --foo=bb=bar --foo=cc=baz);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, 'foo', 'key aa has val foo');
is($has{'bb'}, 'bar', 'key bb has val bar');
is($has{'cc'}, 'baz', 'key cc has val baz');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Int]',
    }
};

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1 --foo bb=2 --foo cc=3);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, 1, 'key aa has val 1');
is($has{'bb'}, 2, 'key bb has val 2');
is($has{'cc'}, 3, 'key cc has val 3');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1 --foo bb=bar --foo cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1 --foo bb=2.2 --foo cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Num]',
    }
};

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1 --foo bb=2 --foo cc=3);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, 1, 'key aa has val 1');
is($has{'bb'}, 2, 'key bb has val 2');
is($has{'cc'}, 3, 'key cc has val 3');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1.1 --foo bb=2.2 --foo cc=3.3);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, 1.1, 'key aa has val 1.1');
is($has{'bb'}, 2.2, 'key bb has val 2.2');
is($has{'cc'}, 3.3, 'key cc has val 3.3');

%has = ();
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo aa=1 --foo bb=bar --foo cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--FOO);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--FOO=1);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($foo, 0, '--foo not set');

$sp = {
	'foo' => {
		'var' => \$foo,
		'type' => 'Str',
	}
};

$foo = '';
$op = Getopt::Flex->new({spec => $sp});
@args = qw(--foo bar);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($foo, 'bar', 'foo set to bar');
