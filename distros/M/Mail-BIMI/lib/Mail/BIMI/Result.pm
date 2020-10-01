package Mail::BIMI::Result;
# ABSTRACT: Class to model a BIMI result
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use Mail::AuthenticationResults::Header::Entry;
use Mail::AuthenticationResults::Header::SubEntry;
use Mail::AuthenticationResults::Header::Comment;

extends 'Mail::BIMI::Base';
has result => ( is => 'rw', isa => 'Str',
  documentation => 'Text result' );
has comment => ( is => 'rw', isa => 'Str',
  documentation => 'Text comment' );
has error => ( is => 'rw',
  documentation => 'Optional Mail::BIMI::Error object detailing failure' );
has headers => ( is => 'rw', isa => 'HashRef',
  documentation => 'Hashref of headers to add to message' );



sub domain($self) {
  return $self->bimi_object->domain;
}


sub selector($self) {
  return $self->bimi_object->selector;
}


sub set_result($self,$result) {
  if ( ref $result eq 'Mail::BIMI::Error' ) {
    $self->result($result->result);
    $self->comment($result->description);
  }
  else {
    $self->result($result);
  }
}


sub get_authentication_results_object($self) {
  my $header = Mail::AuthenticationResults::Header::Entry->new()->set_key( 'bimi' )->safe_set_value( $self->result );
  if ( $self->comment ) {
    $header->add_child( Mail::AuthenticationResults::Header::Comment->new()->safe_set_value( $self->comment ) );
  }
  if ( $self->result eq 'pass' ) {
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.d' )->safe_set_value( $self->bimi_object->record->domain ) );
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'header.selector' )->safe_set_value( $self->bimi_object->record->selector ) );
  }
  if ( $self->bimi_object->record->authority->is_relevant ) {
    my $vmc = $self->bimi_object->record->authority->vmc;
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'policy.authority' )->safe_set_value( $vmc->is_valid ? 'pass' : 'fail' ) );
    $header->add_child( Mail::AuthenticationResults::Header::SubEntry->new()->set_key( 'policy.authority-uri' )->safe_set_value( $self->bimi_object->record->authority->uri ) );
  }

  return $header;
}


sub get_authentication_results($self) {
  return $self->get_authentication_results_object->as_string;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Result - Class to model a BIMI result

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Class for representing a BIMI result

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 comment

is=rw

Text comment

=head2 error

is=rw

Optional Mail::BIMI::Error object detailing failure

=head2 headers

is=rw

Hashref of headers to add to message

=head2 result

is=rw

Text result

=head1 EXTENDS

=over 4

=item * L<Mail::BIMI::Base>

=back

=head1 METHODS

=head2 I<domain()>

Return the domain of the current operation

=head2 I<selector()>

Return the selector of the current operation

=head2 I<set_result($result)>

Set the result text and comment for this Result object

If $result is a Mail::BIMI::Error object then the result will be built from
its attributes, otherwise the result must be a string.

=head2 I<get_authentication_results_object()>

Returns a Mail::AuthenticationResults::Header::Entry object with the BIMI results set

=head2 I<get_authentication_results()>

Return the BIMI Authentication-Results fragment as text

=head1 REQUIRES

=over 4

=item * L<Mail::AuthenticationResults::Header::Comment|Mail::AuthenticationResults::Header::Comment>

=item * L<Mail::AuthenticationResults::Header::Entry|Mail::AuthenticationResults::Header::Entry>

=item * L<Mail::AuthenticationResults::Header::SubEntry|Mail::AuthenticationResults::Header::SubEntry>

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
