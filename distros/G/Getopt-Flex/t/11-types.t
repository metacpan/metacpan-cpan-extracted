use strict;
use warnings;
use Test::More tests => 15;
use Test::Exception;
use Moose;
use Moose::Util::TypeConstraints;
use Getopt::Flex;

my $foo;
my @arr;
my %has;

my $sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'MyRational',
    }
};

my $op;

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with invalid type';

subtype 'MyRational'
            => as 'Num'
            => where { $_ > 0 };
            
lives_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Should not die';

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Natural',
    }
};

subtype 'Natural'
            => as 'Int'
            => where { $_ > 0 };

lives_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Should not die';

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'ArrayRef[Natural]',
    }
};

lives_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Should not die';

$sp = {
    'foo|f' => {
        'var' => \%has,
        'type' => 'HashRef[Natural]',
    }
};

lives_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Should not die';

$sp = {
    'foo|f' => {
        'var' => \$foo,
        'type' => 'Natural',
    }
};

lives_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Should not die';
my @args = qw(-f 10);
$op->set_args(\@args);
ok($op->getopts(), 'Parses ok');
is($foo, 10, '-f set with 10');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f 10.1);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f aa);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

$op = Getopt::Flex->new({spec => $sp});
@args = qw(-f -2);
$op->set_args(\@args);
ok(!$op->getopts(), 'Fails in parsing');
like($op->get_error(), qr/type constraint/, 'Failed to parse because value fails type constraint');

subtype 'MyArr'
            => as 'ArrayRef[Int]',

$sp = {
    'foo|f' => {
        'var' => \@arr,
        'type' => 'MyArr',
    }
};

dies_ok { $op = Getopt::Flex->new({spec => $sp}) } 'Dies with type not simple';
