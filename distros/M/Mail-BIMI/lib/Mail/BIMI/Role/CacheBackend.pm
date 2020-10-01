package Mail::BIMI::Role::CacheBackend;
# ABSTRACT: Cache handling backend
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose::Role;
use Mail::BIMI::Prelude;
use Digest::SHA;

has parent => ( is => 'ro', required => 1, weak_ref => 1,
  documentation => 'Parent class for cacheing' );
has _cache_hash => ( is => 'ro', lazy => 1, builder => '_build_cache_hash' );
requires 'get_from_cache';
requires 'put_to_cache';
requires 'delete_cache';


sub _build_cache_hash($self) {
  my $context = Digest::SHA->new;
  ## TODO make sure there are no wide characters present in cache key
  $context->add($self->parent->_cache_key);
  my $hash = $context->hexdigest;
  $hash =~ s/ //g;
  return $hash;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::Role::CacheBackend - Cache handling backend

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Role for implementing a cache backend

=head1 REQUIRES

=over 4

=item * L<Digest::SHA|Digest::SHA>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose::Role|Moose::Role>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
