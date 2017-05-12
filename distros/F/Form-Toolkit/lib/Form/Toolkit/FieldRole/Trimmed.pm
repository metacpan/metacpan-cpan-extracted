package Form::Toolkit::FieldRole::Trimmed;
{
  $Form::Toolkit::FieldRole::Trimmed::VERSION = '0.008';
}
use Moose::Role;

with qw/Form::Toolkit::FieldRole/;

=head1 NAME

Form::Toolkit::FieldRole::Trimmed - A Role that trims the value to avoid heading and trailing spacing characters.

=cut


around 'value' => sub{
  my ($orig, $self , $new_v ) = @_;

  unless( defined $new_v ){
    return $self->$orig();
  }
  if( ref($new_v) ){
    ## Cannot trim a reference (for now, until we decide to trim values in a collection for instance).
    return $self->$orig($new_v);
  }
  $new_v =~ s/^\s+//;
  $new_v =~ s/\s+$//;
  return $self->$orig($new_v);
};


1;
