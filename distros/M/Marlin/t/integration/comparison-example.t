=pod

=encoding utf-8

=head1 PURPOSE

Tests the example shown in L<Marlin::Manual::Comparison>, with minor
adaptations to make it run on Perl v5.8.8.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

use lib "t/lib";

use Local::Example::Marlin;
my $i = 'Local::Example::Marlin';

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

done_testing;
