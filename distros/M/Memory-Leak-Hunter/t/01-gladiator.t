use strict;
use warnings;

use File::Temp qw(tempdir);
use Test::More;
use Test::Deep;

sub range {
	my ($x, $y) = @_;

	return code(sub {
		my $val = shift;
		if ($x <= $val and $val <= $y) {
			return 1;
		} else {
			return (0, "Expected $x <= VALUE <= $y\nReceived $val");
		}
	});
}


my $code1 = <<'CODE';
sub f {
	my $x = {
		name => 'Foo',
	};
	my $y = {
		name => 'Bar',
	};
	$x->{partner} = $y;
	$y->{partner} = $x;
}

CODE

my $code2 = $code1 . 'f();';
my $code3 = $code1 . 'f() for 1..100;';

# Different version of  Scalar::Util will give different numbers.

#my $code11 = <<'CODE';
#use Scalar::Util qw(weaken);
#sub f {
#	my $x = {
#		name => 'Foo',
#	};
#	my $y = {
#		name => 'Bar',
#	};
#	$x->{partner} = $y;
#	$y->{partner} = $x;
#	weaken $y->{partner};
#}
#
#CODE
#
#my $code12 = $code11 . 'f();';
#my $code13 = $code11 . 'f() for 1..100;';

my @cases = (
	{
		code   => '',
		rebase => {},
		name   => 'base',
	},
	{
		code   => 'my $x;',
		rebase => { SCALAR => 2 },
		name   => 'one scalar',
	},
	{
		code   => '{ my $x; }',
		rebase => { SCALAR => 2 },
		name   => 'one scalar in block',
	},
	{
		code   => 'my $x = "abcd";',
		rebase => { SCALAR => 3 },
		name   => 'one scalar with scalar value',
	},
	{
		code   => '{my $x = "abcd";}',
		rebase => { SCALAR => 3 },
		name   => 'one scalar with scalar value in scope',
	},
	{
		code   => 'my $x = 1; $x++;',
		rebase => { SCALAR => 4 },
		name   => 'one scalar with scalar value',
	},
	{
		code   => 'my @x;',
		rebase => { SCALAR => 1, ARRAY => 1 },
		name   => 'one array',
	},
	{
		code   => 'my $x = [];',
		rebase => { SCALAR => 1, ARRAY => 1, REF => 1, 'REF-ARRAY' => 1 },
		name   => 'one array ref',
	},
	{
		code   => 'my %x;',
		rebase => { SCALAR => 1, HASH => 1 },
		name   => 'one hash',
	},
	{
		code   => 'my $x = {};',
		rebase => { SCALAR => 1, HASH => 1, 'REF-HASH' => 1, 'REF' => 1 },
		name   => 'one hash ref',
	},
	{
		code   => $code1,
		rebase => { SCALAR => [10, 12], ARRAY => 2, CODE => 1, GLOB => 1 },
		name   => 'function',
	},
	{
		code   => $code2,
		rebase => { SCALAR => [13, 15], ARRAY => 2, 'REF-HASH' => 2, REF => 2, HASH => 2,
			CODE => 1, GLOB => 1 },
		name   => 'function + call once',
	},
	{
		code   => $code3,
		rebase => { SCALAR => [215, 217], ARRAY => 2, 'REF-HASH' => 200, REF => 200, HASH => 200, 
			CODE => 1, GLOB => 1 },
		name   => 'function + call 100 times',
	},
	#{
	#	code   => $code11,
	#	rebase => { REGEXP => 2, REF => 1, 'REF-HASH' => 1, HASH => 7,
	#		SCALAR => 122, ARRAY => 25, CODE => 31, GLOB => 53 },
	#	name   => 'function with weaken',
	#},
	#{
	#	code   => $code12,
	#	rebase => { REGEXP => 2, REF => 1, 'REF-HASH' => 1, HASH => 7,
	#		SCALAR => 123, ARRAY => 25, CODE => 31, GLOB => 53 },
	#	name   => 'function with weaken + call once',
	#},
	#{
	#	code   => $code13,
	#	rebase => { REGEXP => 2, REF => 1, 'REF-HASH' => 1, HASH => 7,
	#		SCALAR => 127, ARRAY => 25, CODE => 31, GLOB => 53 },
	#	name   => 'function with weaken + call 100-times',
	#},
);

plan tests => scalar @cases;

my $dir = tempdir( CLEANUP => 1 );
my $file = "$dir/code";

my $base = run_gladiator('');
#diag explain $base;

foreach my $c (@cases) {
	#diag explain run_gladiator($c->{code});
	cmp_deeply run_gladiator($c->{code}), rebase($c->{rebase}), $c->{name};
}


sub run_gladiator {
	my ($code) = @_;

	open my $fh, '>', $file or die;
	print $fh "$code\n";
	print $fh q{use Devel::Gladiator qw(arena_ref_counts);}  . "\n";
	print $fh q{print Devel::Gladiator::arena_table;} . "\n";
	close $fh;

	my @out = `$^X $file`;
	chomp @out;
	shift @out;
	my %out =  map { /(\d+)\s+(\S+)/; $2, $1 } @out;
	return \%out;
}

sub rebase {
	my ($add) = @_;
	my %data = %$base;
	for my $f (keys %$add) {
		if (ref $add->{$f}) {
			$data{$f} = range($data{$f}+$add->{$f}[0], $data{$f}+$add->{$f}[1]);
		} else {
			$data{$f} += $add->{$f};
		}
	}
	return \%data;
}

