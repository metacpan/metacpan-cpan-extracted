=pod

=encoding utf-8

=head1 PURPOSE

Tests Marlin::Struct works.

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2025 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

use Test2::V0;
use Data::Dumper;

use Marlin::Struct
	Person    => [ 'name!', 'age' ],
	Employee  => [ 'employee_id!', -base => \'Person' ];

my $A = Employee->new( name => 'Alice', employee_id => 1 );
ok( $A->name, 'Alice' );
ok( $A->employee_id, 1 );
ok is_Employee( $A );
ok is_Person( $A );

my $B = Employee[ 'Bob', 2 ];
ok( $B->name, 'Bob' );
ok( $B->employee_id, 2 );
ok is_Employee( $B );
ok is_Person( $B );

is( to_Person( { name => 'Carol' } ), bless( { name => 'Carol' }, Person->class ) );
is( to_Person( [ 'Dave' ] ), bless( { name => 'Dave' }, Person->class ) );
is( to_Person( [ 'Eve', age => 33 ] ), bless( { name => 'Eve', age => 33 }, Person->class ) );

tie( my $person, Person );
$person = { name => 'Fred' };
is( $person, bless( { name => 'Fred' }, Person->class ) );
$person = [ 'George' ];
is( $person, bless( { name => 'George' }, Person->class ) );
$person = Employee[ 'Harriet', 8 ];
is( $person, bless( { name => 'Harriet', employee_id => 8 }, Employee->class ) );

like( dies { $person = 1 }, qr/did not pass type constraint "Person"/ );

my $i = Employee[ 'Ingrid', age => 40, employee_id => 9 ];
is( "$i", q{Employee["Ingrid", 9, age => 40]} );
is( [@$i], ["Ingrid", 9, age => 40] );

done_testing;
