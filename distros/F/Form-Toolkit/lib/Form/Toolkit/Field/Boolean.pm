package Form::Toolkit::Field::Boolean;
{
  $Form::Toolkit::Field::Boolean::VERSION = '0.008';
}
use Moose;

extends qw/Form::Toolkit::Field/;

=head1 NAME

Form::Toolkit::Field::String - A Pure and single boolean field. Could render as a checkbox.

=head1 NOTES

The state of this is either a true value or nothing. Meaning undef. This is
to stay consistent with the Role Mandatory.

=cut

has '+value' => ( isa => 'Bool' );

=head2 value_struct

Returns the string value of this field.

=cut

sub value_struct{
  my ($self) = @_;
  unless( $self->value() ){
    return 0;
  }
  return 1;
}


__PACKAGE__->meta->short_class('Boolean');
__PACKAGE__->meta->make_immutable();
1;
