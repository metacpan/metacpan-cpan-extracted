package Mail::BIMI::Record::Location;
# ABSTRACT: Class to model a BIMI location
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::BIMI::Indicator;

extends 'Mail::BIMI::Base';
with 'Mail::BIMI::Role::HasError';
has is_location_valid => ( is => 'rw', lazy => 1, builder => '_build_is_location_valid' );
has uri => ( is => 'rw', isa => 'Maybe[Str]', required => 1,
  documentation => 'inputs: URI of Indicator', );
has is_valid => ( is => 'rw', lazy => 1, builder => '_build_is_valid',
  documentation => 'Is this Location record valid' );
has indicator => ( is => 'rw', lazy => 1, builder => '_build_indicator',
  documentation => 'Mail::BIMI::Indicator object for this location' );
has is_relevant => ( is => 'rw', lazy => 1, default => sub{return 1},
  documentation => 'Is the location relevant' );


sub _build_is_location_valid($self) {
  # Check is_valid without checking indicator, because recursion!
  if ( !defined $self->uri ) {
    $self->add_error('MISSING_L_TAG');
  }
  elsif ( $self->uri eq '' ) {
    $self->add_error('EMPTY_L_TAG');
  }
  elsif ( ! ( $self->uri =~ /^https:\/\// ) ) {
    $self->add_error('INVALID_TRANSPORT_L');
  }
  else {
  }

  return 0 if $self->errors->@*;
  return 1;
}

sub _build_is_valid($self) {
  return 0 if !$self->is_location_valid;
  if ( !$self->indicator->is_valid ) {
    $self->add_error_object( $self->indicator->errors );
  }

  return 0 if $self->errors->@*;
  $self->log_verbose('Location is valid');
  return 1;
}

sub _build_indicator($self) {
  return if !$self->is_location_valid;
  return if !$self->is_relevant;
  return Mail::BIMI::Indicator->new( uri => $self->uri, bimi_object => $self->bimi_object, source => 'Location' );
}


sub finish($self) {
  $self->indicator->finish if $self->indicator;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Record::Location - Class to model a BIMI location

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing, validating, and processing a BIMI location attribute

=head1 INPUTS

These values are used as inputs for lookups and verifications, they are typically set by the caller based on values found in the message being processed

=head2 uri

is=rw required

URI of Indicator

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 errors

is=rw

=head2 indicator

is=rw

Mail::BIMI::Indicator object for this location

=head2 is_location_valid

is=rw

=head2 is_relevant

is=rw

Is the location relevant

=head2 is_valid

is=rw

Is this Location record valid

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::HasError>

=back

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<finish()>

Finish and clean up, write cache if enabled.

=head1 REQUIRES

=over 4

=item * L<Mail::BIMI::Indicator|Mail::BIMI::Indicator>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose|Moose>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
