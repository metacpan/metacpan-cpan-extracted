package Form::Toolkit::FieldRole::MonoValued;
{
  $Form::Toolkit::FieldRole::MonoValued::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

=head1 NAME

Form::Toolkit::FieldRole::MonoValued - A Role that makes a _Set_ field mono valued.

=cut

after 'validate' => sub{
  my ($self) = @_;
  unless( defined $self->value() ){
    return;
  }
  if( @{$self->value()} > 1 ){
    $self->add_error("Please provide only one value. The GUI code should not let you add more than one anyway.");
  }
};

1;
