package Mail::BIMI;
# ABSTRACT: Class to model a collection of egress pools
our $VERSION = '1.20200103'; # VERSION
use 5.20.0;
use Moo;
use Types::Standard qw{Str HashRef ArrayRef};
use Type::Utils qw{class_type};
use Mail::BIMI::Pragmas;

use English qw( -no_match_vars );

use Mail::BIMI::Record;
use Mail::BIMI::Result;
  with 'Mail::BIMI::Role::Resolver';
  with 'Mail::BIMI::Role::Constants';
  has domain => ( is => 'rw', isa => Str );
  has selector => ( is => 'rw', isa => Str, lazy => 1, builder => sub{ return 'default' } );
  has dmarc_object => ( is => 'rw', isa => class_type('Mail::DMARC::Result') );
  has record => ( is => 'rw', lazy => 1, builder => '_build_record' );
  has result => ( is => 'rw', lazy => 1, builder => '_build_result' );

sub _build_record($self) {
  return Mail::BIMI::Record->new( domain => $self->domain, selector => $self->selector, resolver => $self->resolver );
}

sub _build_result($self) {
  my $result = Mail::BIMI::Result->new(
    parent => $self,
  );

  # does DMARC pass
  if ( ! $self->dmarc_object ) {
    $result->set_result( 'skipped', 'no DMARC' );
    return $result;
  }
  if ( $self->dmarc_object->result ne 'pass' ) {
      $result->set_result( 'skipped', 'DMARC ' . $self->dmarc_object->result );
      return $result;
  }


  if ( ! $self->record ) {
    $result->set_result( 'none', 'No BIMI Record' );
    return $result;
  }

  if ( ! $self->record->is_valid ) {
    if ( $self->record->has_error( $self->NO_BIMI_RECORD ) ) {
      $result->set_result( 'none', 'Domain is not BIMI enabled' );
    }
    else {
      $result->set_result( 'fail', 'Invalid BIMI Record' );
    }
    return $result;
  }

  $result->set_result( 'pass', '' );

  return $result;
}


1;
