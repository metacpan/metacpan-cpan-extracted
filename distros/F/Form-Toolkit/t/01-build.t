#!perl -T
use Test::More;
use Test::Exception;
use Form::Toolkit::Form;
use DateTime;

ok( my $f = Form::Toolkit::Form->new() );
# diag($f->meta->id());
ok( $f->meta->id() =~ /^form_/ , "Ok form id is prefixed correctly");
ok( $f->id() , "Still ok to call deprecated id");

ok( $f->add_field('field1') );
ok( $f->add_field('String' , 'field2')->set_help('This is field 2')->set_placeholder('BLA') , "Ok can build field2 with help text and placeholder" );
ok( $f->add_field('Integer' , 'int_field') , "Ok can buid Integer field");

ok( $f->field('field1')->isa('Form::Toolkit::Field::String') , "Ok field1 is a string");
ok( $f->field('field2')->isa('Form::Toolkit::Field::String') , "Ok field2 is a string too");
ok( $f->field('int_field')->isa('Form::Toolkit::Field::Integer') , "Ok field2 is an integer");
ok( $f->field('field2')->value('Bla') , "Ok can set value on f2");

ok( $f->add_field('Date' , 'field_date') , "Ok added date field");
ok( $f->add_field('+Form::Toolkit::Field::Date' , 'field_date_2')  , "Ok added another field date");
ok( $f->field('field_date')->value(DateTime->now()), "Ok can set value");
ok( $f->field('int_field')->value(100) , "Ok can set valid integer value");
is( $f->field('int_field')->value() , 100 , "Good value is stored");
is( $f->field('int_field')->value(-100) , -100 , "Good value is stored");

ok( $f->add_field( Form::Toolkit::Field::String->new({ form => $f , name => 'field3'})) , "Can add an instance");

dies_ok(sub{ $f->add_field('field1'); } , "Cannot add twice the same field");

ok( $f->add_error('There is an error') , "Ok can add error");
ok( $f->has_errors() , "Form has errors");
$f->clear();
ok( ! $f->has_errors() , "Form doesnt have errors anymore");

$f->field('field2')->add_error('A field error');
ok( $f->has_errors() , "Ok form has error because of a field");
$f->clear();
ok(! $f->has_errors() , "Ok form is reset, so no error");
ok( $f->is_valid() , "Is also valid");
ok( $f->field('field2')->set_label('Boudin blanc')->isa('Form::Toolkit::Field') , "Ok can set label");
ok( $f->field('field2')->id() , "Ok got an id");
cmp_ok( $f->field('field2')->meta->short_class() , 'eq' , $f->field('field2')->short_class() , "Shortcut short_class works");

{
  {
    package My::Form;
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
  }

my $form = My::Form->new();
$form->field('a_bool')->value(1);
$form->field('a_date')->value(DateTime->now());
$form->field('a_int')->value(314);
$form->field('a_set')->value([ 1, 2, 3, 4 ]);
$form->field('a_string')->value("HAHAHAHA");

ok(my $litteral = $form->literal() , "Ok got litteral");
ok( my $lb = Form::Toolkit::Form->from_literal($litteral) , "Ok loopback");
use Data::Dumper;
is_deeply($lb->values_hash() , $form->values_hash() , "Ok loopback form has got same values");
}
done_testing();
