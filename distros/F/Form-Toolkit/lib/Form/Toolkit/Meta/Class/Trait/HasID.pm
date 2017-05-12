package Form::Toolkit::Meta::Class::Trait::HasID;
{
  $Form::Toolkit::Meta::Class::Trait::HasID::VERSION = '0.008';
}
use Moose::Role;

=head2 NAME

Form::Toolkit::Meta::Class::Trait::HasID - Gives a meta->id and a meta->id_prefix attribute to this trait consumer.

=cut

{
  my $FORMSEQ = 0;
  sub _next_default_id{
    my ($self) = @_;
    return ( $self->id_prefix() // $self ).(++$FORMSEQ);
  }
}

has 'id' => ( isa => 'Str' , is => 'rw', lazy => 1 , default => sub{ $_[0]->_next_default_id() } );
has 'id_prefix' => ( isa => 'Str' , is => 'rw' );

1;
