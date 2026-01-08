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
eval 'require Local::Example::Mouse;  1' or warn $@;
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
         Rate  Plain   Tiny    Moo  Moose   Core Marlin  Mouse
Plain  1350/s     --    -1%   -46%   -55%   -73%   -73%   -78%
Tiny   1369/s     1%     --   -45%   -54%   -72%   -72%   -78%
Moo    2495/s    85%    82%     --   -17%   -50%   -50%   -60%
Moose  3001/s   122%   119%    20%     --   -40%   -40%   -52%
Core   4974/s   268%   263%    99%    66%     --    -0%   -20%
Marlin 4979/s   269%   264%   100%    66%     0%     --   -20%
Mouse  6218/s   360%   354%   149%   107%    25%    25%     --

[[ ACCESSORS ]]
          Rate   Core   Tiny  Moose  Plain    Moo Marlin  Mouse
Core   19907/s     --    -8%    -9%   -10%   -43%   -54%   -57%
Tiny   21561/s     8%     --    -2%    -3%   -38%   -50%   -53%
Moose  21913/s    10%     2%     --    -1%   -37%   -50%   -53%
Plain  22119/s    11%     3%     1%     --   -36%   -49%   -52%
Moo    34662/s    74%    61%    58%    57%     --   -20%   -25%
Marlin 43555/s   119%   102%    99%    97%    26%     --    -6%
Mouse  46291/s   133%   115%   111%   109%    34%     6%     --

[[ DELEGATIONS ]]
         Rate   Tiny  Mouse   Core  Plain  Moose    Moo Marlin
Tiny    822/s     --   -34%   -56%   -57%   -59%   -62%   -63%
Mouse  1247/s    52%     --   -33%   -35%   -38%   -42%   -43%
Core   1855/s   126%    49%     --    -3%    -8%   -14%   -15%
Plain  1913/s   133%    53%     3%     --    -5%   -11%   -13%
Moose  2021/s   146%    62%     9%     6%     --    -6%    -8%
Moo    2149/s   162%    72%    16%    12%     6%     --    -2%
Marlin 2193/s   167%    76%    18%    15%     9%     2%     --

[[ COMBINED ]]
         Rate   Tiny  Mouse  Plain  Moose   Core    Moo Marlin
Tiny    677/s     --   -41%   -48%   -57%   -57%   -59%   -64%
Mouse  1151/s    70%     --   -11%   -27%   -27%   -31%   -39%
Plain  1292/s    91%    12%     --   -18%   -18%   -22%   -31%
Moose  1575/s   133%    37%    22%     --    -0%    -5%   -16%
Core   1577/s   133%    37%    22%     0%     --    -5%   -16%
Moo    1662/s   146%    44%    29%     6%     5%     --   -12%
Marlin 1879/s   178%    63%    45%    19%    19%    13%     --
