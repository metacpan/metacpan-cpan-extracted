use strict;
use warnings;
use Test::More;
use Getopt::Long::Modern;

# regular options
{
	local @ARGV = qw(-f --bar baz -Z 1 --baz 2 abc);
	GetOptions(
		'f|foo'   => \my $foo,
		'b|bar=s' => \my $bar,
		'Z|baz=s' => \my @baz,
	);
	is_deeply \@ARGV, ['abc'], 'argument left';
	ok $foo, 'option is set';
	is $bar, 'baz', 'option is set';
	is_deeply \@baz, [1,2], 'option is set';
}

# no_ignore_case, permute
{
	local @ARGV = qw(--Foo abc --bar baz);
	local $SIG{__WARN__} = sub {};
	GetOptions(
		'foo'   => \my $foo,
		'bar=s' => \my $bar,
	);
	is_deeply \@ARGV, ['abc'], 'argument left';
	ok !$foo, 'option is not set';
	is $bar, 'baz', 'option is set';
}

# bundling
{
	local @ARGV = qw(-fb baz abc);
	GetOptions(
		'f|foo'   => \my $foo,
		'b|bar=s' => \my $bar,
	);
	is_deeply \@ARGV, ['abc'], 'argument left';
	ok $foo, 'option is set';
	is $bar, 'baz', 'option is set';
}

# gnu_compat no_getopt_compat
{
	local @ARGV = qw(+f --bar= abc);
	GetOptions(
		'f|foo'   => \my $foo,
		'b|bar=s' => \my $bar,
	);
	is_deeply \@ARGV, ['+f','abc'], 'argument left';
	ok !$foo, 'option is not set';
	is $bar, '', 'option is set';
}

# extra options
Getopt::Long::Modern->import('pass_through');
{
	local @ARGV = qw(-f --bar=baz --baz abc);
	GetOptions(
		'f|foo'   => \my $foo,
		'b|bar=s' => \my $bar,
	);
	is_deeply \@ARGV, ['--baz','abc'], 'arguments left';
	ok $foo, 'option is set';
	is $bar, 'baz', 'option is set';
}

done_testing;
