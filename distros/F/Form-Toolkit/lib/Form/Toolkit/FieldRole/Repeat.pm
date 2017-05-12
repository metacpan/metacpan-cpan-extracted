package Form::Toolkit::FieldRole::Repeat;
{
  $Form::Toolkit::FieldRole::Repeat::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

=head1 NAME

Form::Toolkit::FieldRole::Repeat - A Role that requires this field to repeat another one

=cut

has 'repeat_field' => ( is => 'rw' , isa => 'Form::Toolkit::Field' , required => 0);

after 'validate' => sub{
  my ($self) = @_;
  unless( $self->repeat_field ){ return ; }

  if( ( $self->repeat_field->value() // '' ) ne ( $self->value() // '' ) ){
    $self->add_error("Please repeat the field \"".$self->repeat_field->label().'"');
  }

};

1;
