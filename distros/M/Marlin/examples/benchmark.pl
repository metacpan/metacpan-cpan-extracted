use v5.20.0;
use strict;
use warnings;
no warnings 'once';

use Benchmark 'cmpthese';
use FindBin '$Bin';

use constant ITERATIONS => $ENV{PERL_MARLIN_BENCH_ITERATIONS} // -3;
use constant NONOO      => $ENV{PERL_MARLIN_BENCH_NONOO}      //  0;

use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib '/home/tai/src/p5/p5-lexical-accessor/lib';

eval 'require Local::Example::Core;   1' or warn $@;
eval 'require Local::Example::Plain;  1' or warn $@;
eval 'require Local::Example::Marlin; 1' or warn $@;
eval 'require Local::Example::Moo;    1' or warn $@;
eval 'require Local::Example::Moose;  1' or warn $@;
eval 'require Local::Example::Mouse;  1' or warn $@;
eval 'require Local::Example::Tiny;   1' or warn $@;

my (
	%simple_constructors,
	%simple_accessors,
	%simple_combined,
	%constructors,
	%accessors,
	%delegations,
	%combined,
);

for my $i ( @Local::Example::ALL ) {
	
	( my $implementation_name = $i ) =~ s/^Local::Example:://;

	my $person_class  = $i . "::Person";
	my $dev_class     = $i . "::Employee::Developer";
	my $simple_class  = $i . "::Simple";

	$simple_constructors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $o = $simple_class->new( foo => 1, bar => 2 );
		}
	};
	
	$constructors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $o1 = $person_class->new( name => 'Alice', age => $n );
			my $o2 = $dev_class->new( name => 'Carol', employee_id => $n );
		}
	};

	my $dev_object = $dev_class->new( name => 'Bob', employee_id => 1 );
	my $simple_object = $simple_class->new( foo => 1, bar => 2 );
	
	$simple_accessors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			die $implementation_name unless $simple_object->foo == 1;
			die $implementation_name unless $simple_object->bar == 2;
		}
	};
	
	$accessors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $name = $dev_object->name;
			my $id   = $dev_object->employee_id;
			my $lang = $dev_object->get_languages;
		}
	};
	
	$delegations{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			$dev_object->add_language( $_ )
				for qw/ Perl C C++ Ruby Python Haskell SQL Go Rust Java /;
			my @all = $dev_object->all_languages;
			@all == 10 or die $implementation_name;
			$dev_object->clear_languages;
		}
	};
	
	$simple_combined{$implementation_name} = sub {
		for my $n ( 1 .. 25 ) {
			my $o = $simple_class->new( foo => 1, bar => 2 );
			for my $n ( 1 .. 10 ) {
				die $implementation_name unless $o->foo == 1;
				die $implementation_name unless $o->bar == 2;
			}
		}
	};
	
	$combined{$implementation_name} = sub {
		for my $n ( 1 .. 25 ) {
			my $person = $person_class->new( name => 'Alice', age => $n );
			my $dev    = $dev_class->new( name => 'Carol', employee_id => $n, age => 42 );
			for my $n ( 1 .. 4 ) {
				$dev->age == 42 or die $implementation_name;
				$dev->name eq 'Carol' or die $implementation_name;
				$dev->add_language( $_ )
					for qw/ Perl C C++ Ruby Python Haskell SQL Go Rust Java /;
				my @all = $dev->all_languages;
				@all == 10 or die $implementation_name;
				$dev->clear_languages;
			}
		}
	};
}

if ( NONOO ) {
	my $implementation_name = 'NonOO';

	$simple_constructors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $href = { foo => 1, bar => 2 };
		}
	};
	
	$constructors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $href1 = { name => 'Alice', age => $n };
			my $href2 = { name => 'Carol', employee_id => $n };
		}
	};

	my $dev_href = { name => 'Bob', employee_id => 1 };
	my $simple_href = { foo => 1, bar => 2 };
	
	$simple_accessors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			die $implementation_name unless $simple_href->{foo} == 1;
			die $implementation_name unless $simple_href->{bar} == 2;
		}
	};
	
	$accessors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $name = $dev_href->{name};
			my $id   = $dev_href->{employee_id};
			my $lang = $dev_href->{languages};
		}
	};
	
	$delegations{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			push @{ $dev_href->{languages} //= [] }, $_
				for qw/ Perl C C++ Ruby Python Haskell SQL Go Rust Java /;
			my @all = @{ $dev_href->{languages} };
			@all == 10 or die $implementation_name;
			delete $dev_href->{languages};
		}
	};
	
	$simple_combined{$implementation_name} = sub {
		for my $n ( 1 .. 25 ) {
			my $href = { foo => 1, bar => 2 };
			for my $n ( 1 .. 10 ) {
				die $implementation_name unless $href->{foo} == 1;
				die $implementation_name unless $href->{bar} == 2;
			}
		}
	};
	
	$combined{$implementation_name} = sub {
		for my $n ( 1 .. 25 ) {
			my $person_hr = { name => 'Alice', age => $n };
			my $dev_hr    = { name => 'Carol', employee_id => $n, age => 42 };
			for my $n ( 1 .. 4 ) {
				$dev_hr->{age} == 42 or die $implementation_name;
				$dev_hr->{name} eq 'Carol' or die $implementation_name;
				push @{ $dev_hr->{languages} //= [] }, $_
					for qw/ Perl C C++ Ruby Python Haskell SQL Go Rust Java /;
				my @all = @{ $dev_hr->{languages} };
				@all == 10 or die $implementation_name;
				delete $dev_hr->{languages};
			}
		}
	};
}

say "[[ SIMPLE CONSTRUCTORS ]]";
cmpthese( ITERATIONS, \%simple_constructors );
say "";

