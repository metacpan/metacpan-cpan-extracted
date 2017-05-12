#!perl -T
use strict;
use warnings;
use Data::Dumper;
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use Form::Toolkit::Clerk::Hash;

package MyForm4Hash;
use Moose;
extends qw/Form::Toolkit::Form/;

sub build_fields{
  my ($self) = @_;
  $self->add_field('Boolean' , 'a_bool' )->add_role('Mandatory');
  $self->add_field('Date' , 'a_date' );
  $self->add_field('Integer' , 'a_int' );
  $self->add_field('Set' , 'a_set' );
  $self->add_field('String' , 'a_string' );
}

1;
package main;


my @input_hashes = (

                    { a_bool => 1,
                      a_date => '1977-10-20T17:04:00',
                      a_int => 314,
                      a_set => [ 'a', 'b' , 3 ],
                      a_string => 'bla'
                    },
                   );

foreach my $input_hash ( @input_hashes ){
  ## Test valid input
  my $f = MyForm4Hash->new();

  Form::Toolkit::Clerk::Hash->new( source => $input_hash )->fill_form($f);

  foreach my $clone_method ( 'clone' , 'fast_clone' ){
    diag("Clone method $clone_method");
    my $clone = $f->$clone_method();
    $clone->field('a_bool')->value(!$f->field('a_bool')->value());
    ok( $f->field('a_bool')->value == ! $clone->field('a_bool')->value() , "Ok clone is different on boolean");

    $clone->field('a_string')->value($f->field('a_string')->value().'_cloned!');
    is($clone->field('a_string')->value() , $f->field('a_string')->value().'_cloned!' , "Ok clone differs on string");

    $clone->field('a_date')->value($f->field('a_date')->value()->clone->add( days => 1 ));
    ok($clone->field('a_date')->value()->compare( $f->field('a_date')->value()->clone->add( days => 1 )) == 0 , "Ok clone differs on a date");

    $clone->field('a_int')->value($f->field('a_int')->value() + 1 );
    is($clone->field('a_int')->value(), $f->field('a_int')->value() + 1 , "Ok clone differs on a int");


    $clone->field('a_set')->value([ @{ $f->field('a_set')->value() }, 'added']);
    is_deeply($clone->field('a_set')->value(), [ @{ $f->field('a_set')->value() } , 'added' ] , "Ok clone differs on a set");

    ok( $clone->field('a_set')->has_value('added') , "Cloned set has added value");
    ok( !$f->field('a_set')->has_value('added') , "Original has no added value");

    $clone->field('a_set')->remove_value('added');
    $f->field('a_set')->add_value('added');
    is_deeply($f->field('a_set')->value(), [ @{ $clone->field('a_set')->value() } , 'added' ] , "Ok could add and remove value to original");
    $f->field('a_set')->remove_value('added');

  }

}



done_testing();
