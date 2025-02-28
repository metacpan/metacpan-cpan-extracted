#!/usr/bin/perl

use strict;
use warnings;
use Math::Symbolic qw(:all);
use Math::Symbolic::Custom::Equation;

use Test::Simple 'no_plan';

my $eq = Math::Symbolic::Custom::Equation->new('x', 'y');
ok( defined $eq, "Created equation x = y" );
ok( $eq->to_string() eq 'x = y', "to_string() returns 'x = y'" );
ok( $eq->holds({'x' => 8, 'y' => 8}), "holds() works for x=8, y=8" );
ok( !$eq->holds({'x' => 5, 'y' => 8}), "!holds() works for x=5, y=8" );
my @v = $eq->explicit_signature();
ok( (($v[0] eq 'x') && ($v[1] eq 'y')) || (($v[0] eq 'y') && ($v[1] eq 'x')), "explicit_signature() works" );

my %test_isolate = (
	'Test 01'	=>	{ 	equation => '(2*x - y)/1000 = 0', 
						to_isolate => [ {var => 'x', type => 1}, {var => 'y', type => 1} ], 
						holds => {'x' => 3, 'y' => 6}, 
						},
	'Test 02'	=>	{ 	equation => '((2*y - 9) - x) / 1000 = 0', 
						to_isolate => [ {var => 'x', type => 1}, {var => 'y', type => 1} ],
						holds => {'x' => 3, 'y' => 6},
						},
	'Test 03'	=>	{ 	equation => 'x = 3*(y + 7)', 
						to_isolate => [ {var => 'x', type => 1}, {var => 'y', type => 1} ],
						holds => {'x' => 27, 'y' => 2},
						},
	'Test 04'	=>	{ 	equation => 'y = 2*x + 4', 
						to_isolate => [ {var => 'x', type => 1}, {var => 'y', type => 1} ],
						holds => {'x' => 3, 'y' => 10},
						},
	'Test 05'	=>	{ 	equation => '(2*x + x*y)/5 = 2', 
						to_isolate => [ {var => 'x', type => 1}, {var => 'y', type => 1} ],
						holds => {'x' => 2, 'y' => 3},
						},
	'Test 06'	=>	{ 	equation => 'v^2 = u^2 + 2*a*s', 
						to_isolate => [ {var => 's', type => 1}, {var => 'u', type => 2} ],
						holds => {'v' => 9.89949493661, 'u' => 0, 'a' => 9.8, 's' => 5},
						},
	'Test 07'	=>	{ 	equation => 's = u*t + (1/2) * a * t^2', 
						to_isolate => [ {var => 's', type => 1}, {var => 'a', type => 1}, {var => 't', type => 3} ],
						holds => { 's' => 127.5, 'u' => 1, 'a' => 9.8, 't' => 5},
						},
	'Test 08'	=>	{	equation => 'y - 4 = 0',
						to_isolate => [ {var => 'y', type => 1} ],
						holds => {'y' => 4},
						},
	'Test 09'	=>	{	equation => '(a/3) = (2 - 7*x)/(x-5)',
						to_isolate => [ {var => 'x', type => 1} ],
						holds => {'a' => -120, 'x' => 6},
						},
	'Test 10'	=>	{	equation => 'y = (2*x*z) / (x - 5)',
						to_isolate => [ {var => 'x', type => 1} ],
						holds => {'x' => 3, 'y' => -6, 'z' => 2}
						},
    'Test 11'   =>  {   equation => 'a - n = (a + 2) / n',
                        to_isolate => [ {var => 'a', type => 1} ],
                        holds => { 'a' => 6, 'n' => 4 },
                        },
    'Test 12'   =>  {   equation => 'sqrt((a+x)/(a-x)) = 2',
                        to_isolate => [ {var => 'a', type => 1} ],
                        holds => { 'a' => 5, 'x' => 3 },
                        },
    'Test 13'   =>  {   equation => 'A = (1/2)*(a+b)*h',
                        to_isolate => [ {var => 'b', type => 1}, {var => 'h', type => 1} ],
                        holds => { 'A' => 10, 'a' => 6, 'b' => 4, 'h' => 2 },
                        },
    'Test 14'   =>  {   equation => 'a^2 * x^2 - b^2 = b^2 * c^2',
                        to_isolate => [ {var => 'x', type => 2} ],
                        holds => { 'a' => 2, 'b' => 3, 'c' => 4, 'x' => 6.18465843843 }, 
                        },
);

foreach my $test (sort keys %test_isolate) {
		
	my $eq_str = $test_isolate{$test}{equation};
	my @subjects = @{$test_isolate{$test}{to_isolate}};
    my $vals; 
                
    if ( exists $test_isolate{$test}{holds} ) {               
        $vals = $test_isolate{$test}{holds};	
    }

	my $eq = Math::Symbolic::Custom::Equation->new($eq_str);
	ok( defined($eq) && (ref($eq) =~ /Math::Symbolic/), "$test: Constructed equation [" . $eq->to_string() . "]" );
	
    if ( defined $vals ) {
	    ok( $eq->holds($vals, 1e-9), "$test: Equation holds for test values [" . $eq->to_string() . "]" );
    }	

	foreach my $hr (@subjects) {
		
        my $desired = $hr->{var};
        my $t_type = $hr->{type};

		my ($eq2, $type) = $eq->isolate($desired);
		ok( defined($eq2) && defined($type), "$test/$desired: isolate() returned result for '$desired'" );
		
		if ( defined $eq2 ) {

			ok( defined($eq2) && (ref($eq2) =~ /Math::Symbolic/), "$test/$desired: Constructed equation [" . $eq2->to_string() . "]" );
            ok( $type == $t_type, "$test/$desired: return equation type is correct" );

            if ( defined $vals ) {
    			ok( $eq2->holds($vals, 1e-9), "$test/$desired: Re-arranged equation holds for test values [" . $eq2->to_string() . "]" );
            }
		}
	}
}

