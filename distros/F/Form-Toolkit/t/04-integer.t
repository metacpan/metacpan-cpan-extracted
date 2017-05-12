#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use Form::Toolkit::Clerk::Hash;


package MyFormInt;
use Moose;
extends qw/Form::Toolkit::Form/;

sub build_fields{
  my ($self) = @_;
  my $sf = $self->add_field('Integer' , 'aint' );
}

1;
package main;

my $f = MyFormInt->new();
## Test field_Set
Form::Toolkit::Clerk::Hash->new( source => { aint => 1 } )->fill_form($f);
ok( !$f->has_errors() , "Ok not errors");
$f->clear();

is( $f->field('aint')->meta->short_class() , 'Integer' , "Ok good short_class for field Integer");

{
  ## Test mandatory role
  $f->field('aint')->add_role('Mandatory');
  Form::Toolkit::Clerk::Hash->new( source => {} )->fill_form($f);
  ok($f->has_errors() , "Ok got error, because of mandatory");
  $f->clear();
}

{
  ## Bad format
  Form::Toolkit::Clerk::Hash->new( source => { aint => 'Boudin blanc' } )->fill_form($f);
  ok( $f->has_errors() , "Ok got errors, because of bad format");
  $f->clear();
}


{
  ## Min
  $f->field('aint')->add_role('MinMax')->set_min(0);
  Form::Toolkit::Clerk::Hash->new( source => { aint => '0' } )->fill_form($f);
  ok( ! $f->has_errors(), "Ok good");
  $f->clear();
  Form::Toolkit::Clerk::Hash->new( source => { aint => '-1' } )->fill_form($f);
  ok( $f->has_errors() , "Too low");
  $f->clear();
  ## Set exclusive
  $f->field('aint')->set_min(0, 'excl');
  Form::Toolkit::Clerk::Hash->new( source => { aint => '0' } )->fill_form($f);
  ok( $f->has_errors(), "Not good");
  $f->clear();
}

{
  ## Max
  $f->field('aint')->add_role('MinMax')->set_max(10);
  Form::Toolkit::Clerk::Hash->new( source => { aint => '10' } )->fill_form($f);
  ok( ! $f->has_errors(), "Ok good");
  $f->clear();

  Form::Toolkit::Clerk::Hash->new( source => { aint => '11' } )->fill_form($f);
  ok( $f->has_errors() , "Too high");
  $f->clear();

  ## Set exclusive
  $f->field('aint')->set_max(10, 'excl');
  Form::Toolkit::Clerk::Hash->new( source => { aint => '10' } )->fill_form($f);
  ok( $f->has_errors(), "Not good");
  $f->clear();

  Form::Toolkit::Clerk::Hash->new( source => { aint => '9' } )->fill_form($f);
  ok( ! $f->has_errors(), "Ok good");
  $f->clear();

}

done_testing();
