package Form::Toolkit::FieldRole::MinLength;
{
  $Form::Toolkit::FieldRole::MinLength::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

=head1 NAME

Form::Toolkit::FieldRole::MinLength - A Role that gives a min_length to this field.

=cut

has 'min_length' => ( is => 'rw' , isa => 'Int' , default => 0 , required => 1);

after 'validate' => sub{
  my ($self) = @_;
  unless( defined $self->value() ){ return ; }

  unless( length($self->value()) >= $self->min_length() ){
    $self->add_error('Value too short. Mininum length is '.$self->min_length().' characters');
  }

};

1;
