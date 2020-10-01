package Mail::BIMI::Record::Authority;
# ABSTRACT: Class to model a BIMI authority
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::VMC;

extends 'Mail::BIMI::Base';
with 'Mail::BIMI::Role::HasError';
has is_authority_valid => ( is => 'rw', lazy => 1, builder => '_build_is_authority_valid' );
has uri => ( is => 'rw', isa => 'Maybe[Str]', required => 1,
  documentation => 'inputs: URI of VMC', );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Is this Authority valid' );
has vmc => ( is => 'rw', lazy => 1, builder => '_build_vmc',
  documentation => 'Mail::BIMI::VMC object for this Authority' );


sub _build_is_authority_valid($self) {
  return 1 if !defined $self->uri;
  return 1 if $self->uri eq '';
  return 1 if $self->uri eq 'self';
  if ( ! ( $self->uri =~ /^https:\/\// ) ) {
    $self->add_error('INVALID_TRANSPORT_A');
  }

  return 0 if $self->errors->@*;
  return 1;
}


sub is_relevant($self) {
  return 0 if !defined $self->uri;
  return 0 if $self->uri eq '';
  return 0 if $self->uri eq 'self';
  return 0 if $self->bimi_object->options->no_validate_cert;
  $self->log_verbose('Authority is relevant');
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->is_authority_valid;
  if ( $self->is_relevant && !$self->vmc->is_valid ) {
    $self->add_error_object( $self->vmc->errors );
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('Authority is valid');
  return 1;
}

sub _build_vmc($self) {
  return if !$self->is_authority_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::VMC->new( uri => $self->uri, bimi_object => $self->bimi_object );
}


sub finish($self) {
  $self->vmc->finish if $self->vmc;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Record::Authority - Class to model a BIMI authority

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI authority attribute

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 uri

is=rw required

URI of VMC

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 errors

is=rw

=head2 is_authority_valid

is=rw

=head2 is_valid

is=rw

Is this Authority valid

=head2 vmc

is=rw

Mail::BIMI::VMC object for this Authority

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::HasError>

=back

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<is_relevant()>

Return true if this Authority is relevant to validation

=head2 I<finish()>

Finish and clean up, write cache if enabled.

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Mail::BIMI::VMC|Mail::BIMI::VMC>

=item * L<Moose|Moose>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