say "[[ SIMPLE ACCESSORS ]]";
cmpthese( ITERATIONS, \%simple_accessors );
say "";

say "[[ SIMPLE COMBINED ]]";
cmpthese( ITERATIONS, \%simple_combined );
say "";

say "[[ COMPLEX CONSTRUCTORS ]]";
cmpthese( ITERATIONS, \%constructors );
say "";

say "[[ COMPLEX ACCESSORS ]]";
cmpthese( ITERATIONS, \%accessors );
say "";

say "[[ COMPLEX DELEGATIONS ]]";
cmpthese( ITERATIONS, \%delegations );
say "";

say "[[ COMPLEX COMBINED ]]";
cmpthese( ITERATIONS, \%combined );
say "";

__END__
[[ SIMPLE CONSTRUCTORS ]]
          Rate   Tiny  Moose    Moo  Plain  Mouse Marlin   Core
Tiny    3071/s     --   -44%   -63%   -73%   -75%   -80%   -86%
Moose   5444/s    77%     --   -35%   -53%   -56%   -65%   -75%
Moo     8354/s   172%    53%     --   -28%   -32%   -46%   -61%
Plain  11541/s   276%   112%    38%     --    -6%   -26%   -46%
Mouse  12300/s   301%   126%    47%     7%     --   -21%   -43%
Marlin 15513/s   405%   185%    86%    34%    26%     --   -28%
Core   21452/s   598%   294%   157%    86%    74%    38%     --

[[ SIMPLE ACCESSORS ]]
          Rate   Core  Moose   Tiny  Plain  Mouse Marlin    Moo
Core   29332/s     --    -9%   -11%   -26%   -48%   -60%   -60%
Moose  32172/s    10%     --    -2%   -19%   -43%   -56%   -56%
Tiny   32809/s    12%     2%     --   -17%   -42%   -55%   -55%
Plain  39565/s    35%    23%    21%     --   -30%   -46%   -46%
Mouse  56758/s    93%    76%    73%    43%     --   -22%   -22%
Marlin 72614/s   148%   126%   121%    84%    28%     --    -0%
Moo    72878/s   148%   127%   122%    84%    28%     0%     --

[[ SIMPLE COMBINED ]]
          Rate   Tiny  Moose   Core  Plain    Moo  Mouse Marlin
Tiny    6492/s     --   -24%   -35%   -47%   -53%   -60%   -64%
Moose   8540/s    32%     --   -15%   -30%   -38%   -47%   -53%
Core   10052/s    55%    18%     --   -18%   -28%   -37%   -45%
Plain  12222/s    88%    43%    22%     --   -12%   -24%   -33%
Moo    13869/s   114%    62%    38%    13%     --   -14%   -24%
Mouse  16033/s   147%    88%    59%    31%    16%     --   -12%
Marlin 18185/s   180%   113%    81%    49%    31%    13%     --

[[ COMPLEX CONSTRUCTORS ]]
         Rate  Plain   Tiny    Moo  Moose   Core Marlin  Mouse
Plain  1350/s     --    -1%   -46%   -55%   -73%   -73%   -78%
Tiny   1369/s     1%     --   -45%   -54%   -72%   -72%   -78%
Moo    2495/s    85%    82%     --   -17%   -50%   -50%   -60%
Moose  3001/s   122%   119%    20%     --   -40%   -40%   -52%
Core   4974/s   268%   263%    99%    66%     --    -0%   -20%
Marlin 4979/s   269%   264%   100%    66%     0%     --   -20%
Mouse  6218/s   360%   354%   149%   107%    25%    25%     --

[[ COMPLEX ACCESSORS ]]
          Rate   Core   Tiny  Moose  Plain    Moo Marlin  Mouse
Core   19907/s     --    -8%    -9%   -10%   -43%   -54%   -57%
Tiny   21561/s     8%     --    -2%    -3%   -38%   -50%   -53%
Moose  21913/s    10%     2%     --    -1%   -37%   -50%   -53%
Plain  22119/s    11%     3%     1%     --   -36%   -49%   -52%
Moo    34662/s    74%    61%    58%    57%     --   -20%   -25%
Marlin 43555/s   119%   102%    99%    97%    26%     --    -6%
Mouse  46291/s   133%   115%   111%   109%    34%     6%     --

[[ COMPLEX DELEGATIONS ]]
         Rate   Tiny  Mouse   Core  Plain  Moose    Moo Marlin
Tiny    822/s     --   -34%   -56%   -57%   -59%   -62%   -63%
Mouse  1247/s    52%     --   -33%   -35%   -38%   -42%   -43%
Core   1855/s   126%    49%     --    -3%    -8%   -14%   -15%
Plain  1913/s   133%    53%     3%     --    -5%   -11%   -13%
Moose  2021/s   146%    62%     9%     6%     --    -6%    -8%
Moo    2149/s   162%    72%    16%    12%     6%     --    -2%
Marlin 2193/s   167%    76%    18%    15%     9%     2%     --

[[ COMPLEX COMBINED ]]
         Rate   Tiny  Mouse  Plain  Moose   Core    Moo Marlin
Tiny    677/s     --   -41%   -48%   -57%   -57%   -59%   -64%
Mouse  1151/s    70%     --   -11%   -27%   -27%   -31%   -39%
Plain  1292/s    91%    12%     --   -18%   -18%   -22%   -31%
Moose  1575/s   133%    37%    22%     --    -0%    -5%   -16%
Core   1577/s   133%    37%    22%     0%     --    -5%   -16%
Moo    1662/s   146%    44%    29%     6%     5%     --   -12%
Marlin 1879/s   178%    63%    45%    19%    19%    13%     --
