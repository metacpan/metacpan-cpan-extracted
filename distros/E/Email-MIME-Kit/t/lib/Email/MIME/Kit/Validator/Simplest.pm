package Email::MIME::Kit::Validator::Simplest;
use Moose;
with 'Email::MIME::Kit::Role::Validator';

use File::Spec;

has required_fields => (
  reader => 'required_fields',
  writer => '_set_required_fields',
  isa    => 'ArrayRef',
);

sub validate {
  my ($self, $stash) = @_;
  
  for my $name (@{ $self->required_fields }) {
    confess "required field <$name> not provided" if ! exists $stash->{$name};
  }
}

1;
