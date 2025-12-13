use v5.20.0;
use Test2::V0;
no warnings 'once';

use FindBin '$Bin';

use lib "$Bin/lib";
use lib "$Bin/../lib";
use lib '/home/tai/src/p5/p5-lexical-accessor/lib';

eval 'require Local::Example::Core;   1' or warn $@;
eval 'require Local::Example::Plain;  1' or warn $@;
eval 'require Local::Example::Marlin; 1' or warn $@;
eval 'require Local::Example::Moo;    1' or warn $@;
eval 'require Local::Example::Moose;  1' or warn $@;
eval 'require Local::Example::Tiny;   1' or warn $@;

for my $i ( @Local::Example::ALL ) {
	
	subtest $i => sub {
		
		subtest 'NamedThing' => sub {
			my $class = "$i\::NamedThing";
			
			my $obj = $class->new( name => 'Fido' );
			is( $obj->name, 'Fido', 'reader "name" works' );
			
			ok( dies { $class->new }, 'constructor dies when missing required parameters' );
			ok( dies { $class->new( name => [] ) }, 'constructor dies when given wrong typed parameters' );
			ok( dies { $class->new( name => 'Fido', other => 1 ) }, 'constructor dies when given extra parameters' );
		};
		
		subtest 'Person' => sub {
			my $class = "$i\::Person";
			
			my $obj = $class->new( name => 'Bob', age => 21 );
			is( $obj->name, 'Bob', 'reader "name" works' );
			is( $obj->age, 21, 'reader "age" works' );
			ok( $obj->has_age, 'predicate "has_age" works' );
			
			ok( $obj->DOES( "$i\::DoesIntro" ), 'composed role correctly' );
			is( $obj->introduction, "Hi, my name is Bob!", 'method "introduction" works' );
			
			ok( dies { $class->new }, 'constructor dies when missing required parameters' );
			ok( dies { $class->new( name => [] ) }, 'constructor dies when given wrong typed parameters' );
			ok( dies { $class->new( name => 'Bob', other => 1 ) }, 'constructor dies when given extra parameters' );
		};
		
		subtest 'Employee' => sub {
			my $class = "$i\::Employee";
			
			my $obj = $class->new( name => 'Bob', age => 21, employee_id => 1 );
			is( $obj->name, 'Bob', 'reader "name" works' );
			is( $obj->age, 21, 'reader "age" works' );
			ok( $obj->has_age, 'predicate "has_age" works' );
			is( $obj->employee_id, 1, 'reader "employee_id" works' );
			
			ok( $obj->DOES( "$i\::DoesIntro" ), 'composed role correctly' );
			is( $obj->introduction, "Hi, my name is Bob!", 'method "introduction" works' );
			
			ok( dies { $class->new( employee_id => 1 ) }, 'constructor dies when missing required parameters' );
			ok( dies { $class->new( name => [], employee_id => 1 ) }, 'constructor dies when given wrong typed parameters' );
			ok( dies { $class->new( name => 'Bob', employee_id => 1, other => 1 ) }, 'constructor dies when given extra parameters' );
		};
		
		subtest 'Employee::Developer' => sub {
			my $class = "$i\::Employee::Developer";
			
			my $obj = $class->new( name => 'Bob', age => 21, employee_id => 1 );
			is( $obj->name, 'Bob', 'reader "name" works' );
			is( $obj->age, 21, 'reader "age" works' );
			ok( $obj->has_age, 'predicate "has_age" works' );
			is( $obj->employee_id, 1, 'reader "employee_id" works' );
			is( $obj->get_languages, [], 'reader "get_languages" works' );
			
			ok( $obj->DOES( "$i\::DoesIntro" ), 'composed role correctly' );
			is( $obj->introduction, "Hi, my name is Bob!", 'method "introduction" works' );
			
			$obj->add_language($_) for qw/ C Perl /;
			is( $obj->get_languages, [ qw/ C Perl / ], 'delegated method "add_language" worked' );
			is( [ $obj->all_languages ], [ qw/ C Perl / ], 'delegated method "all_languages" works' );
			
			ok( dies { $class->new( employee_id => 1 ) }, 'constructor dies when missing required parameters' );
			ok( dies { $class->new( name => [], employee_id => 1 ) }, 'constructor dies when given wrong typed parameters' );
			ok( dies { $class->new( name => 'Bob', employee_id => 1, other => 1 ) }, 'constructor dies when given extra parameters' );
			ok( dies { $class->new( name => 'Bob', employee_id => 1, _languages => 1 ) }, 'constructor dies when given non-parameter attributes' );
		};
	};
}

done_testing;
