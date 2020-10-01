package Mail::BIMI::CacheBackend::File;
# ABSTRACT: Cache handling
our $VERSION = '2.20200930.1'; # VERSION
use 5.20.0;
use Moose;
use Mail::BIMI::Prelude;
use File::Slurp qw{ read_file write_file };
use Sereal qw{encode_sereal decode_sereal};

with 'Mail::BIMI::Role::CacheBackend';
has _cache_filename => ( is => 'ro', lazy => 1, builder => '_build_cache_filename' );



sub get_from_cache($self) {
  my $cache_file = $self->_cache_filename;
  return if !-e $cache_file;
  my $raw = scalar read_file($self->_cache_filename);
  my $value = eval{ decode_sereal($raw) };
  warn "Error reading from cache: $@" if $@;
  return $value;
}


sub put_to_cache($self,$data) {
  $self->parent->log_verbose('Writing '.(ref $self->parent).' to cache file '.$self->_cache_filename);
  my $sereal_data = eval{ encode_sereal($data) };
  warn "Error writing to cache: $@" if $@; # uncoverable branch
  return unless $sereal_data; # uncoverable branch
  write_file($self->_cache_filename,{atomic=>1},$sereal_data);
}


sub delete_cache($self) {
  unlink $self->_cache_filename or warn "Unable to unlink cache file: $!";
}

sub _build_cache_filename($self) {
  my $cache_dir = $self->parent->bimi_object->options->cache_file_directory;
  return $cache_dir.'mail-bimi-cache-'.$self->_cache_hash.'.cache';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::BIMI::CacheBackend::File - Cache handling

=head1 VERSION

version 2.20200930.1

=head1 DESCRIPTION

Cache worker role for File storage

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

=item * L<File::Slurp|File::Slurp>

=item * L<Mail::BIMI::Prelude|Mail::BIMI::Prelude>

=item * L<Moose|Moose>

=item * L<Sereal|Sereal>

=back

=head1 AUTHOR

Marc Bradshaw <marc@marcbradshaw.net>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Marc Bradshaw.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
