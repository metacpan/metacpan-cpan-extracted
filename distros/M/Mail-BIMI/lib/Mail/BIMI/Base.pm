package Mail::BIMI::Base;
# ABSTRACT: Base class for Mail::BIMI subclasses
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

has bimi_object => ( is => 'ro', isa => 'Mail::BIMI', required => 1, weak_ref => 1,
  documentation => 'Base Mail::BIMI object for this operation' );



sub record_object($self) {
  return $self->bimi_object->record;
}


sub authority_object($self) {
  return unless $self->record_object;
  return $self->record_object->authority;
}


sub log_verbose($self,$text) {
  $self->bimi_object->log_verbose($text);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Base - Base class for Mail::BIMI subclasses

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Base BIMI class with common methods and attributes

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 bimi_object

is=ro required

Base Mail::BIMI object for this operation

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 METHODS

=head2 I<record_object()>

Return the current Mail::BIMI::Record object for this operation

=head2 I<authority_object()>

Return the current Mail::BIMI::Authority object for this operation

=head2 I<log_verbose()>

Output given text if in verbose mode.

=head1 REQUIRES

=over 4

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
