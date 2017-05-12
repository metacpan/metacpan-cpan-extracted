use warnings;
use strict;
use Test::More tests => 271;
use Getopt::Flex;

my $foo;
my $bar;
my $cab;
my @arr;
my %has;

my $cfg = {
    'case_mode' => 'INSENSITIVE',
};

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

$foo = '';
my $op = Getopt::Flex->new({spec => $sp, config => $cfg});
my @args = qw(-F bar);
$op->set_args(\@args);
$op->getopts();
my @va = $op->get_valid_args();
my @ia = $op->get_invalid_args();
my @ea = $op->get_extra_args();
is($foo, 'bar', '-F set with bar');
is($#va, 0, 'va contains 1 value');
is($#ia, -1, 'ia contains 0 values');
is($#ea, -1, 'ea contains 0 values');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=baz);
$op->set_args(\@args);
$op->getopts();
@va = $op->get_valid_args();
@ia = $op->get_invalid_args();
@ea = $op->get_extra_args();
is($foo, 'baz', '-F set with baz');
is($#va, 0, 'va contains 1 value');
is($#ia, -1, 'ia contains 0 values');
is($#ea, -1, 'ea contains 0 values');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-Fbag);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bag', '-F set with bag');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F-boo);
$op->set_args(\@args);
$op->getopts();
is($foo, '-boo', '-F set with boo');

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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aaa -b bbb);
$op->set_args(\@args);
$op->getopts();
@va = $op->get_valid_args();
@ia = $op->get_invalid_args();
@ea = $op->get_extra_args();
is($foo, 'aaa', '-F set with aaa');
is($bar, 'bbb', '-b set with bbb');
is($#va, 1, 'va contains 2 values');
is($#ia, -1, 'ia contains 0 values');
is($#ea, -1, 'ea contains 0 values');

#try out required
$sp = {
  'foo|f' => {
      'var' => \$foo,
      'type' => 'Str',
      'required' => 1,
  },
};

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F box);
$op->set_args(\@args);
$op->getopts();
is($foo, 'box', '-F set with box');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/requires value/, 'Failed to parse because -F missing required value');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/required switch/, 'Failed to parse because missing required argument -F');

#checking int values
$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 2.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F2.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=2.2);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-F set to true');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 0);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-F set to true');
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '-F set to 0');

$foo = 1;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '-F set to 0');

$foo = 1;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '-F set to 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '-F set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '-F set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '-F set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aaa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=aaa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-Faaa);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '-F should be 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F -F);
$op->set_args(\@args);
$op->getopts();
is($foo, 2, '-F should be 2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '-F should be 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F -F -F -F -F);
$op->set_args(\@args);
$op->getopts();
is($foo, 5, '-F should be 5');

#try out arrays
$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($#arr, -1, '-F set with no values');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa -F bb -F cc);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '-F set with 3 values');
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1 -F 2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '-F set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1 -F bar);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1 -F 2 -F 3);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '-F set with 3 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');
is($arr[2], 3, 'arr has 2nd elem 3');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1 -F 2.2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '-F set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2.2, 'arr has 1st elem 2.2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F 1 -F bar);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=foo -F bb=bar -F cc=baz);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=aa=foo -F=bb=bar -F=cc=baz);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1 -F bb=2 -F cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1 -F bb=bar -F cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

%has = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1 -F bb=2.2 -F cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1 -F bb=2 -F cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1.1 -F bb=2.2 -F cc=3.3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=1 -F bb=bar -F cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F -2);
$op->set_args(\@args);
$op->getopts();
ok($op->getopts(), 'Parses ok');
is($foo, -2, '-F set with -2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=-2);
$op->set_args(\@args);
$op->getopts();
ok($op->getopts(), 'Parses ok');
is($foo, -2, '-F set with -2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F-2);
$op->set_args(\@args);
$op->getopts();
ok($op->getopts(), 'Parses ok');
is($foo, -2, '-F set with -2');


$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Int]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F -2 -F 3 -F -10);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($#arr, 2, '-F set with 3 values');
is($arr[0], -2, 'arr has 0th elem -2');
is($arr[1], 3, 'arr has 1st elem 3');
is($arr[2], -10, 'arr has 3rd elem -10');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=-2 -F=3 -F=-10);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($#arr, 2, '-F set with 3 values');
is($arr[0], -2, 'arr has 0th elem -2');
is($arr[1], 3, 'arr has 1st elem 3');
is($arr[2], -10, 'arr has 3rd elem -10');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F-2 -F3 -F-10);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($#arr, 2, '-F set with 3 values');
is($arr[0], -2, 'arr has 0th elem -2');
is($arr[1], 3, 'arr has 1st elem 3');
is($arr[2], -10, 'arr has 3rd elem -10');

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Int]',
    }
};

%has = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F aa=-11 -F bb=2 -F cc=-3);
$op->set_args(\@args);
$op->getopts();
@keys = sort keys %has;
is($#keys, 2, 'has has 3 keys');
is($keys[0], 'aa', 'has key aa');
is($keys[1], 'bb', 'has key bb');
is($keys[2], 'cc', 'has key cc');
is($has{'aa'}, -11, 'key aa has val -11');
is($has{'bb'}, 2, 'key bb has val 2');
is($has{'cc'}, -3, 'key cc has val -3');

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/requires value/, 'Failed to parse because -F missing required value');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-F=1);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($foo, '1', '-F set with 1');

