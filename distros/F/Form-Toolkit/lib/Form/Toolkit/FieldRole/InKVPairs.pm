package Form::Toolkit::FieldRole::InKVPairs;
{
  $Form::Toolkit::FieldRole::InKVPairs::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole::HasKVPairs/;

=head1 NAME

Form::Toolkit::FieldRole::InKVPairs - A Role that makes sure a _Set_ field only contains values from the in_kvpairs (a L<Form::Toolkit::KVPairs>) set

=cut

after 'validate' => sub{
  my ($self) = @_;
  unless( defined $self->value() ){
    return;
  }

  foreach my $v ( @{$self->value()} ){
    unless( $self->kvpairs->lookup($v) ){
      $self->add_error("Value $v is not in the allowed set of values");
    }
  }
};



1;
