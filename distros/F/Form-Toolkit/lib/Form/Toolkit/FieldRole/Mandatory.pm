package Form::Toolkit::FieldRole::Mandatory;
{
  $Form::Toolkit::FieldRole::Mandatory::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

has 'allow_blank' => ( is => 'ro', isa => 'Bool', default => 0 );

=head1 NAME

Form::Toolkit::FieldRole::Mandatory - A Role that makes the field mandatory

=head2 allow_blank

Set if this field can be totally blank (only space characters). Default is false.
Only works for scalar value

=cut

after 'validate' => sub{
  my ($self) = @_;
  my $v = $self->value();

  unless( defined $v ){
    $self->add_error("This field is mandatory");
    return;
  }

  unless( ref($v) ){
    unless( $self->allow_blank() ){
      if( $v =~ /^\s*$/ ){
        $self->add_error('This field is mandatory');
      }
    }
  }

};

1;
