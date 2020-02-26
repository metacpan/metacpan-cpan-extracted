package Mail::BIMI::Role::Error;
# ABSTRACT: Class to model an error
our $VERSION = '1.20200226'; # VERSION
use 5.20.0;
use Moo::Role;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
  has error => ( is => 'rw', isa => ArrayRef, lazy => 1, builder => sub{return []} );

sub add_error($self,$error) {
  push $self->error->@*, $error;
}

sub has_error($self,$error) {
  if ( grep { $_ =~ /$error/ } $self->error->@* ) {
    return 1;
  }
  return 0;
}

1;
