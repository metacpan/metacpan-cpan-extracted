package Dist::Zooky::Core::FromMETA;
$Dist::Zooky::Core::FromMETA::VERSION = '0.22';
# ABSTRACT: gather meta data from META files

use strict;
use warnings;
use Moose;

with 'Dist::Zooky::Role::Core';
with 'Dist::Zooky::Role::Meta';

sub _build_metadata {
  my $self = shift;

  my $struct;

  if ( -e 'META.json' ) {

    $struct = $self->meta_from_file( 'META.json' );

  }
  elsif ( -e 'META.yml' ) {

    $struct = $self->meta_from_file( 'META.yml' );

  }
  else {

    die "There is no 'META.json' nor 'META.yml' found\n"

  }

  return { %$struct };
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[What does a meta make if a meta makes];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Core::FromMETA - gather meta data from META files

=head1 VERSION

version 0.22

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
