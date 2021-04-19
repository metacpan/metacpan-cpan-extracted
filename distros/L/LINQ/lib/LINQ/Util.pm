use 5.006;
use strict;
use warnings;

package LINQ::Util;

our $AUTHORITY = 'cpan:TOBYINK';
our $VERSION   = '0.002';

use Exporter::Shiny qw( field fields check_fields );

sub fields {
	require LINQ::FieldSet::Selection;
	'LINQ::FieldSet::Selection'->new( @_ );
}

sub field {
	require LINQ::FieldSet::Single;
	'LINQ::FieldSet::Single'->new( @_ );
}

sub check_fields {
	require LINQ::FieldSet::Assertion;
	'LINQ::FieldSet::Assertion'->new( @_ );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

LINQ::Util - useful utilities to make working with LINQ collections easier

=head1 SYNOPSIS

  use feature qw( say );
  use LINQ qw( LINQ )';
  use LINQ::Util qw( fields  );
  
  my $collection = LINQ( [
    { name => 'Alice', age => 30, dept => 'IT'        },
    { name => 'Bob'  , age => 29, dept => 'IT'        },
    { name => 'Carol', age => 32, dept => 'Marketing' },
    { name => 'Dave',  age => 33, dept => 'Accounts'  },
  ] );
  
  my $name_and_dept = $collection->select( fields( 'name', 'dept' ) );
  
  for ( $name_and_dept->to_list ) {
    printf( "Hi, I'm %s from %s\n", $_->name, $_->dept );
  }

=head1 DESCRIPTION

LINQ::Util provides a collection of auxiliary functions to make working with
LINQ collections a little more intuitive and perhaps avoid passing a bunch of
C<< sub { ... } >> arguments to C<select> and C<where>.

=head1 FUNCTIONS

=over

=item C<< fields( SPEC ) >>

Creates a coderef (actually a blessed object overloading C<< &{} >>) which
takes a hashref or object as input, selects just the fields/keys given in the
SPEC, and returns an object with those fields.

A simple example would be:

  my $selector = fields( 'name' );
  my $object   = $selector->( { name => 'Bob', age => 29 } );

In this example, C<< $object >> would be a blessed object with a C<name>
method which returns "Bob".

Fields can be renamed:

  my $selector = fields( 'name', -as => 'moniker' );
  my $object   = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "Bob"

A coderef can be used as a field:

  my $selector = fields(
    sub { uc( $_->{'name'} ) }, -as => 'moniker',
  );
  my $object = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "BOB"

An asterisk field selects all the input fields:

  my $selector = fields(
    sub { uc( $_->{'name'} ) }, -as => 'moniker',
    '*',
  );
  my $object = $selector->( { name => 'Bob', age => 29 } );
  say $object->moniker;  # ==> "BOB"
  say $object->name;     # ==> "Bob"
  say $object->age;      # ==> 29

The aim of the C<fields> function is to allow the LINQ C<select> method to
function more like an SQL SELECT, where you give a list of fields you wish
to select.

=item C<< field( NAME ) >>

Conceptually similar to C<< fields() >> but for a single field. Returns the
field value instead of a hashref of field values.

  my $field = field('name');
  say $field->( $_ ) for (
    { name => 'Alice' },
    { name => 'Bob' },
  );

If called in list context with extra arguments after the field name, a list
will be returned, including the extra arguments unchanged.

  my $people = LINQ( [
    { name => 'Alice', age => 30, dept => 3 },
    { name => 'Bob'  , age => 29, dept => 3 },
    { name => 'Carol', age => 32, dept => 4 },
    { name => 'Dave',  age => 33, dept => 1 },
  ] );
  
  my $depts = LINQ( [
    { id => 3, name => 'IT'        },
    { id => 4, name => 'Marketing' },
    { id => 1, name => 'Accounts'  },
  ] );
  
  my $joiner = sub {
    my ( $person, $dept ) = @_;
    return {
      person_name => $person->{name},
      person_age  => $person->{age},
      dept_name   => $dept->{name},
    };
  };
  
  my $joined = $people->join( $depts, field 'dept', field 'id', $joiner );
  
  print Dumper( $joined->to_array );

=item C<< check_fields( SPEC ) >>

If C<< fields() >> can be compared to SQL SELECT, then C<< check_fields() >>
can be compared to SQL WHERE. Like C<< fields() >> it assumes your data is
hashrefs or blessed objects with attributes.

  # Select people called Bob.
  $people
    ->where( check_fields( 'name', -is => 'Bob' ) )
    ->select( fields( 'name', 'age', 'dept' ) );

Different operators can be used. Whether performing string or numeric
comparison, ">", "<", ">=", "<=", "==", and "!=" are used. (And the C<< -is >>
parameter is used to provide the right hand side of the comparison, even
for comparisons like "!=".)

  $people
    ->where( check_fields( 'name', -cmp => '>', -is => 'Bob' ) );

C<< check_fields() >> will probably guess correctly whether you want numeric
or string comparison, but if you need to specify, you can:

  $people
    ->where( check_fields( 'phone', -is => '012345679', -string );
  
  $people
    ->where( check_fields( 'age', -is => '33', -numeric );

String comparisons can be made case-insensitive:

  $people
    ->where( check_fields( 'name', -is => 'Bob', -nocase ) );

You can use C<< -in >> to find a value in an arrayref. These comparisons are
always stringy and case-sensitive.

  $people
    ->where( check_fields( 'name', -in => ['Alice', 'Bob'] ) );

You can invert any comparison using C<< -nix >>.

  $people
    ->where( check_fields( 'name', -nix, -in => ['Alice', 'Bob'] ) );

You can perform more complex matches using L<match::simple>:

  $people
    ->where( check_fields( 'name', -match => qr/^[RB]ob(ert)?$/i ) );

SQL LIKE is also supported:

  $people
    ->where( check_fields( 'name', -like => 'Bob%', -nocase ) );

You can check multiple fields at once. There's an implied "AND" between the
conditions.

  $people
    ->where( check_fields(
      'name',       -is => 'Bob',
      'age',  -nix, -is => 33,
    ) );

You can compare one field to another field using C<< -to >>:

  # Says all the values which are between the min and max.
  LINQ(
    { min => 10, max => 100, value => 50 },
    { min => 10, max => 100, value =>  5 },
    { min => 10, max =>  20, value => 50 },
  )->where( check_fields(
    'value', -cmp => '>=', -to => 'min', -numeric,
    'value', -cmp => '<=', -to => 'max', -numeric,
  ) )->foreach( sub {
    say $_->value;
  } );

You can invert a whole C<< check_fields() >> using the C<< not >> method:

  my $where_not_bob = check_fields( 'name', -is => 'Bob' )->not;
  
  $people->where( $where_not_bob );

Generally, you can use C<< not >>, C<< and >>, and C<< or >> methods to compose
more complex conditions. The C<< ~ >>, C<< & >>, and C<< | >> bitwise operators
are also overloaded to compose conditions.

  my $where_alice = check_fields( 'name', -is => 'Alice' );
  my $where_bob   = check_fields( 'name', -is => 'Bob' );
  
  my $where_alice_or_bob = $where_alice->or( $where_bob );
  
  # Or...
  my $where_alice_or_bob = $where_alice | $where_bob;
  
  # Or...
  my $where_alice_or_bob =
    check_fields( 'name', -is => 'Alice' )
            ->or( 'name', -is => 'Bob' );

Like with C<< fields() >>, fields can be a coderef.

  my $where_bob = check_fields(
    sub { $_->get_name("givenName") }, -is => 'Bob'
  );

=back

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=LINQ>.

=head1 SEE ALSO

L<LINQ::Collection>, L<LINQ>.

L<https://en.wikipedia.org/wiki/Language_Integrated_Query>

=head1 AUTHOR

Toby Inkster E<lt>tobyink@cpan.orgE<gt>.

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2021 by Toby Inkster.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.
