package Mail::BIMI::CacheBackend::Null;
# ABSTRACT: Cache handling
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;

with 'Mail::BIMI::Role::CacheBackend';



sub get_from_cache($self) {
  return;
}


sub put_to_cache($self,$data) {
  return;
}


sub delete_cache($self) {
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::CacheBackend::Null - Cache handling

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Cache worker Role for Null storage

=head1 ATTRIBUTES

These values are derived from lookups and verifications made based upon the input values, it is however possible to override these with other values should you wish to, for example, validate a record before it is published in DNS, or validate an Indicator which is only available locally

=head2 parent

is=ro required

Parent class for cacheing

=head1 CONSUMES

=over 4

=item * L<Mail::BIMI::Role::CacheBackend>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 METHODS

=head2 I<get_from_cache()>

Retrieve this class data from cache

=head2 I<put_to_cache($data)>

Put this classes data into the cache

=head2 I<delete_cache>

Delete the cache entry for this class

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
