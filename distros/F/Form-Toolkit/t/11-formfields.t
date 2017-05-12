#!perl -T
use strict;
use warnings;
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use Form::Toolkit::Clerk::Hash;

use Data::Dumper;

package MyFormBase;
use Moose;
extends qw/Form::Toolkit::Form/;
has 'stuff' => ( isa => 'Bool' , is => 'ro' , required => 1);

package MyForm;
use Moose;
extends qw/MyFormBase/;

sub build_fields{
  my ($self) = @_;
  $self->add_field('String' , 'a_string');
}

1;

package MyFormForm;
use Moose;
extends qw/MyFormBase/;

sub build_fields{
  my ($self) = @_;
  my $sf = $self->add_field('Form' , 'aform' );
}

sub from_literal{
  my ($self, $literal) = @_;
  return $self->next::method($literal , { stuff => $self->stuff() });
}

1;
package main;

ok( my $nested = MyForm->new({ stuff => 1}) , "Ok can build a form to be nested");
$nested->field('a_string')->value('hahaha');

ok( my $container = MyFormForm->new({ stuff => 1}) , "Ok can build container");
$container->field('aform')->value($nested);

my $snapshot = $container->values_hash();

$container->clear();
ok( ! $container->field('aform')->value() , "Ok value is gone");

ok( my $empty_hash = $container->values_hash() , "Ok can get a value hash even on empty container");

$container->fill_hash($snapshot);

is( $container->field('aform')->value()->field('a_string')->value(), 'hahaha' , "Good value back in nested form");

done_testing();
