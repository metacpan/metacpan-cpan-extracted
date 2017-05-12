use 5.006;
use strict;
use warnings;

package Metabase::Test::Fact;
# ABSTRACT: Test class for Metabase testing
our $VERSION = '1.003'; # VERSION

# Metabase::Fact is not a Moose class
use parent 'Metabase::Fact::String';

sub content_metadata {
  my $self = shift;
  return {
    'size' => length $self->content,
    'WIDTH' => length $self->content,
  };
}

sub content_metadata_types {
  return {
    'size' => "//num",
    'WIDTH' => "//str",
  };
}

sub validate_content {
  my $self = shift;
  $self->SUPER::validate_content;
  die __PACKAGE__ . " content length must be greater than zero\n"
  if length $self->content < 0;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Metabase::Test::Fact - Test class for Metabase testing

=head1 VERSION

version 1.003

=head1 AUTHORS

=over 4

=item *

David Golden <dagolden@cpan.org>

=item *

Ricardo Signes <rjbs@cpan.org>

=item *

Leon Brocard <acme@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 by David Golden.

This is free software, licensed under:

  The Apache License, Version 2.0, January 2004

=cut
