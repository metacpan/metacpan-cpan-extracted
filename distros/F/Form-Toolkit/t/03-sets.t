#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use Form::Toolkit::Clerk::Hash;
use Form::Toolkit::KVPairs::Pure;

# ok( my $f = Form::Toolkit::Test->new() );
# ok( scalar( @{$f->fields()} ) , "Ok form has fields");
# foreach my $field ( @{$f->fields() }){
#   diag($field->name().' '.join(',' , $field->meta->linearized_isa()));
# }


# $f->clear();
# ok( my $clerk = Form::Toolkit::Clerk::Hash->new( source => { field_String => 'Blabla' , field_Date => '2011-10-10',
#                                                           field_Boolean => 'Something true',
#                                                         } ) );
# ok( $clerk->fill_form($f) , "Ok the clerk can fill the form" );
# ok( $f->field('field_Boolean')->value() , "Ok boolean field is true");
# ok( $f->field('mandatory_and_long')->has_errors() , "Ok mandatory and long string has errors");
# diag(join(',' , @{$f->field('mandatory_and_long')->errors()} )  );
# $f->clear();

package MyFormSet;
use Moose;
extends qw/Form::Toolkit::Form/;

sub build_fields{
  my ($self) = @_;
  ## Note that the Trimmed role should be without effect,
  ## as it works only on single values.
  my $sf = $self->add_field('Set' , 'aset' )->add_role('Trimmed');
}

1;
package main;

my $f = MyFormSet->new();
## Test field_Set
Form::Toolkit::Clerk::Hash->new( source => { aset => 1 } )->fill_form($f);
ok( !$f->has_errors() , "Ok not errors");
$f->clear();
$f->field('aset')->add_role('Mandatory');
Form::Toolkit::Clerk::Hash->new( source => {} )->fill_form($f);
ok($f->has_errors() , "Ok got error, because of mandatory");

$f->clear();
Form::Toolkit::Clerk::Hash->new( source => { aset => [ 1, 2 ] } )->fill_form($f);
ok(! $f->has_errors() , "Ok No error again");

$f->field('aset')->add_role('InKVPairs')->kvpairs(Form::Toolkit::KVPairs::Pure
                                                  ->new({ array => [ { 1 => 'One'},
                                                                     { 2 => 'Two'},
                                                                     { 3 => 'Three'}
                                                                   ]}));
$f->clear();
Form::Toolkit::Clerk::Hash->new( source => { aset => [ 1, 2 , 4 ] } )->fill_form($f);
ok( $f->has_errors() , "Form has errors, as 4 is not in the list of allowed values");

$f->clear();
Form::Toolkit::Clerk::Hash->new( source => { aset => [ 1, 2 ] } )->fill_form($f);
ok( ! $f->has_errors() , "Form has no errors. Only added allowed values");

$f->field('aset')->add_role('MonoValued');
$f->clear();
Form::Toolkit::Clerk::Hash->new( source => { aset => [ 1, 2 ] } )->fill_form($f);
ok($f->has_errors() , "Ok Error. Should be monovalued");
$f->clear();
Form::Toolkit::Clerk::Hash->new( source => { aset => [ 2 ] } )->fill_form($f);
ok(!$f->has_errors() , "Mono valued => no error");
ok( $f->field('aset')->has_value(2) , "Ok field has value 2");
ok( ! $f->field('aset')->has_value(123) , "Ok field has no value 123");
$f->clear();
ok( ! $f->field('aset')->has_value(2), "A clear form field doesnt contain any value");


{
  ## Test add and remove values.
  package MyFormSetAdd;
  use Moose;
  extends qw/Form::Toolkit::Form/;
  sub build_fields{
    my ($self) = @_;
    $self->add_field('Set' , 'aset' );
  }
  1;
  package main;
  my $f = MyFormSetAdd->new();
  my $sf = $f->field('aset');
  $sf->value([ 'a' , 'b' , 'c' ]);

  ok( $sf->add_value('d') , "Ok can add new value");
  ok(! $sf->add_value('b') , "Ok cannot add b");
  is_deeply( $sf->value() , [ 'a' , 'b' , 'c' , 'd' ] ,"Ok add");
  is( $sf->_values_idx()->{d} , 3 , "Good index for new value");
  ok( $sf->remove_value('b') , "Ok can remove existing value");
  ok( ! $sf->has_value('b') , "Ok no c value left in set");
  is( $sf->_values_idx()->{d} , 2 , "Good index for d");
  is( $sf->_values_idx()->{c} , 1 , "Good index for b");
  ok(! exists $sf->_values_idx()->{b} , "No index for gone value");
  is( $sf->_values_idx()->{a} , 0 , "Good index for a");
}


done_testing();

