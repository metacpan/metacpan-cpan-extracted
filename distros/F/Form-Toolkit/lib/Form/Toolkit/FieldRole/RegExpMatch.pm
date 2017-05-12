package Form::Toolkit::FieldRole::RegExpMatch;
{
  $Form::Toolkit::FieldRole::RegExpMatch::VERSION = '0.008';
}
use Moose::Role;
with qw/Form::Toolkit::FieldRole/;

has 'regexp_match' => ( is => 'ro' , isa => 'RegexpRef' , required => 1);
has 'regexp_match_desc' => ( is => 'ro' , isa => 'Str', required => 1, lazy => 1 , builder => '_build_regexp_match_desc');

sub _build_regexp_match_desc{
  my ($self) = @_;
  ## Just stringify the regex.
  return $self->regexp_match().'';
}


=head1 NAME

Form::Toolkit::FieldRole::RegExpMatch - A Role that checks the value matches a regex

=head2 regexp_match

Sets the regexp this field should match


=head2 regexp_match_desc

Sets the description of this regex so it makes sense for a user.

=cut

after 'validate' => sub{
  my ($self) = @_;
  my $v = $self->value();

  unless( defined $v ){
    return;
  }

  ## Note that we only consider pure scalar values.
  if( ref($v) ){ return ;}

  unless( $v =~ $self->regexp_match() ){
    $self->add_error('This field must be '.$self->regexp_match_desc());
  }
};

1;
