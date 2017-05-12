package Dist::Zooky::DistIni::MetaNoIndex;
$Dist::Zooky::DistIni::MetaNoIndex::VERSION = '0.22';
# ABSTRACT: Dist::Zooky DistIni plugin for MetaNoIndex

use strict;
use warnings;
use Module::Load::Conditional qw[check_install];
use Moose;

with 'Dist::Zooky::Role::DistIni';

sub content {
  my $self = shift;
  return unless
    check_install( module => 'Dist::Zilla::Plugin::MetaNoIndex' );
  if ( my $noindex = $self->metadata->{no_index} ) {
    my $content = "[MetaNoIndex]\n";
    foreach my $type ( keys %{ $noindex } ) {
      $content .= join "\n", map { "$type = " . $_ } @{ $noindex->{$type} };
    }
    return $content;
  }
  return;
}

__PACKAGE__->meta->make_immutable;
no Moose;

qq[No Index, No Problem];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::DistIni::MetaNoIndex - Dist::Zooky DistIni plugin for MetaNoIndex

=head1 VERSION

version 0.22

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
