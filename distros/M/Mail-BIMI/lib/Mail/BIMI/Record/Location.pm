package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a BIMI location
our $VERSION = '1.20200214'; # VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
  with 'Mail::BIMI::Role::Error';
  with 'Mail::BIMI::Role::Constants';
  has location => ( is => 'rw', isa => ArrayRef, required => 1 );
  has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid' );

sub _build_is_valid($self) {

  foreach my $location ( $self->location->@* ) {
    if ( $location eq '' ) {
      $self->add_error( 'Empty l tag' );
    }
    elsif ( ! ( $location =~ /^https:\/\// ) ) {
      $self->add_error( $self->INVALID_TRANSPORT );
    }
  }

  return 0 if $self->error->@*;
  return 1;
}

1;
