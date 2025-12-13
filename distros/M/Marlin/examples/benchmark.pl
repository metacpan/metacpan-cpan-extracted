use v5.20.0;
use strict;
use warnings;
no warnings 'once';

use Benchmark 'cmpthese';
use FindBin '$Bin';

use constant ITERATIONS => -3;

use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib '/home/tai/src/p5/p5-lexical-accessor/lib';

eval 'require Local::Example::Core;   1' or warn $@;
eval 'require Local::Example::Plain;  1' or warn $@;
eval 'require Local::Example::Marlin; 1' or warn $@;
eval 'require Local::Example::Moo;    1' or warn $@;
eval 'require Local::Example::Moose;  1' or warn $@;
eval 'require Local::Example::Tiny;   1' or warn $@;

my ( %constructors, %accessors, %delegations, %combined );
for my $i ( @Local::Example::ALL ) {
	
	( my $implementation_name = $i ) =~ s/^Local::Example:://;

	my $person_class  = $i . "::Person";
	my $dev_class     = $i . "::Employee::Developer";
	
	$constructors{$implementation_name} = sub {
		for my $n ( 1 .. 100 ) {
			my $o1 = $person_class->new( name => 'Alice', age => $n );
			my $o2 = $dev_class->new( name => 'Carol', employee_id => $n );
		}
	};

	my $dev_object = $dev_class->new( name => 'Bob', employee_id => 1 );
	
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
			@all == 10 or die;
			$dev_object->clear_languages;
		}
	};
	
	$combined{$implementation_name} = sub {
		for my $n ( 1 .. 25 ) {
			my $person = $person_class->new( name => 'Alice', age => $n );
			my $dev    = $dev_class->new( name => 'Carol', employee_id => $n, age => 42 );
			for my $n ( 1 .. 4 ) {
				$dev->age == 42 or die;
				$dev->name eq 'Carol' or die;
				$dev->add_language( $_ )
					for qw/ Perl C C++ Ruby Python Haskell SQL Go Rust Java /;
				my @all = $dev->all_languages;
				@all == 10 or die;
				$dev->clear_languages;
			}
		}
	};
}

say "[[ CONSTRUCTORS ]]";
cmpthese( ITERATIONS, \%constructors );
say "";

say "[[ ACCESSORS ]]";
cmpthese( ITERATIONS, \%accessors );
say "";

say "[[ DELEGATIONS ]]";
cmpthese( ITERATIONS, \%delegations );
say "";

say "[[ COMBINED ]]";
cmpthese( ITERATIONS, \%combined );
say "";

__END__
[[ CONSTRUCTORS ]]
         Rate   Tiny  Plain    Moo  Moose Marlin   Core
Tiny   1317/s     --    -2%   -48%   -53%   -54%   -72%
Plain  1340/s     2%     --   -47%   -53%   -53%   -72%
Moo    2527/s    92%    89%     --   -11%   -12%   -47%
Moose  2828/s   115%   111%    12%     --    -2%   -40%
Marlin 2873/s   118%   114%    14%     2%     --   -39%
Core   4727/s   259%   253%    87%    67%    65%     --

[[ ACCESSORS ]]
          Rate   Tiny  Moose  Plain   Core    Moo Marlin
Tiny   17345/s     --    -1%    -3%    -7%   -36%   -45%
Moose  17602/s     1%     --    -2%    -6%   -35%   -44%
Plain  17893/s     3%     2%     --    -4%   -34%   -44%
Core   18732/s     8%     6%     5%     --   -31%   -41%
Moo    27226/s    57%    55%    52%    45%     --   -14%
Marlin 31688/s    83%    80%    77%    69%    16%     --

[[ DELEGATIONS ]]
         Rate   Tiny   Core  Plain  Moose    Moo Marlin
Tiny    675/s     --   -56%   -57%   -59%   -61%   -61%
Core   1518/s   125%     --    -4%    -8%   -13%   -13%
Plain  1581/s   134%     4%     --    -4%    -9%   -10%
Moose  1642/s   143%     8%     4%     --    -5%    -6%
Moo    1736/s   157%    14%    10%     6%     --    -1%
Marlin 1752/s   160%    15%    11%     7%     1%     --

[[ COMBINED ]]
         Rate   Tiny  Plain   Core  Moose    Moo Marlin
Tiny    545/s     --   -48%   -56%   -58%   -60%   -64%
Plain  1051/s    93%     --   -16%   -19%   -22%   -31%
Core   1249/s   129%    19%     --    -4%    -8%   -18%
Moose  1304/s   139%    24%     4%     --    -4%   -14%
Moo    1355/s   148%    29%     8%     4%     --   -11%
Marlin 1519/s   179%    45%    22%    17%    12%     --