package Dist::Zooky::DistIni::Resources;
$Dist::Zooky::DistIni::Resources::VERSION = '0.24';
# ABSTRACT: Dist::Zooky DistIni plugin to write MetaResources

use strict;
use warnings;
use Moose;

with 'Dist::Zooky::Role::DistIni';

sub content {
  my $self = shift;
  return unless my $resources = $self->metadata->{resources};
  my $content = "[MetaResources]\n";
  foreach my $type ( keys %{ $resources } ) {
    next if $type eq 'license';
    my $ref = ref $resources->{$type};
    if ( $ref eq 'HASH' ) {
      foreach my $item ( keys %{ $resources->{$type} } ) {
        $content .= "$type.$item = " . $resources->{$type}->{$item} . "\n";
      }
    }
    elsif ( $ref eq 'ARRAY' ) {
      $content .= "$type = $_\n" for @{ $resources->{$type} };
    }
    else {
      $content .= "$type = " . $resources->{$type} . "\n";
    }
  }
  return $content;
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::DistIni::Resources - Dist::Zooky DistIni plugin to write MetaResources

=head1 VERSION

version 0.24

=head1 METHODS

=over

=item C<content>

Returns C<content> for adding to C<dist.ini>.

=back

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
