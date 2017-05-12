package Form::Toolkit::FieldRole::Email;
{
  $Form::Toolkit::FieldRole::Email::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole
        Form::Toolkit::FieldRole::Trimmed
       /;

use Mail::RFC822::Address;

=head1 NAME

Form::Toolkit::FieldRole::Email - A Role that checks if the value looks like an email.

=cut


around 'value' => sub{
  my ($orig, $self , $v ) = @_;
  unless( defined $v ){
    return $self->$orig();
  }
  my $new_v = lc($v);
  return $self->$orig($new_v);
};


after 'validate' => sub{
  my ($self) = @_;

  ## Nothing to validate.
  unless( $self->value() ){ return ;}
  unless( Mail::RFC822::Address::valid($self->value) ){
    $self->add_error("Invalid email. Please check it looks like john\@example.com");
  }
};
1;
