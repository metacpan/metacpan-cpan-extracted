package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a collection of egress pools
our $VERSION = '1.20200210'; # VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
  with 'Mail::BIMI::Role::Error';
  has authority => ( is => 'rw', isa => ArrayRef, required => 1 );

1;
