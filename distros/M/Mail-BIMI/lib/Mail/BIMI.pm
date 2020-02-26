package Mail::BIMI;
# ABSTRACT: BIMI object
our $VERSION = '1.20200226'; # VERSION
use 5.20.0;
use Moo;
use Carp;
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
  has spf_object => ( is => 'rw', isa => class_type('Mail::SPF::Result') );
  has record => ( is => 'rw', lazy => 1, builder => '_build_record' );
  has result => ( is => 'rw', lazy => 1, builder => '_build_result' );

sub _build_record($self) {
  croak 'Domain required' if ! $self->domain;
  return Mail::BIMI::Record->new( domain => $self->domain, selector => $self->selector, resolver => $self->resolver );
}

sub _build_result($self) {
  croak 'Domain required' if ! $self->domain;

  my $result = Mail::BIMI::Result->new(
    parent => $self,
  );

  # does DMARC pass
  if ( ! $self->dmarc_object ) {
    $result->set_result( 'skipped', $self->NO_DMARC );
    return $result;
  }
  if ( $self->dmarc_object->result ne 'pass' ) {
      $result->set_result( 'skipped', 'DMARC ' . $self->dmarc_object->result );
      return $result;
  }

  if ( $self->spf_object ) {
      my $spf_request = $self->spf_object->request;
      if ( $spf_request ) {
          my $spf_record = $spf_request->record;
          if ( $spf_record ) {
              my @spf_terms = $spf_record->terms;
              if ( @spf_terms ) {
                    my $last_term = pop @spf_terms;
                    if ( $last_term->name eq 'all' && $last_term->qualifier eq '+') {
                        $result->set_result( 'skipped', $self->SPF_PLUS_ALL );
                        return $result;
                    }
                }
            }
        }
    }

  if ( ! $self->record->is_valid ) {
    if ( $self->record->has_error( $self->NO_BIMI_RECORD ) ) {
      $result->set_result( 'none', $self->BIMI_NOT_ENABLED );
    }
    elsif ( $self->record->has_error( $self->DNS_ERROR ) ) {
      $result->set_result( 'none', $self->DNS_ERROR );
    }
    else {
      $result->set_result( 'fail', $self->BIMI_INVALID );
    }
    return $result;
  }

  $result->set_result( 'pass', '' );

  return $result;
}


1;
