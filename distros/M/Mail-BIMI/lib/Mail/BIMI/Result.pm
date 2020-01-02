package Mail::BIMI::Result;
# ABSTRACT: Class to model a collection of egress pools
our $VERSION = '1.20200102'; # VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Comment;
  has parent => ( is => 'ro', isa => class_type('Mail::BIMI'), required => 1, weaken => 1);
  has result => ( is => 'rw', isa => Str );
  has comment => ( is => 'rw', isa => Str );

sub domain($self) {
  return $self->parent->domain;
}

sub selector($self) {
  return $self->parent->selector;
}

sub set_result($self,$result,$comment) {
  $self->result($result);
  $self->comment($comment);
}

sub get_authentication_results_object($self) {
  my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'bimi' )->safe_set_value( $self->result );
  if ( $self->comment ) {
    $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( $self->comment ) );
  }
  if ( $self->result eq 'pass' ) {
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.d' )->safe_set_value( $self->parent->record->domain ) );
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'selector' )->safe_set_value( $self->parent->record->selector ) );
  }
  return $header;
}

sub get_authentication_results($self) {
  return $self->get_authentication_results_object->as_string;
}

sub get_bimi_location {
}

1;
