package Form::Toolkit::Field::Form;
{
  $Form::Toolkit::Field::Form::VERSION = '0.008';
}
use Moose;

extends qw/Form::Toolkit::Field/;

=head1 NAME

Form::Toolkit::Field::Form - A field that can hold another nested L<Form::Toolkit::Form>

=head1 NOTES

The 'value' field of this is in fact a set of values.

=cut

has '+value' => ( isa => 'Form::Toolkit::Form' );

__PACKAGE__->meta->short_class('Form');
__PACKAGE__->meta->make_immutable();

=head2 value_struct

See superclass.

=cut

sub value_struct{
  my ($self) = @_;
  if( $self->value() ){
    return $self->value()->literal();
  }
  return undef;
}

__PACKAGE__->meta->make_immutable();