##LONG

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Str',
    }
};

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO bar);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bar', '--FoO set with bar');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=baz);
$op->set_args(\@args);
$op->getopts();
is($foo, 'baz', '--FoO set with baz');

$foo = 'cats';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoObag);
$op->set_args(\@args);
$op->getopts();
@va = $op->get_valid_args();
@ia = $op->get_invalid_args();
@ea = $op->get_extra_args();
is($foo, 'cats', '--FoO left unset with cats');
is($#va, -1, 'va contains 0 values');
is($#ia, 0, 'ia contains 1 values');
is($#ea, -1, 'ea contains 0 values');

$foo = 'bats';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO-boo);
$op->set_args(\@args);
$op->getopts();
is($foo, 'bats', '--FoO left unset with bats');

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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aaa --bar bbb);
$op->set_args(\@args);
$op->getopts();
is($foo, 'aaa', '--FoO set with aaa');
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO box);
$op->set_args(\@args);
$op->getopts();
is($foo, 'box', '--FoO set with box');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/requires value/, 'Failed to parse because --FoO missing required value');

$foo = '';
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/required switch/, 'Failed to parse because missing required argument --FoO');

#checking int values
$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Int',
    }
};

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--FoO set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--FoO set with 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=2e2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 2.2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=2.2);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO);
$op->set_args(\@args);
$op->getopts();
ok($foo, '--FoO set to true');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 0);
$op->set_args(\@args);
$op->getopts();
ok($foo, '--FoO set to true');
@extra_args = $op->get_extra_args();
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '--FoO set to 0');

$foo = 1;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=0);
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '---FoO set to 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--FoO set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=1);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--FoO set to 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '--FoO set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=2.2);
$op->set_args(\@args);
$op->getopts();
is($foo, 2.2, '--FoO set to 2.2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aaa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=aaa);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO);
$op->set_args(\@args);
$op->getopts();
is($foo, 1, '--FoO should be 1');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-f -f);
$op->set_args(\@args);
$op->getopts();
is($foo, 2, '--FoO should be 2');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($foo, 0, '--FoO should be 0');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO --FoO --FoO --FoO --FoO);
$op->set_args(\@args);
$op->getopts();
is($foo, 5, '--FoO should be 5');

#try out arrays
$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Str]',
    }
};

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw();
$op->set_args(\@args);
$op->getopts();
is($#arr, -1, '--FoO set with no values');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa --FoO bb --FoO cc);
$op->set_args(\@args);
$op->getopts();
is($#arr, 2, '--FoO set with 3 values');
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1 --FoO 2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--FoO set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1 --FoO bar);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1 --FoO 2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--FoO set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2, 'arr has 1st elem 2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1 --FoO 2.2);
$op->set_args(\@args);
$op->getopts();
is($#arr, 1, '--FoO set with 2 values');
is($arr[0], 1, 'arr has 0th elem 1');
is($arr[1], 2.2, 'arr has 1st elem 2.2');

@arr = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO 1 --FoO bar);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=foo --FoO bb=bar --FoO cc=baz);
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

%has = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO=aa=foo --FoO=bb=bar --FoO=cc=baz);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1 --FoO bb=2 --FoO cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1 --FoO bb=bar --FoO cc=3);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

%has = ();
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1 --FoO bb=2.2 --FoO cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1 --FoO bb=2 --FoO cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1.1 --FoO bb=2.2 --FoO cc=3.3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FoO aa=1 --FoO bb=bar --FoO cc=3);
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
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FOO);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails to parse');
like($op->get_error(), qr/requires value/, 'Failed to parse because -F missing required value');

$foo = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(--FOO=1);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($foo, '1', '--FoO set with 1');

##BUNDLED

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Bool',
    },
    'bar|b' => {
        'var' => \$bar,
        'type' => 'Bool',
    },
    'cab|c' => {
        'var' => \$cab,
        'type' => 'Str',
    }
};

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-Fb -C=foo);
$op->set_args(\@args);
$op->getopts();
@va = $op->get_valid_args();
@ia = $op->get_invalid_args();
@ea = $op->get_extra_args();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');
is($#va, 2, 'va contains 3 values');
is($#ia, -1, 'ia contains 0 values');
is($#ea, -1, 'ea contains 0 values');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-fC=foo -B);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-fCfoo -b);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-FC foo -b);
$op->set_args(\@args);
$op->getopts();
ok($foo, '-f set to true');
ok($bar, '-b set to true');
is($cab, 'foo', '-c set to foo');

$cfg = {
    'non_option_mode' => 'SWITCH_RET_0',
    'case_mode' => 'INSENSITIVE',
};

$foo = 0;
$bar = 0;
$cab = 0;
$op = Getopt::Flex->new({spec => $sp, config => $cfg});
@args = qw(-Fc foo -b);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
