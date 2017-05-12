# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
#
# This file is part of Dist-Metadata
#
# This software is copyright (c) 2011 by Randy Stauner.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
use strict;
use warnings;

package Dist::Metadata::Struct;
our $AUTHORITY = 'cpan:RWSTAUNER';
# ABSTRACT: Enable Dist::Metadata for a data structure
$Dist::Metadata::Struct::VERSION = '0.927';
use Carp qw(croak carp); # core
use parent 'Dist::Metadata::Dist';

push(@Dist::Metadata::CARP_NOT, __PACKAGE__);


sub required_attribute { 'files' }


sub default_file_spec { 'Unix' }


sub file_content {
  my ($self, $file) = @_;
  # TODO: should we croak if not found?  would be consistent with Dir
  my $content = $self->{files}{ $self->full_path($file) };

  # 5.10: given(ref($content))

  if( my $ref = ref $content ){
    local $/; # do this here because of perl bug prior to perl 5.15 (7c2d9d0)
    return $ref eq 'SCALAR'
      # allow a scalar ref
      ? $$content
      # or an IO-like object
      : $content->getline;
  }
  # else a simple string
  return $content;
}


sub find_files {
  my ($self) = @_;

  return keys %{ $self->{files} };
}

1;

__END__

=pod

=encoding UTF-8

=for :stopwords Randy Stauner ACKNOWLEDGEMENTS TODO dist dists dir unix checksum checksums

=head1 NAME

Dist::Metadata::Struct - Enable Dist::Metadata for a data structure

=head1 VERSION

version 0.927

=head1 SYNOPSIS

  my $dm = Dist::Metadata->new(struct => {
    files => {
      'lib/Mod.pm' => 'package Mod; sub something { ... }',
      'README'     => 'this is a fake dist, useful for testing',
    }
  });

=head1 DESCRIPTION

This is a subclass of L<Dist::Metadata::Dist>
to enable mocking up a dist from perl data structures.

This is mostly used for testing
but might be useful if you already have an in-memory representation
of a dist that you'd like to examine.

It's probably not very useful on it's own though,
and should be used from L<Dist::Metadata/new>.

=head1 METHODS

=head2 new

  $dist = Dist::Metadata::Struct->new(files => {
    'lib/Mod.pm' => 'package Mod; sub something { ... }',
  });

Accepts a C<files> parameter that should be a hash of
C<< { name => content, } >>.
Content can be a string, a reference to a string, or an IO object.

=head2 default_file_spec

C<Unix> is the default for consistency/simplicity
but C<file_spec> can be overridden in the constructor.

=head2 file_content

Returns the string content for the specified name.

=head2 find_files

Returns the keys of the C<files> hash.

=head1 AUTHOR

Randy Stauner <rwstauner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2011 by Randy Stauner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
